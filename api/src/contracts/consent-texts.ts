import type { BrandUsageRights } from '@prisma/client';
import { josa } from '../common/josa';

export type ConsentRole = 'CREATOR' | 'BRAND';

const USAGE_TEXTS: Record<BrandUsageRights, string> = {
  REPOST_ONLY: '콘텐츠는 브랜드 계정 재게시에만 쓰여요',
  ADS_TOO: '콘텐츠는 브랜드 계정 재게시와 광고 소재로 쓰여요',
  NONE: '콘텐츠는 브랜드가 따로 활용하지 않아요',
};

// 계약 동의의 확인란 세 줄. 동의할 때 사용자가 확인한 문구를 그대로 계약에 저장하므로 서버가 만든 값과 정확히 같아야 한다.
// 1 합의한 판본, 2 광고 표시 의무(크리에이터는 지키고 브랜드는 요청한다), 3 합의한 활용 권한.
// 판본 번호 뒤의 을/를은 숫자를 한글로 읽은 마지막 소리에 맞춘다("1을", "2를").
export function consentTexts(
  role: ConsentRole,
  version: number,
  usage: BrandUsageRights,
): [string, string, string] {
  return [
    `합의한 조건 버전 ${josa(String(version), '을/를')} 확인했어요`,
    role === 'CREATOR' ? '광고 표시 의무를 지킬게요' : '광고 표시를 요청할게요',
    USAGE_TEXTS[usage],
  ];
}
