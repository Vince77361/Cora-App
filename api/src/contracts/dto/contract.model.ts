import { ApiProperty } from '@nestjs/swagger';
import { PaymentQuoteModel } from '../../payments/dto/payment-quote.model';
import { TermsVersionModel } from '../../terms/dto/terms-version.model';

export const CONTRACT_STATUSES = [
  'NOT_READY',
  'AWAITING_CREATOR',
  'AWAITING_BRAND',
  'PAYING',
  'CONCLUDED',
] as const;

// 계약 화면(D4)이 그리는 값. 계약 전에는 미리 보기(최신 판본)이고, 계약 행이 생기면 그 계약의 사본이다.
export class ContractModel {
  @ApiProperty({
    enum: CONTRACT_STATUSES,
    enumName: 'ContractStatus',
    description:
      'NOT_READY = 양쪽이 같은 판본을 확인하기 전(미리 보기), AWAITING_CREATOR = 합의됨·크리에이터 동의 전, AWAITING_BRAND = 크리에이터 동의 뒤·브랜드 동의(결제) 전, PAYING = 브랜드가 결제 중(결제창을 연 지 60분 안), CONCLUDED = 결제가 승인돼 체결됨.',
  })
  status!: (typeof CONTRACT_STATUSES)[number];

  @ApiProperty({
    type: 'integer',
    nullable: true,
    description: '계약이 담은(미리 보기면 최신) 판본 번호. 판본이 없으면 null.',
  })
  termsVersion!: number | null;

  @ApiProperty({
    type: TermsVersionModel,
    nullable: true,
    description:
      '조건. 계약 행이 있으면 동의할 때 만든 사본이고, 없으면 최신 판본(미리 보기)이다.',
  })
  terms!: TermsVersionModel | null;

  @ApiProperty()
  brandName!: string;

  @ApiProperty()
  creatorName!: string;

  @ApiProperty({
    type: String,
    isArray: true,
    description:
      '내 쪽 확인란 세 줄. 동의할 때 이 문구를 그대로 보낸다(다르면 400). 계약할 수 없는 상태면 빈 배열.',
  })
  myConsentTexts!: string[];

  @ApiProperty({ type: String, format: 'date-time', nullable: true })
  creatorConsentedAt!: string | null;

  @ApiProperty({
    type: String,
    format: 'date-time',
    nullable: true,
    description: '결제가 승인돼 체결될 때 채워진다.',
  })
  brandConsentedAt!: string | null;

  @ApiProperty({ type: String, format: 'date-time', nullable: true })
  concludedAt!: string | null;

  @ApiProperty({
    type: PaymentQuoteModel,
    nullable: true,
    description:
      '브랜드에게만, 동의하면 결제할 금액(크리에이터 동의 뒤 결제 전). 서버가 계약 사본에서 계산한 값이다.',
  })
  quote!: PaymentQuoteModel | null;

  @ApiProperty({
    description:
      '내 동의가 새 판본으로 취소됐고 새 계약이 아직 없다(앱이 "조건이 바뀌어 동의가 취소됐어요." 띠를 보여 준다).',
  })
  voidedNotice!: boolean;
}
