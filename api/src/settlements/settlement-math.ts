// 정산 숫자 계산. 모두 원 단위 정수이고 시각이나 DB를 모르는 순수 함수다.

// 수수료는 내림이다. 소수점 아래를 반올림하면 사장님이 낸 돈보다 장부에 더 쌓일 수 있다.
export function feeFor(escrow: number, feeRate: number): number {
  assertWholeWon(escrow, '에스크로 금액');
  assertWholeWon(feeRate, '수수료율');
  return Math.floor((escrow * feeRate) / 100);
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

// 평소 조회수 대비 이번 조회수의 배수. 소수 첫째 자리까지 내림해 정수(31 = 3.1배)로 둔다.
// 평소 조회수가 0 이하면 나눌 수 없어 null이다(비교 상자를 숨긴다).
export function multiplierTenthsOf(
  views: number,
  usualViews: number,
): number | null {
  assertWholeWon(views, '조회수');
  if (!Number.isInteger(usualViews) || usualViews <= 0) return null;
  return Math.floor((views * 10) / usualViews);
}

function assertWholeWon(value: number, label: string): void {
  if (!Number.isInteger(value) || value < 0) {
    throw new Error(`${label}은(는) 0 이상의 정수여야 해요: ${value}`);
  }
}
