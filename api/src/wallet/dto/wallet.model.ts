import { ApiProperty } from '@nestjs/swagger';
import { CollaborationStage, ContentFormat } from '@prisma/client';

export const WALLET_ENTRY_KINDS = [
  'PAYOUT_SCHEDULED',
  'PAYOUT_DONE',
  'PAYOUT_FAILED',
  'HELD',
  'VOUCHER',
] as const;

export class WalletNextPayoutModel {
  @ApiProperty({
    description:
      '가장 이른 지급 예정일(한국 시간 YYYY-MM-DD). 지급은 수요일 10:00에 나간다.',
    example: '2026-11-18',
  })
  date!: string;

  @ApiProperty({
    type: 'integer',
    description: '그날 한국 시간으로 나갈 지급의 합(원).',
  })
  amount!: number;
}

export class WalletAccountModel {
  @ApiProperty({ description: '짧은 은행 이름. 예: 국민' })
  bankName!: string;

  @ApiProperty({ description: '화면에 보이는 은행 이름. 예: 국민은행' })
  bankFullName!: string;

  @ApiProperty({ description: '계좌번호 뒤 4자리. 전체 번호는 나가지 않는다.' })
  accountLast4!: string;

  @ApiProperty()
  holderName!: string;
}

export class WalletEntryModel {
  @ApiProperty({ format: 'uuid' })
  collaborationId!: string;

  @ApiProperty({
    description:
      '크리에이터에게는 가게 이름. 읽을 수 없으면 "가게"(브랜드 계약은 "브랜드").',
  })
  counterpartName!: string;

  @ApiProperty({ enum: ContentFormat, enumName: 'ContentFormat' })
  format!: ContentFormat;

  @ApiProperty({
    type: 'integer',
    description: '콘텐츠 편 수. 오퍼는 지금 한 편이다.',
  })
  pieces!: number;

  @ApiProperty({
    enum: WALLET_ENTRY_KINDS,
    enumName: 'WalletEntryKind',
    description:
      'PAYOUT_SCHEDULED: 정산이 확정되고 송금 전, PAYOUT_DONE: 송금 끝, PAYOUT_FAILED: 송금 실패(운영팀이 확인), HELD: Cora가 보관 중, VOUCHER: 식사권.',
  })
  kind!: (typeof WALLET_ENTRY_KINDS)[number];

  @ApiProperty({
    type: 'integer',
    nullable: true,
    description: '금액(원). 식사권 줄은 null.',
  })
  amount!: number | null;

  @ApiProperty({
    type: 'integer',
    nullable: true,
    description: '정산에 쓴 최종 조회수. 지급 줄에서만 값이 있다.',
  })
  views!: number | null;

  @ApiProperty({
    type: String,
    nullable: true,
    description: '식사권 이름. 식사권 줄에서만 값이 있다.',
  })
  voucherName!: string | null;

  @ApiProperty({
    type: Boolean,
    nullable: true,
    description:
      '링크를 제출해 식사권을 쓴 것으로 보면 true. 식사권 줄에서만 값이 있다.',
  })
  voucherUsed!: boolean | null;

  @ApiProperty({ enum: CollaborationStage, enumName: 'CollaborationStage' })
  stage!: CollaborationStage;

  @ApiProperty({
    type: String,
    format: 'date-time',
    description:
      '줄의 기준 시각. 지급 예정은 정산 시각, 지급 완료는 송금 시각, 보관 중은 보관 시작.',
  })
  at!: string;
}

// 크리에이터의 정산 화면(E7). 숫자는 모두 서버가 계산한다.
export class WalletModel {
  @ApiProperty({
    type: WalletNextPayoutModel,
    nullable: true,
    description: '지급 예정이 없으면 null.',
  })
  nextPayout!: WalletNextPayoutModel | null;

  @ApiProperty({
    type: WalletAccountModel,
    nullable: true,
    description: '등록 전이면 null.',
  })
  account!: WalletAccountModel | null;

  @ApiProperty({
    type: 'integer',
    description: '이번 달(한국 시간) 송금이 끝난 지급의 합(원).',
  })
  receivedThisMonth!: number;

  @ApiProperty({
    type: 'integer',
    description: '지금 Cora가 보관 중인 내 협업들의 금액 합(원).',
  })
  heldAmount!: number;

  @ApiProperty({
    type: [WalletEntryModel],
    description: '기준 시각 최신순. 식사권 줄은 같은 협업의 돈 줄 바로 아래.',
  })
  entries!: WalletEntryModel[];
}
