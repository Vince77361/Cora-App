import { LedgerAccount } from '@prisma/client';

// 복식 장부의 한 줄 묶음 요소. debit에서 credit으로 amount원이 옮겨 간다(예: PG_IN→ESCROW).
export type Posting = {
  debit: LedgerAccount;
  credit: LedgerAccount;
  amount: number;
  reason: string;
};

export type EntryAmounts = {
  debitAccount: LedgerAccount;
  creditAccount: LedgerAccount;
  amount: number;
};

const ACCOUNTS: LedgerAccount[] = [
  'PG_IN',
  'ESCROW',
  'CREATOR_PAYABLE',
  'STORE_REFUND',
  'FEE_REVENUE',
];

// 금액이 0인 줄은 장부에 남길 이유가 없어 만들지 않는다.
function nonZero(postings: Posting[]): Posting[] {
  return postings.filter((p) => p.amount !== 0);
}

// 결제 승인: 낸 돈이 PG에서 에스크로(크리에이터 몫 상한)와 수수료 수익으로 갈라져 들어온다.
export function postingsForPaymentApproved(p: {
  escrow: number;
  fee: number;
}): Posting[] {
  return nonZero([
    {
      debit: 'PG_IN',
      credit: 'ESCROW',
      amount: p.escrow,
      reason: 'PAYMENT_ESCROW',
    },
    {
      debit: 'PG_IN',
      credit: 'FEE_REVENUE',
      amount: p.fee,
      reason: 'PAYMENT_FEE',
    },
  ]);
}

// 정산: 에스크로에서 크리에이터 지급 예정분과 사장님 환급분으로 나눠 나간다.
export function postingsForSettlement(p: {
  payout: number;
  refund: number;
}): Posting[] {
  return nonZero([
    {
      debit: 'ESCROW',
      credit: 'CREATOR_PAYABLE',
      amount: p.payout,
      reason: 'SETTLEMENT_PAYOUT',
    },
    {
      debit: 'ESCROW',
      credit: 'STORE_REFUND',
      amount: p.refund,
      reason: 'SETTLEMENT_REFUND',
    },
  ]);
}

// 전액 환급: 수수료까지 돌려준다(낸 돈 전부).
export function postingsForFullRefund(p: {
  escrow: number;
  fee: number;
}): Posting[] {
  return nonZero([
    {
      debit: 'ESCROW',
      credit: 'STORE_REFUND',
      amount: p.escrow,
      reason: 'REFUND_ESCROW',
    },
    {
      debit: 'FEE_REVENUE',
      credit: 'STORE_REFUND',
      amount: p.fee,
      reason: 'REFUND_FEE',
    },
  ]);
}

// 운영자 강제 지급: 에스크로에서 크리에이터 지급 예정분으로.
export function postingsForForcedPayout(p: { amount: number }): Posting[] {
  return nonZero([
    {
      debit: 'ESCROW',
      credit: 'CREATOR_PAYABLE',
      amount: p.amount,
      reason: 'FORCED_PAYOUT',
    },
  ]);
}

// 계정별 (들어온 합 − 나간 합). credit 쪽이 들어온 것, debit 쪽이 나간 것이다.
export function balances(
  entries: EntryAmounts[],
): Record<LedgerAccount, number> {
  const result = Object.fromEntries(ACCOUNTS.map((a) => [a, 0])) as Record<
    LedgerAccount,
    number
  >;
  for (const e of entries) {
    result[e.creditAccount] += e.amount;
    result[e.debitAccount] -= e.amount;
  }
  return result;
}

// 불변식: PG_IN에서 나간 합 = ESCROW 잔액 + CREATOR_PAYABLE로 들어간 합 + STORE_REFUND로 들어간 합 + FEE_REVENUE 잔액.
// 에스크로와 수수료 수익은 잔액이 음수일 수 없다(없는 돈을 내보낸 것이다).
// 이 식이 깨지는 변경은 던져서 호출한 트랜잭션을 되돌린다.
export function assertBalanced(entries: EntryAmounts[]): void {
  const b = balances(entries);
  if (b.ESCROW < 0)
    throw new Error(`장부 오류: ESCROW 잔액이 음수예요(${b.ESCROW}).`);
  if (b.FEE_REVENUE < 0) {
    throw new Error(
      `장부 오류: FEE_REVENUE 잔액이 음수예요(${b.FEE_REVENUE}).`,
    );
  }
  let pgOut = 0;
  let payableIn = 0;
  let refundIn = 0;
  for (const e of entries) {
    if (e.debitAccount === 'PG_IN') pgOut += e.amount;
    if (e.creditAccount === 'CREATOR_PAYABLE') payableIn += e.amount;
    if (e.creditAccount === 'STORE_REFUND') refundIn += e.amount;
  }
  const accounted = b.ESCROW + payableIn + refundIn + b.FEE_REVENUE;
  if (pgOut !== accounted) {
    throw new Error(
      `장부 오류: PG_IN에서 나간 합(${pgOut})이 에스크로·지급·환급·수수료의 합(${accounted})과 달라요.`,
    );
  }
}
