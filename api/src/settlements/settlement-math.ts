// 정산 숫자 계산. 모두 원 단위 정수이고 시각이나 DB를 모르는 순수 함수다.

// 수수료는 내림이다. 소수점 아래를 반올림하면 사장님이 낸 돈보다 장부에 더 쌓일 수 있다.
export function feeFor(escrow: number, feeRate: number): number {
  assertWholeWon(escrow, '에스크로 금액');
  assertWholeWon(feeRate, '수수료율');
  return Math.floor((escrow * feeRate) / 100);
}

// 조회수 × 건당 금액을 상한까지 지급하고, 남은 상한은 사장님에게 환급한다.
// 조회수가 음수거나 정수가 아니면 계산하지 않고 던진다: 잘못 읽은 값으로 돈을 움직이지 않으려는 것이다.
export function settle(p: {
  views: number;
  perViewAmount: number;
  cap: number;
}): { payout: number; refund: number } {
  assertWholeWon(p.views, '조회수');
  assertWholeWon(p.perViewAmount, '건당 금액');
  assertWholeWon(p.cap, '상한');
  const payout = Math.min(p.views * p.perViewAmount, p.cap);
  return { payout, refund: p.cap - payout };
}

// 새 보상 계산: 고정 현금은 그대로 지급하고, 조회수 수당(1,000회당 단가)은 상한까지만 지급한다.
// 환불은 상한에서 수당을 뺀 값이다. 고정 현금은 환불에 섞이지 않는다.
// 지급액 + 환불액은 항상 고정 현금 + 상한이라 에스크로 잔액이 0이 된다.
export function settleReward(p: {
  views: number;
  ratePerThousand: number;
  cap: number;
  fixedCash: number;
}): { viewPay: number; payout: number; refund: number; capApplied: boolean } {
  assertWholeWon(p.views, '조회수');
  assertWholeWon(p.ratePerThousand, '1,000회당 단가');
  assertWholeWon(p.cap, '상한');
  assertWholeWon(p.fixedCash, '고정 현금');
  const raw = Math.floor((p.views * p.ratePerThousand) / 1000);
  const viewPay = Math.min(raw, p.cap);
  return {
    viewPay,
    payout: p.fixedCash + viewPay,
    refund: p.cap - viewPay,
    capApplied: raw > p.cap,
  };
}

function assertWholeWon(value: number, label: string): void {
  if (!Number.isInteger(value) || value < 0) {
    throw new Error(`${label}은(는) 0 이상의 정수여야 해요: ${value}`);
  }
}
