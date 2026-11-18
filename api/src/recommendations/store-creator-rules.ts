import { DAILY_CARD_COUNT } from './candidate-rules';

// 사장님 전체 둘러보기에 오를 수 있는 크리에이터 한 명. 거르는 일은 서비스가 끝냈다.
export interface StoreCreatorCandidate {
  id: string;
  // 그 가게에 살아 있는 지원(APPLIED, OFFERED)을 가졌다.
  applied: boolean;
  // 지역 묶음: 0 같은 구·군, 1 같은 시·도, 2 그 밖.
  tier: number;
  // 가입 시각(ms). 클수록 최근이다.
  joinedAt: number;
}

// 설계 5.3 순서: 그 가게에 지원한 사람 → 같은 구·군 → 같은 시·도 → 그 밖. 같은 묶음 안에서는 최근 가입순,
// 끝까지 같으면 id 순이라 같은 입력은 늘 같은 목록이다. 입력은 건드리지 않는다.
export function rankStoreCreators<T extends StoreCreatorCandidate>(
  items: T[],
  limit: number = DAILY_CARD_COUNT,
): T[] {
  return [...items]
    .sort(
      (a, b) =>
        Number(b.applied) - Number(a.applied) ||
        a.tier - b.tier ||
        b.joinedAt - a.joinedAt ||
        a.id.localeCompare(b.id),
    )
    .slice(0, limit);
}
