import type { IndustryCategory } from '@prisma/client';
import { RECOMMEND_POLICY } from '../common/collaboration-policy';

// "주로 만드는 콘텐츠"(자유 글)가 가게의 업종 분류와 맞는지 보는 낱말 표. 글에 낱말이 하나라도 들어 있으면 맞는 것으로 본다.
// 크리에이터의 "받고 싶은 분야"는 4번 계획이 만들면 이 판정에 더한다.
export const INDUSTRY_KEYWORDS: Record<IndustryCategory, string[]> = {
  FOOD_CAFE: [
    '맛집',
    '카페',
    '식당',
    '음식',
    '먹',
    '라멘',
    '디저트',
    '커피',
    '베이커리',
    '빵',
  ],
  BEAUTY: ['뷰티', '미용', '화장', '메이크업', '스킨케어', '헤어', '네일'],
  FASHION: ['패션', '옷', '룩북', '코디', '의류'],
  ACCESSORY: ['액세서리', '주얼리', '악세사리', '반지', '귀걸이'],
  LIVING: ['리빙', '인테리어', '소품', '집꾸미기'],
  GROCERY: ['식품', '푸드', '간식', '요리', '레시피'],
  DIGITAL: ['전자', '디지털', '가전', '테크'],
  HEALTH: ['건강', '운동', '헬스', '필라테스', '요가'],
  OTHER: [],
  ALCOHOL: ['주류', '술', '와인', '맥주', '위스키'],
  GAMBLING: [],
  LOAN: [],
  DIET_SUPPLEMENT: ['다이어트', '영양제'],
};

// 이유 글에 쓰는 업종 분류 이름. 앱의 IndustryCategory.label과 같다.
export const INDUSTRY_LABELS: Record<IndustryCategory, string> = {
  FOOD_CAFE: '맛집·카페',
  BEAUTY: '뷰티·미용',
  FASHION: '패션',
  ACCESSORY: '액세서리·주얼리',
  LIVING: '리빙·소품',
  GROCERY: '식품',
  DIGITAL: '전자·디지털',
  HEALTH: '건강·운동',
  OTHER: '기타',
  ALCOHOL: '주류',
  GAMBLING: '도박·사행성',
  LOAN: '대출·금융',
  DIET_SUPPLEMENT: '다이어트 보조제',
};

// 점수 입력. 팔로워 수 칸이 없다: 팔로워는 점수에 넣지 않는다(설계 G2).
export interface ApplicantFacts {
  regionSido: string;
  regionSigungu: string | null;
  contentFocus: string | null;
  hasPitch: boolean;
  finishedCount: number;
}

export interface StoreFacts {
  regionSido: string | null;
  regionSigungu: string | null;
  industry: IndustryCategory;
}

export interface Candidate extends ApplicantFacts {
  id: string;
  createdAt: Date;
  skippedFromPicksAt: Date | null;
}

function sameDistrict(a: ApplicantFacts, store: StoreFacts): boolean {
  return (
    store.regionSido !== null &&
    store.regionSigungu !== null &&
    a.regionSido === store.regionSido &&
    a.regionSigungu === store.regionSigungu
  );
}

function sameProvince(a: ApplicantFacts, store: StoreFacts): boolean {
  return store.regionSido !== null && a.regionSido === store.regionSido;
}

function industryMatches(a: ApplicantFacts, store: StoreFacts): boolean {
  const focus = a.contentFocus?.trim();
  if (!focus) return false;
  return INDUSTRY_KEYWORDS[store.industry].some((word) => focus.includes(word));
}

// 같은 구·군 3, 같은 시·도 1(구·군이 같으면 3만), 분야 맞음 2, 한 줄 1, 마친 협업 건당 1(최대 2).
export function scoreApplicant(a: ApplicantFacts, store: StoreFacts): number {
  let score = 0;
  if (sameDistrict(a, store)) score += RECOMMEND_POLICY.sameSigungu;
  else if (sameProvince(a, store)) score += RECOMMEND_POLICY.sameSido;
  if (industryMatches(a, store)) score += RECOMMEND_POLICY.industryMatch;
  if (a.hasPitch) score += RECOMMEND_POLICY.hasPitch;
  score += Math.min(
    Math.max(a.finishedCount, 0) * RECOMMEND_POLICY.perFinished,
    RECOMMEND_POLICY.finishedMax,
  );
  return score;
}

// 점수에 쓴 사실로 만들 수 있는 조각만 말한다. 같은 시·도와 한 줄은 화면에 따로 보이는 사실이라 이유 글에 넣지 않는다.
export function reasonsFor(a: ApplicantFacts, store: StoreFacts): string[] {
  const reasons: string[] = [];
  if (sameDistrict(a, store)) reasons.push('같은 동네예요');
  if (industryMatches(a, store)) {
    reasons.push(`${INDUSTRY_LABELS[store.industry]} 콘텐츠를 만들어요`);
  }
  if (a.finishedCount > 0) {
    reasons.push(`지난 협업을 ${a.finishedCount}번 마쳤어요`);
  }
  return reasons;
}

// 점수 높은 순, 같으면 먼저 지원한 순(그래도 같으면 id 순으로 결과를 고정한다). 추천에서 넘긴 지원은 뺀다.
export function pickRecommended<T extends Candidate>(
  applicants: T[],
  store: StoreFacts,
  limit: number = RECOMMEND_POLICY.picks,
): T[] {
  return applicants
    .filter((a) => a.skippedFromPicksAt === null)
    .map((a) => ({ a, score: scoreApplicant(a, store) }))
    .sort(
      (x, y) =>
        y.score - x.score ||
        x.a.createdAt.getTime() - y.a.createdAt.getTime() ||
        x.a.id.localeCompare(y.a.id),
    )
    .slice(0, limit)
    .map(({ a }) => a);
}
