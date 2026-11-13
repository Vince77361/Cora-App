import { ApiProperty } from '@nestjs/swagger';
import { CollaborationKind, CollaborationStage } from '@prisma/client';
import { OfferTermsModel } from '../../stores/dto/offer-terms.model';
import { StoreSummaryModel } from '../../stores/dto/store-public.model';
import { CancelRequestModel } from './cancel-request.model';

export const COLLABORATION_ROLES = ['COMMISSIONER', 'CREATOR'] as const;
export const COLLABORATION_STEP_KEYS = [
  'ACCEPTED',
  'PAID',
  'VISIT',
  'SUBMIT',
  'SETTLE',
] as const;
export const COLLABORATION_STEP_STATES = ['DONE', 'NOW', 'TODO'] as const;
export const COLLABORATION_VIEW_REPORT_STATUSES = [
  'NONE',
  'COUNTING',
  'UNCONFIRMED',
  'CONFIRMED',
  'DISPUTED',
] as const;
export const PAYOUT_STATUSES = [
  'NONE',
  'NEEDS_ACCOUNT',
  'PENDING',
  'DONE',
  'FAILED',
] as const;

export class CollaborationCounterpartModel {
  @ApiProperty({
    description:
      '크리에이터에게는 가게 이름, 사장님에게는 크리에이터의 활동 이름.',
  })
  name!: string;

  @ApiProperty({ type: String, nullable: true })
  photoUrl!: string | null;
}

export class CollaborationStepModel {
  @ApiProperty({
    enum: COLLABORATION_STEP_KEYS,
    enumName: 'CollaborationStepKey',
    description:
      '오퍼 수락, 가게 결제, 방문·촬영, 링크 제출, 조회수 집계 후 지급. 항상 이 다섯 개가 이 순서로 온다.',
  })
  key!: (typeof COLLABORATION_STEP_KEYS)[number];

  @ApiProperty({
    enum: COLLABORATION_STEP_STATES,
    enumName: 'CollaborationStepState',
    description:
      'DONE: 끝남, NOW: 지금 하는 단계, TODO: 아직. 끝난 협업에는 NOW가 없다.',
  })
  state!: (typeof COLLABORATION_STEP_STATES)[number];

  @ApiProperty({
    type: String,
    format: 'date-time',
    nullable: true,
    description:
      '그 단계가 끝난 시각. 기록이 없는 단계(방문·촬영)와 끝나지 않은 단계는 null.',
  })
  at!: string | null;
}

export class CollaborationSettlementModel {
  @ApiProperty({
    type: 'integer',
    nullable: true,
    description: '정산에 쓴 최종 조회수.',
  })
  finalViews!: number | null;

  @ApiProperty({
    type: 'integer',
    description: '크리에이터에게 가는 금액(원).',
  })
  payoutAmount!: number;

  @ApiProperty({
    type: 'integer',
    description: '사장님에게 돌아가는 금액(원).',
  })
  refundAmount!: number;
}

