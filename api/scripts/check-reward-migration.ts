import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { PrismaClient } from '@prisma/client';
import { config } from 'dotenv';
import { assertCheckLedgerTarget } from '../seed/lib/check-ledger-target';
import { readDevProjectRef } from '../seed/lib/dev-target';
import {
  AfterSnapshot,
  BeforeSnapshot,
  CollaborationBefore,
  compareReward,
  SettlementRow,
} from '../seed/lib/reward-migration-check';
import { SeedError } from '../seed/lib/supabase-admin';

// 보상 이전 전후의 금액을 비교한다. 읽기만 하고 쓰지 않는다(기록 파일만 만든다).
//   yarn check:reward-migration --before   이전 전: 협업·오퍼·가게의 옛 값을 파일에 남긴다(옛 스키마에서만 돈다).
//   yarn check:reward-migration --after    이전 후: 새 스키마의 값이 기록과 맞는지 확인한다.
// api/.env를 읽는다. 값은 출력하지 않는다.
config({ quiet: true });

const RECORD_PATH = resolve(
  __dirname,
  '../../.superpowers/sdd/2026-11-12-store-flow-revision/reward-before.json',
);
// 이전이 건드리지 않아야 하는 표.
const UNTOUCHED_TABLES = [
  'payments',
  'settlements',
  'ledger_entries',
  'payouts',
  'refunds',
];

type Row = Record<string, unknown>;
const num = (v: unknown): number | null =>
  typeof v === 'number' ? v : v === null || v === undefined ? null : Number(v);
const str = (v: unknown): string | null => (typeof v === 'string' ? v : null);

async function counts(prisma: PrismaClient): Promise<Record<string, number>> {
  const out: Record<string, number> = {};
  for (const table of UNTOUCHED_TABLES) {
    // 표 이름은 위 고정 목록의 것만 쓴다.
    const rows = await prisma.$queryRawUnsafe<Row[]>(
      `SELECT count(*)::int AS n FROM "${table}"`,
    );
    out[table] = Number(rows[0].n);
  }
  return out;
}

async function paidAndSettled(prisma: PrismaClient) {
  const paid = new Map<string, number>();
  for (const r of await prisma.$queryRawUnsafe<Row[]>(
    `SELECT collaboration_id::text AS id, SUM(amount_escrow)::int AS escrow FROM payments WHERE status = 'APPROVED' GROUP BY collaboration_id`,
  )) {
    paid.set(String(r.id), Number(r.escrow));
  }
  const settled = new Map<string, SettlementRow>();
  for (const r of await prisma.$queryRawUnsafe<Row[]>(
    `SELECT collaboration_id::text AS id, final_views, payout_amount, refund_amount FROM settlements`,
  )) {
    settled.set(String(r.id), {
      finalViews: num(r.final_views),
      payoutAmount: Number(r.payout_amount),
      refundAmount: Number(r.refund_amount),
    });
  }
  return { paid, settled };
}

async function readBefore(prisma: PrismaClient): Promise<BeforeSnapshot> {
  const { paid, settled } = await paidAndSettled(prisma);
  const collaborations: CollaborationBefore[] = (
    await prisma.$queryRawUnsafe<Row[]>(
      `SELECT id::text AS id, terms FROM collaborations ORDER BY id`,
    )
  ).map((r) => {
    const t = (r.terms ?? {}) as Record<string, unknown>;
    return {
      id: String(r.id),
      rewardType: str(t.rewardType),
      voucherName: str(t.voucherName),
      perViewAmount: num(t.perViewAmount),
      perViewCap: num(t.perViewCap),
      paidEscrow: paid.get(String(r.id)) ?? null,
      settlement: settled.get(String(r.id)) ?? null,
    };
  });
  const offers = (
    await prisma.$queryRawUnsafe<Row[]>(
      `SELECT id::text AS id, reward_type::text AS reward_type, voucher_name, voucher_value, per_view_amount, per_view_cap FROM offers ORDER BY id`,
    )
  ).map((r) => ({
    id: String(r.id),
    rewardType: String(r.reward_type),
    voucherName: str(r.voucher_name),
    voucherValue: num(r.voucher_value),
    perViewAmount: num(r.per_view_amount),
    perViewCap: num(r.per_view_cap),
  }));
  const stores = (
    await prisma.$queryRawUnsafe<Row[]>(
      `SELECT id::text AS id, default_reward_type::text AS default_reward_type, default_voucher_name, default_voucher_value FROM stores ORDER BY id`,
    )
  ).map((r) => ({
    id: String(r.id),
    defaultRewardType: str(r.default_reward_type),
    defaultVoucherName: str(r.default_voucher_name),
    defaultVoucherValue: num(r.default_voucher_value),
  }));
  return {
    recordedAt: new Date().toISOString(),
    collaborations,
    offers,
    stores,
    counts: await counts(prisma),
  };
}

