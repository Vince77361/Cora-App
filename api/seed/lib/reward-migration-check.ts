import { settleReward } from '../../src/settlements/settlement-math';
import { maxCashBurden, readTerms } from '../../src/stores/reward-terms';

// 보상 이전(마이그레이션) 전후의 협업별 금액을 비교하는 순수 함수. DB를 모른다.
// 이전 전 값은 옛 스키마에서 읽어 JSON으로 남기고(--before), 이전 후 값은 새 스키마에서 읽어(--after) 맞춰 본다.

// 옛 기본 식사권 이름. 이전이 이름 + 인원(2명)으로 나눈다.
const LEGACY_VOUCHER_NAME = '2인 식사권';
// 옛 기본 보상에 조회수가 있던 가게의 새 기본값(마이그레이션이 채운다).
const STORE_DEFAULT_RATE = 2000;
const STORE_DEFAULT_CAP = 60000;

export interface SettlementRow {
  finalViews: number | null;
  payoutAmount: number;
  refundAmount: number;
}

export interface CollaborationBefore {
  id: string;
  rewardType: string | null;
  voucherName: string | null;
  perViewAmount: number | null;
  perViewCap: number | null;
  // 승인된 결제의 보관액 합. 결제가 없으면 null.
  paidEscrow: number | null;
  settlement: SettlementRow | null;
}

export interface OfferBefore {
  id: string;
  rewardType: string;
  voucherName: string | null;
  voucherValue: number | null;
  perViewAmount: number | null;
  perViewCap: number | null;
}

export interface StoreBefore {
  id: string;
  defaultRewardType: string | null;
  defaultVoucherName: string | null;
  defaultVoucherValue: number | null;
}

// 이전이 건드리지 않아야 하는 표의 행 수.
export type RowCounts = Record<string, number>;

export interface BeforeSnapshot {
  recordedAt: string;
  collaborations: CollaborationBefore[];
  offers: OfferBefore[];
  stores: StoreBefore[];
  counts: RowCounts;
}

export interface CollaborationAfter {
  id: string;
  terms: unknown;
  paidEscrow: number | null;
  // 결제로 장부 ESCROW에 실제로 올라간 금액(결제 승인 줄의 합). 올라간 줄이 없으면 null.
  // 같은 협업에 승인된 결제 행이 둘이어도(밀려난 결제의 뒤늦은 승인) 장부에는 한 번만 올라가므로, 보관액의 기준은 결제 행 합이 아니라 이 값이다.
  postedEscrow: number | null;
  settlement: SettlementRow | null;
}

export interface OfferAfter {
  id: string;
  voucherName: string | null;
  voucherValue: number | null;
  voucherPeople: number | null;
  fixedCash: number;
  viewRatePerThousand: number | null;
  perViewCap: number | null;
  usageRights: string;
}

export interface StoreAfter {
  id: string;
  defaultVoucherName: string | null;
  defaultVoucherValue: number | null;
  defaultVoucherPeople: number | null;
  defaultFixedCash: number;
  defaultViewRatePerThousand: number | null;
  defaultPerViewCap: number | null;
  defaultUsageRights: string;
}

export interface AfterSnapshot {
  collaborations: CollaborationAfter[];
  offers: OfferAfter[];
  stores: StoreAfter[];
  counts: RowCounts;
}

// 옛 계산: 조회수 × 건당 금액을 상한까지 지급하고 남은 상한을 환급한다.
function oldSettle(views: number, perViewAmount: number, cap: number) {
  const payout = Math.min(views * perViewAmount, cap);
  return { payout, refund: cap - payout };
}

// 조회수 0, 1000, 12500, 상한을 넘는 값. 협업의 단가와 상한에 맞춰 상한을 넘기는 값을 만든다.
function sampleViews(perViewAmount: number, cap: number): number[] {
  const overCap =
    perViewAmount > 0 ? Math.ceil(cap / perViewAmount) + 1000 : 1_000_000;
  return [0, 1000, 12500, overCap];
}

// 식사권 이름 규칙: 옛 기본 이름은 "식사권" + 2명으로 나뉜다.
function expectedVoucher(name: string | null): {
  name: string | null;
  people: number | null;
} {
  if (name === LEGACY_VOUCHER_NAME) return { name: '식사권', people: 2 };
  return { name, people: null };
}

