import { ApiProperty } from '@nestjs/swagger';
import { ContentFormat } from '@prisma/client';
import { ProposalCounterpartModel } from '../../offers/dto/proposal-row.model';
import { END_KINDS, PROPOSAL_GROUPS } from '../../offers/proposal-rules';
import type { EndKind, ProposalGroup } from '../../offers/proposal-rules';
import { DROP_CHOICES } from '../../collaborations/dto/drop-collaboration.dto';
import type { DropChoice } from '../../collaborations/dto/drop-collaboration.dto';

// 제안함(F3)의 브랜드 계약 줄. 가게 오퍼 줄(ProposalRowModel)과 칸 이름과 값이 같아 앱이 한 목록으로 합친다.
// 묶음·끝난 갈래·그만둔 이유는 다른 모델과 공유하는 열거형이라 설명을 원래 모델과 똑같이 둔다(다르면 생성 코드의 설명이 한 곳의 것으로 덮인다).
// 값의 뜻: group MY_TURN은 내가 최신 조건을 아직 확인하지 않았다, WAITING은 나는 확인했고 상대가 아직이다, ENDED는 합의했거나 그만뒀다.
// endKind AGREED는 합의, ENDED는 그만뒀다(이 줄에는 EXPIRED가 없다). myDropReason은 내가 그만뒀을 때 내가 고른 이유이고 상대에게는 항상 null이다.
// 가게 줄에는 kind가 없고 offerId가 있으며, 이 줄은 kind가 BRAND_CONTRACT이고 collaborationId가 항상 있다.
export class ProposalInboxRowModel {
  @ApiProperty({ enum: ['BRAND_CONTRACT'] })
  kind!: 'BRAND_CONTRACT';

  @ApiProperty({ format: 'uuid' })
  collaborationId!: string;

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
    enum: END_KINDS,
    enumName: 'ProposalEndKind',
    nullable: true,
    description:
      '끝난 제안(ENDED)의 갈래. AGREED: 합의 완료, ENDED: 사유를 골라 끝냄, EXPIRED: 기한이 지나 끝남. 그 밖에는 null.',
  })
  endKind!: EndKind | null;

  @ApiProperty({
    enum: DROP_CHOICES,
    enumName: 'DropReasonChoice',
    nullable: true,
    description:
      '그만두는 이유. 서버에만 남고 상대에게는 알리지 않는다(상대는 "이번에는 함께하기 어렵대요."만 본다).',
  })
  myDropReason!: DropChoice | null;

  @ApiProperty({
    type: String,
    format: 'date-time',
    description: '최신 판본의 확인이나 협업 상태가 마지막으로 바뀐 시각.',
  })
  updatedAt!: string;
}
