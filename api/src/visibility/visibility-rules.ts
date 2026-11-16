import type { IndustryCategory } from '@prisma/client';

// 크리에이터가 피하는 업종의 상대인지. 원칙이 없으면 피하는 것이 없다.
// 순수 함수라서 서비스와 4번 계획의 카드·추천 계산이 같은 규칙을 쓴다.
export function isBlocked(
  principles: { blockedIndustries: IndustryCategory[] } | null,
  viewerIndustry: IndustryCategory,
): boolean {
  return principles?.blockedIndustries.includes(viewerIndustry) ?? false;
}