export function compareReward(
  before: BeforeSnapshot,
  after: AfterSnapshot,
): { problems: string[]; collaborations: number } {
  const problems: string[] = [];
  const fail = (message: string) => problems.push(message);

  for (const [table, count] of Object.entries(before.counts)) {
    if (after.counts[table] !== count) {
      fail(
        `${table} 행 수가 달라졌어요: 이전 ${count}, 이후 ${after.counts[table]}`,
      );
    }
  }

  const afterCollabs = new Map(after.collaborations.map((c) => [c.id, c]));
  if (afterCollabs.size !== before.collaborations.length) {
    fail(
      `협업 수가 달라졌어요: 이전 ${before.collaborations.length}, 이후 ${afterCollabs.size}`,
    );
  }
  for (const b of before.collaborations) {
    const a = afterCollabs.get(b.id);
    if (!a) {
      fail(`협업 ${b.id}가 이전 뒤에 없어요.`);
      continue;
    }
    let terms: ReturnType<typeof readTerms>;
    try {
      terms = readTerms(a.terms);
    } catch {
      fail(`협업 ${b.id}의 조건 사본을 읽을 수 없어요.`);
      continue;
    }
    // 이전이 끝난 뒤에는 옛 키가 남지 않아야 한다.
    const keys = Object.keys(a.terms ?? {});
    if (keys.includes('perViewAmount') || keys.includes('rewardType')) {
      fail(`협업 ${b.id}의 조건 사본에 옛 키가 남아 있어요.`);
    }
    const expectedRate =
      b.perViewAmount === null ? null : b.perViewAmount * 1000;
    if (terms.viewRatePerThousand !== expectedRate) {
      fail(
        `협업 ${b.id}의 단가가 맞지 않아요: 기대 ${expectedRate}, 이후 ${terms.viewRatePerThousand}`,
      );
    }
    if (terms.perViewCap !== b.perViewCap) {
      fail(`협업 ${b.id}의 상한이 달라졌어요.`);
    }
    if (terms.fixedCash !== 0) fail(`협업 ${b.id}의 고정 현금이 0이 아니에요.`);
    if (terms.usageRights !== 'NONE') {
      fail(`협업 ${b.id}의 사용권이 NONE이 아니에요.`);
    }
    const voucher = expectedVoucher(b.voucherName);
    if (terms.voucherName !== voucher.name) {
      fail(`협업 ${b.id}의 식사권 이름이 기대와 달라요.`);
    }
    if (terms.voucherPeople !== voucher.people) {
      fail(`협업 ${b.id}의 식사권 인원이 기대와 달라요.`);
    }
    if (a.paidEscrow !== b.paidEscrow) {
      fail(`협업 ${b.id}의 결제 보관액이 달라졌어요.`);
    }
    if (JSON.stringify(a.settlement) !== JSON.stringify(b.settlement)) {
      fail(`협업 ${b.id}의 정산 값이 달라졌어요.`);
    }
    // 장부에 보관된 금액은 새 조건의 최대 현금 부담과 같아야 한다.
    if (a.postedEscrow !== null && a.postedEscrow !== maxCashBurden(terms)) {
      fail(
        `협업 ${b.id}의 장부 보관액(${a.postedEscrow})이 최대 현금 부담(${maxCashBurden(terms)})과 달라요.`,
      );
    }

    if (b.perViewAmount !== null && b.perViewCap !== null) {
      const samples = sampleViews(b.perViewAmount, b.perViewCap);
      if (b.settlement?.finalViews != null)
        samples.push(b.settlement.finalViews);
      for (const views of samples) {
        const old = oldSettle(views, b.perViewAmount, b.perViewCap);
        const next = settleReward({
          views,
          ratePerThousand: terms.viewRatePerThousand ?? 0,
          cap: terms.perViewCap ?? 0,
          fixedCash: terms.fixedCash,
        });
        if (next.payout !== old.payout || next.refund !== old.refund) {
          fail(
            `협업 ${b.id}: 조회수 ${views}에서 옛 계산(${old.payout}/${old.refund})과 새 계산(${next.payout}/${next.refund})이 달라요.`,
          );
        }
      }
    }
  }

  const afterOffers = new Map(after.offers.map((o) => [o.id, o]));
  for (const b of before.offers) {
    const a = afterOffers.get(b.id);
    if (!a) {
      fail(`오퍼 ${b.id}가 이전 뒤에 없어요.`);
      continue;
    }
    const voucher = expectedVoucher(b.voucherName);
    const expectedRate =
      b.perViewAmount === null ? null : b.perViewAmount * 1000;
    if (
      a.viewRatePerThousand !== expectedRate ||
      a.perViewCap !== b.perViewCap ||
      a.voucherName !== voucher.name ||
      a.voucherValue !== b.voucherValue ||
      a.voucherPeople !== voucher.people ||
      a.fixedCash !== 0 ||
      a.usageRights !== 'NONE'
    ) {
      fail(`오퍼 ${b.id}의 값이 기대와 달라요.`);
    }
  }
  if (afterOffers.size !== before.offers.length) {
    fail(
      `오퍼 수가 달라졌어요: 이전 ${before.offers.length}, 이후 ${afterOffers.size}`,
    );
  }

  const afterStores = new Map(after.stores.map((s) => [s.id, s]));
  for (const b of before.stores) {
    const a = afterStores.get(b.id);
    if (!a) {
      fail(`가게 ${b.id}가 이전 뒤에 없어요.`);
      continue;
    }
    const hasView =
      b.defaultRewardType === 'PER_VIEW' || b.defaultRewardType === 'BOTH';
    const voucher =
      b.defaultRewardType === 'PER_VIEW'
        ? { name: null, people: null }
        : expectedVoucher(b.defaultVoucherName);
    const value =
      b.defaultRewardType === 'PER_VIEW' ? null : b.defaultVoucherValue;
    if (
      a.defaultViewRatePerThousand !== (hasView ? STORE_DEFAULT_RATE : null) ||
      a.defaultPerViewCap !== (hasView ? STORE_DEFAULT_CAP : null) ||
      a.defaultVoucherName !== voucher.name ||
      a.defaultVoucherValue !== value ||
      a.defaultVoucherPeople !== voucher.people ||
      a.defaultFixedCash !== 0 ||
      a.defaultUsageRights !== 'STORE_REPOST_3M'
    ) {
      fail(`가게 ${b.id}의 기본 조건이 기대와 달라요.`);
    }
  }
  if (afterStores.size !== before.stores.length) {
    fail(
      `가게 수가 달라졌어요: 이전 ${before.stores.length}, 이후 ${afterStores.size}`,
    );
  }

  return { problems, collaborations: before.collaborations.length };
}
