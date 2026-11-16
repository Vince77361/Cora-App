import type {
  FeeBand,
  IndustryCategory,
  NotRequired,
  ProductTrialDays,
} from '@prisma/client';

// 겹침 점수는 모두 순수 함수다. 서비스와 카드 모델이 같은 규칙을 쓴다.
// 점수는 순서를 정하는 데만 쓰고, 이유(reasons)는 카드와 상세의 "나와 잘 맞는 이유"가 된다.

// 크리에이터의 협업 원칙 가운데 점수가 보는 것(PrinciplesModel이 그대로 들어간다).
export interface Principles {
  fields: IndustryCategory[];
  faceOk: boolean;
  scriptOk: boolean;
  feeBand: FeeBand;
  trialDays: ProductTrialDays;
}

// 캠페인에서 점수가 보는 것. industry는 캠페인을 낸 브랜드의 업종이다.
export interface CampaignFacts {
  industry: IndustryCategory;
  fee: number;
  notRequired: NotRequired[];
  trialDays: ProductTrialDays;
}

export type MatchReason = 'FIELD' | 'FACE' | 'SCRIPT' | 'FEE' | 'TRIAL';

// 희망 제작비 구간. 위 끝이 없는 구간은 max가 null이다.
export function feeBandRange(band: FeeBand): {
  min: number;
  max: number | null;
} {
  switch (band) {
    case 'W200K':
      return { min: 200000, max: 299999 };
    case 'W300K':
      return { min: 300000, max: 399999 };
    case 'W400K':
      return { min: 400000, max: 499999 };
    case 'W500K_PLUS':
      return { min: 500000, max: null };
  }
}

// 규칙마다 1점. 솔직 후기는 캠페인에 맞춰 볼 항목이 없어 점수에 넣지 않는다(설계 3장 "추천").
// 제작비는 구간에 들거나 그보다 높으면 맞는 것이라 구간의 아래 끝만 본다.
export function matchScore(
  p: Principles,
  c: CampaignFacts,
): { score: number; reasons: MatchReason[] } {
  const reasons: MatchReason[] = [];
  if (p.fields.includes(c.industry)) reasons.push('FIELD');
  if (p.faceOk || c.notRequired.includes('FACE')) reasons.push('FACE');
  if (p.scriptOk || c.notRequired.includes('SCRIPT_READING')) {
    reasons.push('SCRIPT');
  }
  if (c.fee >= feeBandRange(p.feeBand).min) reasons.push('FEE');
  if (p.trialDays === 'ANY' || p.trialDays === c.trialDays) {
    reasons.push('TRIAL');
  }
  return { score: reasons.length, reasons };
}

export interface RegionMatch {
  sameSigungu: boolean;
  sameSido: boolean;
}

// 가게와 크리에이터의 활동 지역을 견준다. 구·군이 같아도 시·도가 같아야 한다(다른 시·도에도 같은 구 이름이 있다).
export function regionMatch(
  store: { regionSido: string | null; regionSigungu: string | null },
  creator: { regionSido: string; regionSigungu: string | null },
): RegionMatch {
  const sameSido = store.regionSido === creator.regionSido;
  return {
    sameSido,
    sameSigungu:
      sameSido &&
      creator.regionSigungu !== null &&
      store.regionSigungu === creator.regionSigungu,
  };
}

// 가게 점수: 분야가 맞으면 1, 같은 구·군 2, 같은 시·도 1. 구·군이 같으면 시·도 점수는 따로 더하지 않는다.
// 협업 원칙이 없으면 분야는 맞춰 볼 수 없다.
export function storeScore(
  p: Pick<Principles, 'fields'> | null,
  s: { industry: IndustryCategory },
  region: RegionMatch,
): number {
  const field = p?.fields.includes(s.industry) ? 1 : 0;
  const place = region.sameSigungu ? 2 : region.sameSido ? 1 : 0;
  return field + place;
}
