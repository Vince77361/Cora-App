import { maxCashBurden, readTerms } from '../stores/reward-terms';

// 같은 트랜잭션에서 읽은 에스크로 잔액이 조건 사본의 최대 현금 부담과 다르면 화면에 보인 금액과 보관액이 어긋난 것이라
// 돈을 움직이지 않고 던져 되돌린다. 정산(일반·조회 자료 확인·운영 명령)이 모두 이 검사를 지난다.
export function assertEscrowMatches(
  terms: ReturnType<typeof readTerms>,
  escrow: number,
): void {
  const burden = maxCashBurden(terms);
  if (escrow !== burden) {
    throw new Error(
      `에스크로 잔액(${escrow})이 조건의 최대 현금 부담(${burden})과 달라요.`,
    );
  }
}
