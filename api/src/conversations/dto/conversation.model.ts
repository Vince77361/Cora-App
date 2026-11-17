import { ApiProperty } from '@nestjs/swagger';
import {
  CollaborationKind,
  CollaborationStage,
  ContentFormat,
  ConversationStatus,
  MessageKind,
} from '@prisma/client';
import {
  COLLABORATION_ROLES,
  CONTRACT_PROGRESS,
} from '../../collaborations/dto/collaboration.model';
import { OfferTermsModel } from '../../stores/dto/offer-terms.model';
import { TermsVersionModel } from '../../terms/dto/terms-version.model';

export const CONVERSATION_SECTIONS = ['REQUEST', 'NORMAL'] as const;

export class ConversationCounterpartModel {
  @ApiProperty({ format: 'uuid' })
  userId!: string;

  @ApiProperty({
    description:
      '크리에이터에게는 브랜드 이름이나 가게 이름, 맡긴 쪽에게는 크리에이터의 활동 이름.',
  })
  name!: string;

  @ApiProperty({ type: String, nullable: true })
  photoUrl!: string | null;
}

export class ConversationLastMessageModel {
  @ApiProperty({ enum: MessageKind, enumName: 'MessageKind' })
  kind!: MessageKind;

  @ApiProperty({
    description:
      '한 줄 미리 보기. 글은 60자에서 자르고 …을 붙인다. 안내 줄은 읽는 사람에 맞춘 문구.',
  })
  preview!: string;

  @ApiProperty({ type: String, format: 'date-time' })
  at!: string;
}

export class ConversationSummaryModel {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ enum: CollaborationKind, enumName: 'CollaborationKind' })
  kind!: CollaborationKind;

  @ApiProperty({ enum: ConversationStatus, enumName: 'ConversationStatus' })
  status!: ConversationStatus;

  @ApiProperty({
    enum: CONVERSATION_SECTIONS,
    enumName: 'ConversationSection',
    description:
      'REQUEST: 내가 답해야 하는 메시지 요청(목록 맨 위에 모인다). 그 밖은 NORMAL.',
  })
  section!: (typeof CONVERSATION_SECTIONS)[number];

  @ApiProperty({ type: ConversationCounterpartModel })
  counterpart!: ConversationCounterpartModel;

  @ApiProperty({ description: '캠페인 한 줄 또는 가게 이름.' })
  contextLabel!: string;

  @ApiProperty({ type: ConversationLastMessageModel, nullable: true })
  lastMessage!: ConversationLastMessageModel | null;

  @ApiProperty({
    type: 'integer',
    description: '내 읽은 번호 뒤에 상대나 안내로 온 메시지의 수.',
  })
  unreadCount!: number;

  @ApiProperty({ description: '이 방의 알림을 꺼 두었으면 true.' })
  muted!: boolean;
}

export class CampaignTermsModel {
  @ApiProperty({ type: 'integer', description: '캠페인의 제작비(원).' })
  fee!: number;

  @ApiProperty({ enum: ContentFormat, enumName: 'ContentFormat' })
  format!: ContentFormat;

  @ApiProperty()
  productProvided!: boolean;

  @ApiProperty({ type: String, format: 'date', description: '제작 시작.' })
  startFrom!: string;
}

export class ConversationDetailModel extends ConversationSummaryModel {
  @ApiProperty({ format: 'uuid' })
  collaborationId!: string;

  @ApiProperty({ enum: CollaborationStage, enumName: 'CollaborationStage' })
  stage!: CollaborationStage;

  @ApiProperty({
    enum: COLLABORATION_ROLES,
    enumName: 'CollaborationRole',
    // CollaborationModel.role과 같은 글: 열거형의 설명이 어느 쪽을 먼저 읽느냐에 따라 오가지 않게 한다.
    description:
      '내 쪽. COMMISSIONER는 맡긴 쪽(사장님·브랜드), CREATOR는 크리에이터.',
  })
  myRole!: (typeof COLLABORATION_ROLES)[number];

  @ApiProperty({ description: '내가 먼저 보낸 메시지 요청이면 true.' })
  requestedByMe!: boolean;

  @ApiProperty({ description: '내가 이 상대를 차단했으면 true.' })
  blockedByMe!: boolean;

  @ApiProperty({ type: 'integer' })
  lastSeq!: number;

  @ApiProperty({ type: 'integer' })
  lastReadSeq!: number;

  @ApiProperty({
    type: TermsVersionModel,
    nullable: true,
    description: '브랜드 계약의 최신 조건 버전. 아직 없으면 null.',
  })
  terms!: TermsVersionModel | null;

  @ApiProperty({
    type: CampaignTermsModel,
    nullable: true,
    description: '서로 관심 전(INQUIRY)의 캠페인 조건. 그 밖은 null.',
  })
  campaignTerms!: CampaignTermsModel | null;

  @ApiProperty({
    type: OfferTermsModel,
    nullable: true,
    description: '가게 오퍼의 수락된 판본의 조건(사본). 브랜드 계약은 null.',
  })
  storeTerms!: OfferTermsModel | null;

  @ApiProperty({
    enum: CONTRACT_PROGRESS,
    enumName: 'ContractProgress',
    description:
      'NONE: 계약 동의 전, AWAITING_BRAND: 크리에이터가 동의해 브랜드 결제 대기, CONCLUDED: 체결.',
  })
  contractStatus!: (typeof CONTRACT_PROGRESS)[number];

  @ApiProperty({
    description: '지금 글을 보낼 수 있으면 true(방이 열려 있다).',
  })
  canSend!: boolean;

  @ApiProperty({
    description: '크리에이터가 콘텐츠 카드를 보낼 수 있으면 true(카드가 있다).',
  })
  canSendContentCard!: boolean;

  @ApiProperty({ description: '조건 수정 제안을 보낼 수 있는 단계이면 true.' })
  canProposeTerms!: boolean;

  @ApiProperty({ description: '협의를 그만둘 수 있는 단계이면 true.' })
  canDrop!: boolean;

  @ApiProperty({
    description:
      '서로 관심 전, 크리에이터가 캠페인에 관심을 보낼 수 있으면 true.',
  })
  canLikeCampaign!: boolean;
}
