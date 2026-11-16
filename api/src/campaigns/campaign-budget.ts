// 캠페인 예산을 "알려 주기만 하고 막지 않는다"(설계 3장 "캠페인 예산"). 확보액의 합이 예산을 넘어도 관심, 수락, 제안은 된다.
// 그래서 남은 예산은 음수가 되지 않고 0에서 멈추며, 넘은 금액은 따로 돌려줘 화면이 "예산을 {금액}원 넘었어요."를 보여 줄 수 있게 한다.
// secured는 그 캠페인에서 서로 관심이 닿은 협업들의 확보액(원 단위 정수)이다. 어떤 협업을 셀지는 부르는 쪽(Task 6)이 정한다.
export function budgetLeft(
  budget: number,
  secured: number[],
): { left: number; over: number } {
  const total = secured.reduce((sum, amount) => sum + amount, 0);
  if (total <= budget) return { left: budget - total, over: 0 };
  return { left: 0, over: total - budget };
}
