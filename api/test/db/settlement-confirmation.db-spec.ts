import { randomUUID } from 'node:crypto';
import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { prisma } from './setup-db';

const OWNER = '77777777-7777-4777-8777-777777777771';
const CREATOR = '77777777-7777-4777-8777-777777777772';
const SETTLED_AT = new Date('2026-12-08T03:00:00.000Z');

beforeEach(async () => {
  await prisma.user.createMany({
    data: [
      { id: OWNER, role: 'STORE' },
      { id: CREATOR, role: 'CREATOR' },
    ],
  });
});

function collaboration(
  terms: object,
  settlementMethod: 'PER_VIEW' | 'FIXED' | 'FIXED_AND_PER_VIEW',
) {
  return prisma.collaboration.create({
    data: {
      kind: 'STORE_OFFER',
      stage: 'SETTLED',
      commissionerId: OWNER,
      creatorId: CREATOR,
      terms: { format: 'REELS', ...terms },
      settlementMethod,
    },
  });
}

// 마이그레이션 파일의 BEGIN/END 사이(옛 정산 행 이전)만 cora_test에서 실행한다. 열을 더하는 앞부분은 migrate deploy가 이미 적용했다.
async function runBackfill(): Promise<void> {
  const dir = join(__dirname, '../../prisma/migrations');
  const folder = readdirSync(dir).find((d) =>
    d.endsWith('_settlement_confirmation'),
  );
  if (!folder) throw new Error('정산 확인 마이그레이션이 없어요.');
  const sql = readFileSync(join(dir, folder, 'migration.sql'), 'utf8');
  const match =
    /-- BEGIN settlement-confirmation-backfill\n([\s\S]*?)-- END settlement-confirmation-backfill/.exec(
      sql,
    );
  if (!match) throw new Error('이전 구간 표시가 없어요.');
  const statements = match[1]
    .replace(/^--.*$/gm, '')
    .split(';')
    .map((part) => part.trim())
    .filter(Boolean);
  for (const statement of statements) await prisma.$executeRawUnsafe(statement);
}

describe('settlement confirmation columns', () => {
  it('defaults a new row to confirmed with the connected account as the source', async () => {
    const c = await collaboration({}, 'PER_VIEW');
    const row = await prisma.settlement.create({
      data: {
        collaborationId: c.id,
        payoutAmount: 100,
        refundAmount: 0,
        settledAt: SETTLED_AT,
      },
    });
    expect(row).toMatchObject({
      status: 'CONFIRMED',
      evidenceSource: 'CONNECTED_ACCOUNT',
      fixedCashAmount: 0,
      viewPayAmount: 0,
      confirmDueAt: null,
      confirmedAt: null,
      confirmedBy: null,
    });
    expect(row.calculatedAt).toBeInstanceOf(Date);
  });

  it('lets an unconfirmed row have no settled time', async () => {
    const c = await collaboration({}, 'PER_VIEW');
    const row = await prisma.settlement.create({
      data: {
        collaborationId: c.id,
        payoutAmount: 25000,
        refundAmount: 35000,
        status: 'UNCONFIRMED',
        settledAt: null,
        confirmDueAt: new Date('2026-12-10T03:00:00.000Z'),
      },
    });
    expect(row).toMatchObject({ status: 'UNCONFIRMED', settledAt: null });
  });

  it('knows the two new notification kinds', async () => {
    await prisma.notification.create({
      data: {
        userId: OWNER,
        role: 'STORE',
        kind: 'VIEW_REPORT_REQUESTED',
        tab: 'SETTLEMENT',
        params: {},
        targetKind: 'VIEW_REPORT',
        targetId: randomUUID(),
      },
    });
    expect(await prisma.notification.count()).toBe(1);
  });
});

