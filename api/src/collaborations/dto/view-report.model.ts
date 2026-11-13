import { ApiProperty } from '@nestjs/swagger';

export const VIEW_REPORT_STATUSES = [
  'COUNTING',
  'UNCONFIRMED',
  'CONFIRMED',
  'DISPUTED',
] as const;
export const VIEW_REPORT_SOURCES = [
  'CONNECTED_ACCOUNT',
  'CAPTURE_PENDING',
  'CAPTURE_CONFIRMED',
] as const;

// 보상 계산 상자(F4)의 줄. 지급 = 고정 현금 + 조회수 수당, 환불 = 상한 - 조회수 수당이다.
export class ViewReportCalcModel {
  @ApiProperty({ type: 'integer', description: '조회수 수당(원).' })
  viewPay!: number;

  @ApiProperty({ type: 'integer', description: '1,000회당 단가(원).' })
  ratePerThousand!: number;

  @ApiProperty({ type: 'integer', description: '조회수 수당 상한(원).' })
  cap!: number;

  @ApiProperty({ description: '수당이 상한에 걸렸으면 true.' })
  capApplied!: boolean;

  @ApiProperty({ type: 'integer', description: '고정 현금(원). 없으면 0.' })
  fixedCash!: number;

  @ApiProperty({
    type: 'integer',
    description: '맡긴 쪽에게 돌아가는 금액(원).',
  })
  refund!: number;

  @ApiProperty({
    type: 'integer',
    description: '크리에이터에게 가는 금액(원).',
  })
  payout!: number;
}

export class ViewReportEvidenceModel {
  @ApiProperty({
    type: String,
    nullable: true,
    description:
      '캡처 이미지를 읽는 주소(당사자에게만 주는, 기한이 있는 주소). 주소를 만들지 못했으면 null이다(화면은 그림 없이 조회수만 보여 준다).',
  })
  imageUrl!: string | null;

  @ApiProperty({ type: 'integer', description: '크리에이터가 적은 조회수.' })
  statedViews!: number;
}

// 조회 자료 확인(F4). 조회수 수당이 있는 협업의 집계 결과와 계산이다.
export class ViewReportModel {
  @ApiProperty({
    enum: VIEW_REPORT_STATUSES,
    enumName: 'ViewReportStatus',
    description:
      'COUNTING: 집계 중(계산 없음), UNCONFIRMED: 계산이 나왔고 확인을 기다림, CONFIRMED: 확인되어 정산됨, DISPUTED: 이의가 걸려 돈이 그대로 보관됨.',
  })
  status!: (typeof VIEW_REPORT_STATUSES)[number];

  @ApiProperty({
    type: 'integer',
    nullable: true,
    description:
      '조회수. 집계 중에는 그날까지 읽은 값(없으면 null), 계산이 나온 뒤에는 정산에 쓰는 값.',
  })
  views!: number | null;

  @ApiProperty({ description: '크리에이터가 낸 게시 링크.' })
  postUrl!: string;

  @ApiProperty({
    format: 'date-time',
    description: '집계 시작(링크 제출 시각).',
  })
  periodStart!: string;

  @ApiProperty({ format: 'date-time', description: '집계가 끝나는 시각.' })
  periodEnd!: string;

  @ApiProperty({
    enum: VIEW_REPORT_SOURCES,
    enumName: 'ViewReportSource',
    description:
      'CONNECTED_ACCOUNT: 연결한 인스타그램 계정에서 읽음, CAPTURE_PENDING: 캡처 자료(계산 전에 캡처가 제출된 상태, 또는 캡처로 만든 계산의 확인 전), CAPTURE_CONFIRMED: 캡처 자료(확정됨).',
  })
  source!: (typeof VIEW_REPORT_SOURCES)[number];

  @ApiProperty({
    type: ViewReportCalcModel,
    nullable: true,
    description: '계산. 집계 중에는 null이다.',
  })
  calc!: ViewReportCalcModel | null;

  @ApiProperty({
    type: String,
    format: 'date-time',
    nullable: true,
    description: '확인 전일 때 자동으로 확인되는 시각.',
  })
  confirmDueAt!: string | null;

  @ApiProperty({
    description:
      '내가 지금 "자료 확인했어요"를 누를 수 있으면 true(맡긴 쪽, 확인 전, 연결 계정 자료일 때만).',
  })
  canConfirm!: boolean;

  @ApiProperty({ description: '내가 지금 이의를 제기할 수 있으면 true.' })
  canDispute!: boolean;

  @ApiProperty({ description: '내가 지금 캡처 자료를 올릴 수 있으면 true.' })
  canUploadEvidence!: boolean;

  @ApiProperty({
    type: ViewReportEvidenceModel,
    nullable: true,
    description: '올라온 캡처 자료. 없으면 null.',
  })
  evidence!: ViewReportEvidenceModel | null;
}
