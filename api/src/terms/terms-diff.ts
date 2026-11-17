import type { TermsValues } from './draft-terms';

// 판본끼리 비교하는 항목(공통 모델 7장의 열 항목 가운데 광고 표시를 뺀 아홉). 화면의 "바뀐 줄만 강조"가 쓴다.
// DELIVERABLE = 형식과 편 수, PERFORMANCE = 성과 추가의 켜짐·단가·상한.
export const TERMS_FIELDS = [
  'TITLE',
  'FEE',
  'PERFORMANCE',
  'START_DATE',
  'DELIVERABLE',
  'PRODUCT',
  'REVISION',
  'USAGE',
  'PAYOUT',
] as const;

export type TermsField = (typeof TERMS_FIELDS)[number];

export type TermsDiffValues = Pick<
  TermsValues,
  | 'title'
  | 'fee'
  | 'startDate'
  | 'format'
  | 'pieces'
  | 'productProvided'
  | 'revisionScope'
  | 'usageRights'
  | 'payoutDays'
  | 'perfRatePerThousand'
  | 'perfCap'
>;

// 직전 판본(prev)에서 바뀐 항목. 항상 TERMS_FIELDS의 순서다. 버전 1(prev 없음)은 빈 배열이다.
// 오퍼 판본의 changedFields와는 항목이 달라 따로 둔다(브랜드 계약의 항목만 다룬다).
export function diffTerms(
  prev: TermsDiffValues | null,
  next: TermsDiffValues,
): TermsField[] {
  if (!prev) return [];
  const changed: Record<TermsField, boolean> = {
    TITLE: prev.title !== next.title,
    FEE: prev.fee !== next.fee,
    PERFORMANCE:
      (prev.perfRatePerThousand ?? null) !==
        (next.perfRatePerThousand ?? null) ||
      (prev.perfCap ?? null) !== (next.perfCap ?? null),
    START_DATE: prev.startDate.getTime() !== next.startDate.getTime(),
    DELIVERABLE: prev.format !== next.format || prev.pieces !== next.pieces,
    PRODUCT: prev.productProvided !== next.productProvided,
    REVISION: prev.revisionScope !== next.revisionScope,
    USAGE: prev.usageRights !== next.usageRights,
    PAYOUT: prev.payoutDays !== next.payoutDays,
  };
  return TERMS_FIELDS.filter((field) => changed[field]);
}
