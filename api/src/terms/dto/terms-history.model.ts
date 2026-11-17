import { ApiProperty } from '@nestjs/swagger';
import { TermsVersionModel } from './terms-version.model';

export const TERMS_AGREEMENTS = [
  'NONE',
  'WAITING_BRAND',
  'WAITING_CREATOR',
  'AGREED',
] as const;

// 조건 판본의 이력(12 화면). 최신 판본의 확인 상태만 본다: 이전 판본에 했던 수락은 합의에 세지 않는다.
export class TermsHistoryModel {
  @ApiProperty({
    type: [TermsVersionModel],
    description: '판본 목록. 최신이 먼저다.',
  })
  versions!: TermsVersionModel[];

  @ApiProperty({
    enum: TERMS_AGREEMENTS,
    enumName: 'TermsAgreement',
    description:
      '최신 판본의 확인 상태. NONE = 아무도 확인하지 않음, WAITING_BRAND = 크리에이터만 확인, WAITING_CREATOR = 브랜드만 확인, AGREED = 양쪽 확인.',
  })
  agreement!: (typeof TERMS_AGREEMENTS)[number];

  @ApiProperty({
    description:
      '조건 수정 제안을 낼 수 있다: 협의할 수 있는 단계이고 브랜드 결제가 진행 중이 아니다.',
  })
  editable!: boolean;
}
