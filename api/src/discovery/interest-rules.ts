import type { SwipeDecisionKind } from '@prisma/client';

export type InterestState = 'MUTUAL' | 'WAITING' | 'HELD';
export type InterestTab = 'saved' | 'mutual' | 'sent' | 'held';

// 03의 짧은 이름: 활동 이름이 "{X}의 …" 꼴이면 X("서윤의 작은 취향" → "서윤"), 아니면 이름 전체다.
// "의"가 이름 안에 들어 있어도(예: "의자 공방") 뒤에 다른 글자가 이어지는 "의 " 꼴일 때만 자른다.
export function shortName(name: string): string {
  const match = /^(.+?)의\s+\S/.exec(name.trim());
  const head = match?.[1]?.trim();
  return head ? head : name;
}

// 내 결정 한 줄이 관심 목록에서 어떤 상태인가. 서로 관심(match)이 있으면 결정과 상관없이 MUTUAL이다.
// 넘김(PASS)은 목록에 오르지 않으므로 상태가 없다(null).
// 서로 관심이 닿았다가 협업이 그만둠·차단으로 끝났으면(dropped) 카드를 내지 않는다(null, 판단 C13):
// 무산된 상대는 보관함의 몫이고, '응답 대기'로 되돌리면 진행 중인 것처럼 읽혀 더 틀리다.
export function interestState(
  decision: SwipeDecisionKind,
  matched: boolean,
  dropped = false,
): InterestState | null {
  if (decision === 'PASS') return null;
  if (matched) return dropped ? null : 'MUTUAL';
  return decision === 'LIKE' ? 'WAITING' : 'HELD';
}

// 저장 탭은 전체(관심 + 보류)이고, 나머지 탭은 그 상태만이다.
export function inTab(state: InterestState, tab: InterestTab): boolean {
  switch (tab) {
    case 'saved':
      return true;
    case 'mutual':
      return state === 'MUTUAL';
    case 'sent':
      return state === 'WAITING';
    case 'held':
      return state === 'HELD';
  }
}
