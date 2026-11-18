import { ApiProperty } from '@nestjs/swagger';
import { ContentFormat, FeeBand, SwipeTargetKind } from '@prisma/client';
import { IsIn, IsOptional } from 'class-validator';

export const INTEREST_STATES = ['MUTUAL', 'WAITING', 'HELD'] as const;
export const INTEREST_TABS = ['saved', 'mutual', 'sent', 'held'] as const;

export class ListInterestsQuery {
  @ApiProperty({
    enum: INTEREST_TABS,
    enumName: 'InterestTab',
    required: false,
    description:
      'saved(기본) = 내 하트 + 저장, mutual = 서로 관심, sent = 보낸 관심(응답 대기), held = 저장.',
  })
  @IsOptional()
  @IsIn(INTEREST_TABS)
  tab?: (typeof INTEREST_TABS)[number];
}

// 03 관심·보류의 카드 한 장. 내가 관심을 보냈거나 보류한 것만 나온다. 넘긴 것은 어디에도 나오지 않는다.
export class InterestCardModel {
  @ApiProperty({
    enum: SwipeTargetKind,
    enumName: 'SwipeTargetKind',
    description: '브랜드는 CREATOR, 크리에이터는 CAMPAIGN.',
  })
  targetKind!: SwipeTargetKind;

  @ApiProperty({ format: 'uuid' })
  targetId!: string;

  @ApiProperty({ description: '크리에이터의 활동 이름 또는 브랜드 이름.' })
  name!: string;

  @ApiProperty({
    description: '"{X}의 …" 꼴이면 X, 아니면 이름 전체. 04의 버튼에 쓴다.',
  })
  shortName!: string;

  @ApiProperty({
    type: String,
    nullable: true,
    description: '크리에이터 카드의 한 줄 또는 캠페인 한 줄.',
  })
  headline!: string | null;

  @ApiProperty({ type: String, nullable: true })
  photoUrl!: string | null;

  @ApiProperty({ enum: INTEREST_STATES, enumName: 'InterestState' })
  state!: (typeof INTEREST_STATES)[number];

  @ApiProperty({
    type: 'integer',
    nullable: true,
    description:
      '카드 아래 글의 금액. 서로 관심이면 최신 판본의 제작비, 아니면 브랜드는 내가 만든 제안의 금액(없으면 null이고 앱이 feeBand를 보여 준다), 크리에이터는 캠페인의 제작비.',
  })
  feeLabel!: number | null;

  @ApiProperty({
    enum: FeeBand,
    enumName: 'FeeBand',
    nullable: true,
    description:
      '브랜드가 볼 때 그 크리에이터의 희망 제작비 구간. 크리에이터가 볼 때는 null.',
  })
  feeBand!: FeeBand | null;

  @ApiProperty({
    type: String,
    format: 'date',
    nullable: true,
    description:
      '서로 관심일 때만 최신 판본의 제작 시작. 아니면 null(일정 협의).',
  })
  startFrom!: string | null;

  @ApiProperty({
    description:
      '내가 보낸 하트에 제안(제작비, 혜택, 성과 추가)이 붙어 있다. 브랜드만 true일 수 있다.',
  })
  hasProposal!: boolean;

  @ApiProperty({
    type: String,
    format: 'uuid',
    nullable: true,
    description: '서로 관심이면 그 협업의 id.',
  })
  collaborationId!: string | null;
}

export class ProposalPerformanceModel {
  @ApiProperty({ type: 'integer', description: '조회수 단가(1,000회당 원).' })
  ratePer1000!: number;

  @ApiProperty({ type: 'integer', description: '조회수 수당 상한(원).' })
  cap!: number;
}

// 크리에이터가 받은 제안: 나에게 온 글 또는 조건 제안이 붙은 관심 가운데 내가 아직 결정하지 않은 것.
// 캠페인의 예산은 담지 않는다.
export class ProposalModel {
  @ApiProperty({ format: 'uuid' })
  campaignId!: string;

  @ApiProperty()
  brandName!: string;

  @ApiProperty({ type: String, nullable: true })
  brandPhotoUrl!: string | null;

  @ApiProperty({
    type: String,
    nullable: true,
    description: '브랜드가 붙인 글(좋아한 점). 조건 제안만 붙었으면 null.',
  })
  note!: string | null;

  @ApiProperty({ type: String, nullable: true })
  contentTitle!: string | null;

  @ApiProperty({ type: String, nullable: true })
  contentPhotoUrl!: string | null;

  @ApiProperty({
    type: 'integer',
    description: '제안이 붙어 있으면 제안의 제작비, 없으면 캠페인의 제작비.',
  })
  fee!: number;

  @ApiProperty({
    description: '제안이 붙어 있으면 제안의 값, 없으면 캠페인의 값.',
  })
  productProvided!: boolean;

  @ApiProperty({
    type: ProposalPerformanceModel,
    nullable: true,
    description: '제안에 붙은 성과 추가. 없으면 null.',
  })
  performance!: ProposalPerformanceModel | null;

  @ApiProperty({ enum: ContentFormat, enumName: 'ContentFormat' })
  format!: ContentFormat;
}