// 협업 한 건. 크리에이터의 A7, 사장님의 협업 화면, 진행 중 목록, 지갑이 모두 이 모양을 읽는다.
export class CollaborationModel {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ enum: CollaborationKind, enumName: 'CollaborationKind' })
  kind!: CollaborationKind;

  @ApiProperty({ enum: CollaborationStage, enumName: 'CollaborationStage' })
  stage!: CollaborationStage;

  @ApiProperty({
    enum: COLLABORATION_ROLES,
    enumName: 'CollaborationRole',
    description:
      '내 쪽. COMMISSIONER는 맡긴 쪽(사장님·브랜드), CREATOR는 크리에이터.',
  })
  role!: (typeof COLLABORATION_ROLES)[number];

  @ApiProperty({ type: CollaborationCounterpartModel })
  counterpart!: CollaborationCounterpartModel;

  @ApiProperty({
    type: StoreSummaryModel,
    nullable: true,
    description:
      '가게 오퍼의 가게. 브랜드 계약이거나 가게를 읽을 수 없으면 null.',
  })
  store!: StoreSummaryModel | null;

  @ApiProperty({
    type: OfferTermsModel,
    description: '수락할 때의 조건(사본).',
  })
  terms!: OfferTermsModel;

  @ApiProperty({ type: [CollaborationStepModel] })
  steps!: CollaborationStepModel[];

  @ApiProperty({
    type: 'integer',
    description:
      '결제할 때 에스크로에 맡긴 금액(원). 협업이 끝날 때까지 그대로이고, 결제 전이거나 식사권만 있으면 0.',
  })
  escrowAmount!: number;

  @ApiProperty({
    type: String,
    format: 'date-time',
    nullable: true,
    description: '링크 제출 기한(결제 뒤 14일).',
  })
  submitDueAt!: string | null;

  @ApiProperty({ type: String, nullable: true })
  submittedUrl!: string | null;

  @ApiProperty({
    type: String,
    format: 'date-time',
    nullable: true,
    description: '조회수 집계가 끝나는 시각(제출 뒤 7일).',
  })
  countingEndsAt!: string | null;

  @ApiProperty({
    type: 'integer',
    nullable: true,
    description: '가장 최근에 읽은 조회수. 아직 읽은 값이 없으면 null.',
  })
  currentViews!: number | null;

  @ApiProperty({
    type: 'integer',
    nullable: true,
    description:
      '지금까지 받을 금액(원). 집계 중일 때 크리에이터에게만 숫자다.',
  })
  earnedSoFar!: number | null;

  @ApiProperty({
    type: 'integer',
    nullable: true,
    description: '예상 환급액(원). 집계 중일 때 사장님에게만 숫자다.',
  })
  expectedRefund!: number | null;

  @ApiProperty({
    type: CollaborationSettlementModel,
    nullable: true,
    description:
      '정산이 확정된 뒤의 결과. 정산 전이거나(조회 자료 확인 전 포함) 식사권만 있으면 null.',
  })
  settlement!: CollaborationSettlementModel | null;

  @ApiProperty({
    enum: COLLABORATION_VIEW_REPORT_STATUSES,
    enumName: 'CollaborationViewReportStatus',
    description:
      '조회 자료 확인 단계. NONE: 조회수 수당이 없거나 링크 제출 전, COUNTING: 집계 중, UNCONFIRMED: 계산이 나와 확인을 기다림, CONFIRMED: 확인됨, DISPUTED: 이의 중.',
  })
  viewReportStatus!: (typeof COLLABORATION_VIEW_REPORT_STATUSES)[number];

  @ApiProperty({
    enum: PAYOUT_STATUSES,
    enumName: 'PayoutStatus',
    description:
      'NONE: 줄 돈이 없음(정산 전이거나 0원), NEEDS_ACCOUNT: 지급 계좌 등록이 필요함(크리에이터에게만), PENDING: 지급일을 기다림, DONE: 지급됨, FAILED: 송금 실패(운영팀이 확인).',
  })
  payoutStatus!: (typeof PAYOUT_STATUSES)[number];

  @ApiProperty({
    type: String,
    format: 'date-time',
    nullable: true,
    description:
      '지급이 PENDING이고 계좌가 있을 때 송금할 지급일. 크리에이터에게만.',
  })
  payoutScheduledFor!: string | null;

  @ApiProperty({
    type: CancelRequestModel,
    nullable: true,
    description: '답을 기다리는 취소 요청.',
  })
  cancelRequest!: CancelRequestModel | null;

  @ApiProperty({
    description:
      '크리에이터가 지금 협업을 그만둘 수 있으면 true(링크를 제출하기 전).',
  })
  canCancel!: boolean;

  @ApiProperty({
    description: '사장님이 지금 취소 요청을 보낼 수 있으면 true.',
  })
  canRequestCancel!: boolean;
}
