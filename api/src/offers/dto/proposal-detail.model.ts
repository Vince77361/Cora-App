import { ApiProperty } from '@nestjs/swagger';
import { OfferEndReason } from '@prisma/client';
import { OFFER_VIEWS } from '../offer-rules';
import type { OfferView } from '../offer-rules';
import { END_KINDS, PROPOSAL_GROUPS } from '../proposal-rules';
import type { EndKind, ProposalGroup } from '../proposal-rules';
import { OFFER_PARTIES, OfferVersionModel } from './offer-version.model';
import type { OfferPartyValue } from './offer-version.model';

export class ProposalStoreModel {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty()
  name!: string;

  @ApiProperty({ type: String, nullable: true })
  recruitLine!: string | null;
}

export class ProposalPersonModel {
  @ApiProperty({ format: 'uuid' })
  userId!: string;

  @ApiProperty()
  name!: string;

  @ApiProperty({ type: String, nullable: true })
  photoUrl!: string | null;
}

// 제안 상세. 가장 새 판본과 바로 앞 판본, 달라진 항목을 함께 준다.
export class ProposalDetailModel {
  @ApiProperty({ format: 'uuid' })
  offerId!: string;

  @ApiProperty({
    enum: OFFER_VIEWS,
    enumName: 'OfferView',
    description:
      '내가 보는 상태. 크리에이터가 방금 거절해 되돌릴 수 있는 동안 사장님에게는 WAITING이다.',
  })
  status!: OfferView;

  @ApiProperty({
    enum: OFFER_PARTIES,
    enumName: 'OfferParty',
    description: '이 제안에서 나는 어느 쪽인가.',
  })
  myParty!: OfferPartyValue;

  @ApiProperty({ enum: PROPOSAL_GROUPS, enumName: 'ProposalGroup' })
  group!: ProposalGroup;

  @ApiProperty({ type: OfferVersionModel })
  latest!: OfferVersionModel;

  @ApiProperty({
    type: OfferVersionModel,
    nullable: true,
    description: '바로 앞 판본. 첫 판본이면 null.',
  })
  previous!: OfferVersionModel | null;

  @ApiProperty({
    type: [String],
    description:
      '앞 판본과 달라진 항목(FORMAT, VOUCHER, FIXED_CASH, VIEW_PAY, USAGE_RIGHTS, IDEA, PRINCIPLES, SERIES). 화면이 보여 주는 순서다.',
  })
  changed!: string[];

  @ApiProperty({ type: ProposalStoreModel })
  store!: ProposalStoreModel;

  @ApiProperty({
    type: ProposalPersonModel,
    description:
      '상대. 사장님에게는 크리에이터, 크리에이터에게는 가게의 사장님이다(이름과 사진은 가게의 것).',
  })
  counterpart!: ProposalPersonModel;

  @ApiProperty({
    type: 'integer',
    description: '결제 때 더해지는 수수료율(%).',
  })
  feeRate!: number;

  @ApiProperty({
    description:
      '답을 기다리는 제안이고 조회수 수당이 켜져 있는데 크리에이터가 인스타그램을 연동하지 않았으면 true.',
  })
  needsInstagram!: boolean;

  @ApiProperty({ format: 'date-time', description: '응답 기한(ISO 8601).' })
  expiresAt!: Date;

  @ApiProperty({
    enum: END_KINDS,
    enumName: 'ProposalEndKind',
    nullable: true,
  })
  endKind!: EndKind | null;

  @ApiProperty({
    enum: OfferEndReason,
    enumName: 'OfferEndReason',
    nullable: true,
  })
  endReason!: OfferEndReason | null;

  @ApiProperty({ type: String, format: 'uuid', nullable: true })
  collaborationId!: string | null;
}