async function readAfter(prisma: PrismaClient): Promise<AfterSnapshot> {
  const { paid, settled } = await paidAndSettled(prisma);
  // 결제 승인 때 장부 ESCROW에 올라간 금액(결제 행 합이 아니라 장부 줄의 합).
  const posted = new Map<string, number>();
  for (const r of await prisma.$queryRawUnsafe<Row[]>(
    `SELECT collaboration_id::text AS id, SUM(amount)::int AS amount FROM ledger_entries WHERE credit_account = 'ESCROW' AND reason = 'PAYMENT_ESCROW' GROUP BY collaboration_id`,
  )) {
    posted.set(String(r.id), Number(r.amount));
  }
  return {
    collaborations: (
      await prisma.$queryRawUnsafe<Row[]>(
        `SELECT id::text AS id, terms FROM collaborations ORDER BY id`,
      )
    ).map((r) => ({
      id: String(r.id),
      terms: r.terms,
      paidEscrow: paid.get(String(r.id)) ?? null,
      postedEscrow: posted.get(String(r.id)) ?? null,
      settlement: settled.get(String(r.id)) ?? null,
    })),
    offers: (
      await prisma.$queryRawUnsafe<Row[]>(
        `SELECT id::text AS id, voucher_name, voucher_value, voucher_people, fixed_cash, view_rate_per_thousand, per_view_cap, usage_rights::text AS usage_rights FROM offers ORDER BY id`,
      )
    ).map((r) => ({
      id: String(r.id),
      voucherName: str(r.voucher_name),
      voucherValue: num(r.voucher_value),
      voucherPeople: num(r.voucher_people),
      fixedCash: Number(r.fixed_cash),
      viewRatePerThousand: num(r.view_rate_per_thousand),
      perViewCap: num(r.per_view_cap),
      usageRights: String(r.usage_rights),
    })),
    stores: (
      await prisma.$queryRawUnsafe<Row[]>(
        `SELECT id::text AS id, default_voucher_name, default_voucher_value, default_voucher_people, default_fixed_cash, default_view_rate_per_thousand, default_per_view_cap, default_usage_rights::text AS default_usage_rights FROM stores ORDER BY id`,
      )
    ).map((r) => ({
      id: String(r.id),
      defaultVoucherName: str(r.default_voucher_name),
      defaultVoucherValue: num(r.default_voucher_value),
      defaultVoucherPeople: num(r.default_voucher_people),
      defaultFixedCash: Number(r.default_fixed_cash),
      defaultViewRatePerThousand: num(r.default_view_rate_per_thousand),
      defaultPerViewCap: num(r.default_per_view_cap),
      defaultUsageRights: String(r.default_usage_rights),
    })),
    counts: await counts(prisma),
  };
}

async function main(): Promise<number> {
  const mode = process.argv.includes('--before')
    ? 'before'
    : process.argv.includes('--after')
      ? 'after'
      : null;
  if (!mode) {
    console.error('사용법: yarn check:reward-migration --before | --after');
    return 1;
  }
  const { NODE_ENV, SUPABASE_URL, DATABASE_URL, CORA_TEST_DB } = process.env;
  // DB에 닿기 전에 개발·테스트 DB가 맞는지부터 확인한다.
  assertCheckLedgerTarget({
    nodeEnv: NODE_ENV,
    supabaseUrl: SUPABASE_URL,
    devProjectRef: readDevProjectRef(),
    databaseUrl: DATABASE_URL,
    testDbFlag: CORA_TEST_DB,
  });
  const prisma = new PrismaClient({ errorFormat: 'minimal' });
  try {
    await prisma.$connect();
    if (mode === 'before') {
      const snapshot = await readBefore(prisma);
      mkdirSync(dirname(RECORD_PATH), { recursive: true });
      writeFileSync(RECORD_PATH, `${JSON.stringify(snapshot, null, 2)}\n`);
      console.log(
        `이전 전 기록을 남겼어요: 협업 ${snapshot.collaborations.length}건, 오퍼 ${snapshot.offers.length}건, 가게 ${snapshot.stores.length}곳`,
      );
      return 0;
    }
    const recorded = JSON.parse(
      readFileSync(RECORD_PATH, 'utf8'),
    ) as BeforeSnapshot;
    const { problems, collaborations } = compareReward(
      recorded,
      await readAfter(prisma),
    );
    if (problems.length === 0) {
      console.log(`옛 협업 ${collaborations}건의 금액이 그대로입니다`);
      return 0;
    }
    console.error(`이전 전후가 맞지 않는 곳이 ${problems.length}개예요.`);
    for (const problem of problems) console.error(`  ${problem}`);
    return 1;
  } finally {
    await prisma.$disconnect();
  }
}

main().then(
  (code) => process.exit(code),
  (error: unknown) => {
    if (error instanceof SeedError) {
      console.error(error.message);
    } else {
      const name = error instanceof Error ? error.name : 'UnknownError';
      console.error(`보상 이전 확인이 실패했어요. (${name})`);
    }
    process.exit(1);
  },
);
