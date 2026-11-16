import type { SwipeDecisionKind } from '@prisma/client';

// 하루 추천과 둘러보기가 쓰는 고정 값과 순수 규칙. 설계 3장 "추천", "둘러보기".
export const DAILY_CARD_COUNT = 10;
export const PREVIEW_CARD_COUNT = 10;

export interface RankInput {
  id: string;
  // 상대가 나에게 이미 관심을 보냈다. 점수와 관계없이 앞에 놓는다(상대에게는 알리지 않는다).
  boosted: boolean;
  score: number;
  // 최근일수록 큰 값(가입·생성·공개 시각). 점수가 같을 때 최근 것이 앞이다.
  recency: number;
}

// 관심을 받은 카드 → 점수 높은 순 → 최근 순 → id 순. 앞에서 limit개. 입력은 건드리지 않는다.
export function rankCandidates<T extends RankInput>(
  items: T[],
  limit: number,
): T[] {
  return [...items]
    .sort(
      (a, b) =>
        Number(b.boosted) - Number(a.boosted) ||
        b.score - a.score ||
        b.recency - a.recency ||
        a.id.localeCompare(b.id),
    )
    .slice(0, limit);
}

export interface DecisionRow {
  targetId: string;
  decision: SwipeDecisionKind;
  updatedAt: Date;
}

// 목록을 만들 때 다시 올리지 않는 대상: 관심을 보냈거나 넘긴 것. 보류는 다음 날 목록에 다시 나올 수 있다.
export function settledTargetIds(rows: DecisionRow[]): Set<string> {
  return new Set(
    rows.filter((r) => r.decision !== 'HOLD').map((r) => r.targetId),
  );
}

// 오늘 목록에서 빼는 대상: 위의 것과, 오늘 보류한 것. 보류를 한국 날짜가 바뀌기 전에 다시 보여 주지 않는다.
export function decidedTargetIds(
  rows: DecisionRow[],
  startOfToday: Date,
): Set<string> {
  return new Set(
    rows
      .filter(
        (r) =>
          r.decision !== 'HOLD' ||
          r.updatedAt.getTime() >= startOfToday.getTime(),
      )
      .map((r) => r.targetId),
  );
}
