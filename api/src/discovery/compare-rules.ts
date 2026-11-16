import type { BrandUsageRights, ContentFormat, FeeBand } from '@prisma/client';

// 04 표의 줄. 화면의 순서 그대로다.
export const COMPARE_FIELDS = [
  'DELIVERABLE',
  'BENEFIT',
  'FEE',
  'PERF_CAP',
  'USAGE',
  'START',
  'FACE',
] as const;
export type CompareField = (typeof COMPARE_FIELDS)[number];

// 후보 한 명의 줄 값. 팔로워 수는 비교하지 않으므로 여기에 없다.
export interface CompareValues {
  format: ContentFormat;
  pieces: number;
  productProvided: boolean;
  fee: number | null;
  feeBand: FeeBand;
  // 성과 추가 단가(1,000회당 원). 화면 줄은 아니고(상한만 견준다) 04가 이미 만든 제안을 다시 열 때 쓴다.
  perfRate: number | null;
  perfCap: number | null;
  usageRights: BrandUsageRights;
  startDate: string | null;
  faceOk: boolean;
}

// 화면에 보일 글자가 서로 다른 줄을 돌려준다. 숫자가 아니라 표시되는 값으로 견준다:
// 현금 고정비는 `fee ?? feeBand`라서 "30만 원"(제안한 금액)과 "30만 원대"(희망 구간)는 다른 줄이다.
// 촬영 가능일은 `startDate ?? 'TBD'`(일정 협의)로 견준다.
export function compareDiff(
  a: CompareValues,
  b: CompareValues,
): CompareField[] {
  const shown: Record<CompareField, (v: CompareValues) => string> = {
    DELIVERABLE: (v) => `${v.format}:${v.pieces}`,
    BENEFIT: (v) => String(v.productProvided),
    FEE: (v) => (v.fee !== null ? `fee:${v.fee}` : `band:${v.feeBand}`),
    PERF_CAP: (v) => (v.perfCap !== null ? `cap:${v.perfCap}` : 'none'),
    USAGE: (v) => v.usageRights,
    START: (v) => v.startDate ?? 'TBD',
    FACE: (v) => String(v.faceOk),
  };
  return COMPARE_FIELDS.filter((field) => shown[field](a) !== shown[field](b));
}