describe('moving old settlement rows', () => {
  const legacyRow = (
    collaborationId: string,
    over: {
      payoutAmount: number;
      refundAmount: number;
      finalViews: number | null;
    },
  ) =>
    prisma.settlement.create({
      data: {
        collaborationId,
        settledAt: SETTLED_AT,
        // 옛 행은 새 열의 기본값(CONFIRMED, 계산 시각 = 만든 시각, 수당 0)을 갖고 있다.
        ...over,
      },
    });

  it('confirms every old row as of its settled time and splits the amounts', async () => {
    const perView = await collaboration(
      { fixedCash: 0, viewRatePerThousand: 2000, perViewCap: 60000 },
      'PER_VIEW',
    );
    const both = await collaboration(
      { fixedCash: 30000, viewRatePerThousand: 2000, perViewCap: 60000 },
      'FIXED_AND_PER_VIEW',
    );
    const fixedOnly = await collaboration({ fixedCash: 30000 }, 'FIXED');
    await legacyRow(perView.id, {
      finalViews: 12500,
      payoutAmount: 25000,
      refundAmount: 35000,
    });
    await legacyRow(both.id, {
      finalViews: 12500,
      payoutAmount: 55000,
      refundAmount: 35000,
    });
    await legacyRow(fixedOnly.id, {
      finalViews: null,
      payoutAmount: 30000,
      refundAmount: 0,
    });

    await runBackfill();

    const rows = new Map(
      (await prisma.settlement.findMany()).map((r) => [r.collaborationId, r]),
    );
    expect(rows.get(perView.id)).toMatchObject({
      status: 'CONFIRMED',
      confirmedBy: 'AUTO',
      calculatedAt: SETTLED_AT,
      confirmedAt: SETTLED_AT,
      fixedCashAmount: 0,
      viewPayAmount: 25000,
    });
    expect(rows.get(both.id)).toMatchObject({
      confirmedBy: 'AUTO',
      fixedCashAmount: 30000,
      viewPayAmount: 25000,
    });
    expect(rows.get(fixedOnly.id)).toMatchObject({
      confirmedBy: 'NOT_NEEDED',
      fixedCashAmount: 30000,
      viewPayAmount: 0,
    });
  });

  it('marks a forced payout as decided by the operator', async () => {
    const forced = await collaboration(
      { fixedCash: 0, viewRatePerThousand: 2000, perViewCap: 60000 },
      'PER_VIEW',
    );
    await legacyRow(forced.id, {
      finalViews: null,
      payoutAmount: 40000,
      refundAmount: 20000,
    });
    await prisma.payout.create({
      data: {
        collaborationId: forced.id,
        amount: 40000,
        idempotencyKey: `force-payout:${forced.id}`,
        scheduledFor: new Date('2026-12-16T01:00:00.000Z'),
      },
    });
    await prisma.ledgerEntry.create({
      data: {
        collaborationId: forced.id,
        batchId: randomUUID(),
        debitAccount: 'ESCROW',
        creditAccount: 'CREATOR_PAYABLE',
        amount: 40000,
        reason: 'FORCED_PAYOUT',
        idempotencyKey: `force-payout:${forced.id}`,
      },
    });

    await runBackfill();

    expect(
      await prisma.settlement.findUniqueOrThrow({
        where: { collaborationId: forced.id },
      }),
    ).toMatchObject({
      status: 'CONFIRMED',
      confirmedBy: 'OPERATOR',
      fixedCashAmount: 0,
      viewPayAmount: 40000,
    });
  });

  it('is safe to run twice', async () => {
    const c = await collaboration(
      { fixedCash: 30000, viewRatePerThousand: 2000, perViewCap: 60000 },
      'FIXED_AND_PER_VIEW',
    );
    await legacyRow(c.id, {
      finalViews: 12500,
      payoutAmount: 55000,
      refundAmount: 35000,
    });
    await runBackfill();
    const once = await prisma.settlement.findUniqueOrThrow({
      where: { collaborationId: c.id },
    });
    await runBackfill();
    const twice = await prisma.settlement.findUniqueOrThrow({
      where: { collaborationId: c.id },
    });
    expect(twice).toMatchObject({
      fixedCashAmount: once.fixedCashAmount,
      viewPayAmount: once.viewPayAmount,
      confirmedBy: once.confirmedBy,
    });
  });
});
