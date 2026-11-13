import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { fromLegacyTerms, readTerms } from '../../src/stores/reward-terms';
import { createOffer } from '../helpers/create-offer';
import { prisma } from './setup-db';

const OWNER = '66666666-6666-4666-8666-666666666661';
const CREATOR = '66666666-6666-4666-8666-666666666662';

// 마이그레이션 파일의 BEGIN/END 사이(협업의 조건 사본 jsonb 다시 쓰기)만 cora_test에서 실행한다.
// 열을 더하고 지우는 앞부분은 migrate deploy가 이미 적용했다.
function backfillSql(): string {
  const dir = join(__dirname, '../../prisma/migrations');
  const folder = readdirSync(dir).find((d) =>
    d.endsWith('_reward_three_elements'),
  );
  if (!folder) throw new Error('보상 이전 마이그레이션이 없어요.');
  const sql = readFileSync(join(dir, folder, 'migration.sql'), 'utf8');
  const match =
    /-- BEGIN legacy-reward-backfill\n([\s\S]*?)-- END legacy-reward-backfill/.exec(
      sql,
    );
  if (!match) throw new Error('이전 SQL의 BEGIN/END 묶음을 찾지 못했어요.');
  return match[1];
}

const legacyBoth = {
  format: 'REELS',
  rewardType: 'BOTH',
  voucherName: '2인 식사권',
  voucherValue: 40000,
  perViewAmount: 10,
  perViewCap: 100000,
};
const legacyVoucherOnly = {
  format: 'SHORTS',
  rewardType: 'VOUCHER',
  voucherName: '커피 2잔',
  voucherValue: 9000,
  perViewAmount: null,
  perViewCap: null,
};

let storeId: string;

beforeEach(async () => {
  await prisma.user.createMany({
    data: [
      { id: OWNER, role: 'STORE' },
      { id: CREATOR, role: 'CREATOR' },
    ],
  });
  storeId = (await prisma.store.create({ data: { ownerId: OWNER } })).id;
});

async function collaborationWith(
  terms: object,
  over: { settled?: boolean } = {},
) {
  const row = await prisma.collaboration.create({
    data: {
      kind: 'STORE_OFFER',
      stage: over.settled ? 'SETTLED' : 'AWAITING_PAYMENT',
      commissionerId: OWNER,
      creatorId: CREATOR,
      storeId,
      terms,
      settlementMethod: terms === legacyVoucherOnly ? 'NONE' : 'PER_VIEW',
    },
  });
  return row.id;
}

const termsOf = async (id: string) =>
  (await prisma.collaboration.findUniqueOrThrow({ where: { id } })).terms;

