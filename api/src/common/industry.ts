import type { IndustryCategory } from '@prisma/client';

// 업종 분류의 이름표와 묶음. 이유 글(applications)과 협업 원칙 검증(principles)이 같은 값을 쓴다.
// 이름표는 앱의 IndustryCategory.label과 같다.
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

// 크리에이터가 "받고 싶은 분야"로 고르는 일반 업종 아홉 개.
export const GENERAL_INDUSTRIES = [
  'FOOD_CAFE',
  'BEAUTY',
  'FASHION',
  'ACCESSORY',
  'LIVING',
  'GROCERY',
  'DIGITAL',
  'HEALTH',
  'OTHER',
] as const satisfies readonly IndustryCategory[];

// 크리에이터가 "피하는 업종"으로 고를 수 있는 민감 업종 네 개. 나머지는 모두 일반 업종이다.
export const SENSITIVE_INDUSTRIES = [
  'ALCOHOL',
  'GAMBLING',
  'LOAN',
  'DIET_SUPPLEMENT',
] as const satisfies readonly IndustryCategory[];
