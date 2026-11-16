// 캠페인 입력의 고정 값(4번 계획 Global Constraints, 설계 3장 "캠페인 예산").
// DB CHECK(campaigns_budget_range, campaigns_must_include_max)와 같은 값이다.
export const CAMPAIGN_RULES = {
  // 제작비와 예산은 1만 원 단위다.
  moneyStep: 10000,
  feeMin: 10000,
  feeMax: 10000000,
  budgetMax: 100000000,
  headlineMax: 40,
  mustIncludeMax: 3,
  mustIncludeLength: 20,
} as const;