describe('legacy reward backfill', () => {
  it('rewrites a legacy collaboration copy to 10000 won per thousand and zero fixed cash', async () => {
    const id = await collaborationWith(legacyBoth);
    const before = readTerms(legacyBoth);

    await prisma.$executeRawUnsafe(backfillSql());

    const terms = (await termsOf(id)) as Record<string, unknown>;
    expect(terms).toEqual({
      format: 'REELS',
      pieces: 1,
      voucherName: '식사권',
      voucherValue: 40000,
      voucherPeople: 2,
      fixedCash: 0,
      viewRatePerThousand: 10000,
      perViewCap: 100000,
      usageRights: 'NONE',
    });
    expect(Object.keys(terms)).not.toContain('perViewAmount');
    expect(Object.keys(terms)).not.toContain('rewardType');
    // 이전 앞뒤로 같은 조건으로 읽혀야 한다(옛 모양을 직접 읽은 값과 같다).
    expect(readTerms(terms)).toEqual(before);
  });

  it('leaves a voucher only collaboration copy without a rate or cap', async () => {
    const id = await collaborationWith(legacyVoucherOnly);

    await prisma.$executeRawUnsafe(backfillSql());

    expect(await termsOf(id)).toEqual({
      format: 'SHORTS',
      pieces: 1,
      voucherName: '커피 2잔',
      voucherValue: 9000,
      voucherPeople: null,
      fixedCash: 0,
      viewRatePerThousand: null,
      perViewCap: null,
      usageRights: 'NONE',
    });
    expect(readTerms(await termsOf(id))).toEqual(readTerms(legacyVoucherOnly));
  });

  it('rewrites a copy that only has the legacy reward type key', async () => {
    // 손으로 만든 사본에 perViewAmount 키가 없어도 옛 모양이면 새 모양으로 옮긴다.
    const id = await collaborationWith({
      format: 'REELS',
      rewardType: 'VOUCHER',
      voucherName: '2인 식사권',
      voucherValue: 40000,
    });

    await prisma.$executeRawUnsafe(backfillSql());

    expect(await termsOf(id)).toMatchObject({
      voucherName: '식사권',
      voucherPeople: 2,
      viewRatePerThousand: null,
      fixedCash: 0,
    });
  });

  it('does not touch payments, settlements or ledger rows', async () => {
    const id = await collaborationWith(legacyBoth, { settled: true });
    await prisma.payment.create({
      data: {
        collaborationId: id,
        amountEscrow: 100000,
        amountFee: 10000,
        feeRate: 10,
        method: 'CARD',
        status: 'APPROVED',
        requestedAt: new Date('2026-11-02T00:00:00Z'),
      },
    });
    await prisma.settlement.create({
      data: {
        collaborationId: id,
        finalViews: 4320,
        payoutAmount: 43200,
        refundAmount: 56800,
        settledAt: new Date('2026-11-10T00:00:00Z'),
      },
    });
    await prisma.ledgerEntry.create({
      data: {
        collaborationId: id,
        batchId: '66666666-6666-4666-8666-666666666663',
        debitAccount: 'PG_IN',
        creditAccount: 'ESCROW',
        amount: 100000,
        reason: 'PAYMENT',
        idempotencyKey: 'payment:test',
      },
    });
    const snapshot = async () =>
      JSON.stringify([
        await prisma.payment.findMany(),
        await prisma.settlement.findMany(),
        await prisma.ledgerEntry.findMany(),
        await prisma.payout.findMany(),
        await prisma.refund.findMany(),
      ]);
    const before = await snapshot();

    await prisma.$executeRawUnsafe(backfillSql());

    expect(await snapshot()).toBe(before);
  });

  it('is safe to run twice', async () => {
    const id = await collaborationWith(legacyBoth);

    await prisma.$executeRawUnsafe(backfillSql());
    const once = await termsOf(id);
    await prisma.$executeRawUnsafe(backfillSql());

    // 두 번 돌려도 단가가 ×1000 한 번이다.
    expect(await termsOf(id)).toEqual(once);
    expect((once as Record<string, unknown>).viewRatePerThousand).toBe(
      fromLegacyTerms({ ...legacyBoth, rewardType: 'BOTH' })
        .viewRatePerThousand,
    );
  });

  it('leaves a copy that already has the new shape alone', async () => {
    const fresh = {
      format: 'REELS',
      pieces: 1,
      voucherName: '식사권',
      voucherValue: 40000,
      voucherPeople: 2,
      fixedCash: 0,
      viewRatePerThousand: 2000,
      perViewCap: 60000,
      usageRights: 'STORE_REPOST_3M',
    };
    const id = await collaborationWith(fresh);

    await prisma.$executeRawUnsafe(backfillSql());

    expect(await termsOf(id)).toEqual(fresh);
  });
});

describe('reward columns', () => {
  // 오퍼의 조건은 판본으로 옮겨졌다(5번 항목 Task 5). 보상 세 요소는 판본에 있다.
  it('stores three reward elements on an offer version and leaves the optional ones empty', async () => {
    const offer = await createOffer(prisma, {
      storeId,
      creatorId: CREATOR,
      format: 'REELS',
      status: 'SENT',
      expiresAt: new Date('2026-12-01T00:00:00Z'),
    });
    const version = await prisma.offerVersion.create({
      data: {
        offerId: offer.id,
        number: 2,
        authorParty: 'CREATOR',
        format: 'REELS',
        fixedCash: 0,
        usageRights: 'NONE',
      },
    });
    expect(version).toMatchObject({
      pieces: 1,
      voucherName: null,
      voucherPeople: null,
      fixedCash: 0,
      viewRatePerThousand: null,
      perViewCap: null,
      usageRights: 'NONE',
      idea: null,
      principles: [],
      seriesName: null,
    });
  });

  it('defaults a store to no fixed cash and the 3 month repost right', async () => {
    const store = await prisma.store.findUniqueOrThrow({
      where: { id: storeId },
    });
    expect(store).toMatchObject({
      defaultFixedCash: 0,
      defaultUsageRights: 'STORE_REPOST_3M',
      defaultViewRatePerThousand: null,
      defaultPerViewCap: null,
      defaultVoucherPeople: null,
    });
  });
});
