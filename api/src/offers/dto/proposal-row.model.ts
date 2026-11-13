import { ApiProperty } from '@nestjs/swagger';
import { ContentFormat, OfferEndReason } from '@prisma/client';
import { END_KINDS, PROPOSAL_GROUPS } from '../proposal-rules';
import type { EndKind, ProposalGroup } from '../proposal-rules';

// 제안함 줄에 보이는 상대. 사장님에게는 크리에이터, 크리에이터에게는 가게다.
export class ProposalCounterpartModel {
  @ApiProperty()
  name!: string;

  @ApiProperty({ type: String, nullable: true })
  photoUrl!: string | null;
}

// 제안함(F3)의 한 줄.
export class ProposalRowModel {
  @ApiProperty({ format: 'uuid' })
  offerId!: string;

  @ApiProperty({ type: ProposalCounterpartModel })
  counterpart!: ProposalCounterpartModel;

  @ApiProperty({
    enum: PROPOSAL_GROUPS,
    enumName: 'ProposalGroup',
    description:
      'MY_TURN: 내가 응답할 차례. WAITING: 상대 대기. ENDED: 끝난 제안.',
  })
  group!: ProposalGroup;

  @ApiProperty({ type: 'integer', description: '최신 판본의 번호.' })
  version!: number;

  @ApiProperty({
    description: '상대가 쓴 최신 판본이 번호 2 이상이면 true(역제안).',
  })
  counter!: boolean;

  @ApiProperty({ enum: ContentFormat, enumName: 'ContentFormat' })
  format!: ContentFormat;

  @ApiProperty({ type: 'integer' })
  pieces!: number;

  @ApiProperty({
    type: 'integer',
    nullable: true,
    description:
      '상대 대기(WAITING)일 때 남은 응답 기한(올림). 하루가 안 남았으면 0. 그 밖에는 null.',
  })
  daysLeft!: number | null;

  @ApiProperty({
    enum: END_KINDS,
    enumName: 'ProposalEndKind',
    nullable: true,
    description:
      '끝난 제안(ENDED)의 갈래. AGREED: 합의 완료, ENDED: 사유를 골라 끝냄, EXPIRED: 기한이 지나 끝남. 그 밖에는 null.',
  })
  endKind!: EndKind | null;

  @ApiProperty({
    enum: OfferEndReason,
    enumName: 'OfferEndReason',
    nullable: true,
    description: '끝낸 쪽이 고른 사유. 사유 없이 끝났으면 null.',
  })
  endReason!: OfferEndReason | null;

  @ApiProperty({
    type: String,
    format: 'uuid',
    nullable: true,
    description: '합의해 만들어진 협업의 id. 합의 전이면 null.',
  })
  collaborationId!: string | null;
}
