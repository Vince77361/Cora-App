import { ApiProperty } from '@nestjs/swagger';
import { FeeBand } from '@prisma/client';
import { StoreSummaryModel } from '../../stores/dto/store-public.model';
import type { MatchReason } from '../match-score';

export const MATCH_REASONS = [
  'FIELD',
  'FACE',
  'SCRIPT',
  'FEE',
  'TRIAL',
] as const;

// 카드를 눌러 상세를 읽는 5번 계획의 응답도 같은 이유 목록을 쓴다.
const REASONS_PROPERTY = {
  enum: MATCH_REASONS,
  enumName: 'MatchReason',
  isArray: true,
  description: '크리에이터의 협업 원칙과 겹치는 규칙. 많을수록 잘 맞는다.',
} as const;

// 브랜드가 넘겨 보는 크리에이터 카드.
export class CreatorCardModel {
  @ApiProperty({ format: 'uuid' })
  creatorId!: string;

  @ApiProperty()
  displayName!: string;

  @ApiProperty({ type: String, nullable: true })
  instagramHandle!: string | null;

  @ApiProperty({ type: String, nullable: true, maxLength: 40 })
  headline!: string | null;

  @ApiProperty({ type: String, nullable: true })
  photoUrl!: string | null;

  @ApiProperty({ enum: FeeBand, enumName: 'FeeBand' })
  feeBand!: FeeBand;

  @ApiProperty({ type: [String] })
  tags!: string[];

  @ApiProperty(REASONS_PROPERTY)
  reasons!: MatchReason[];

  @ApiProperty({
    description:
      '항상 false. 상대가 먼저 관심을 보냈는지는 미리 알려 주지 않고, 순서에만 쓴다.',
  })
  theyLikedMe!: boolean;
}

// 크리에이터가 넘겨 보는 브랜드 캠페인 카드. 캠페인의 예산은 담지 않는다.
export class CampaignCardModel {
  @ApiProperty({ enum: ['CAMPAIGN'] })
  kind!: 'CAMPAIGN';

  @ApiProperty({ format: 'uuid' })
  campaignId!: string;

  @ApiProperty()
  brandName!: string;

  @ApiProperty({ type: String, nullable: true })
  brandTagline!: string | null;

  @ApiProperty({ type: String, nullable: true })
  photoUrl!: string | null;

  @ApiProperty()
  headline!: string;

  @ApiProperty({ type: 'integer' })
  fee!: number;

  @ApiProperty()
  productProvided!: boolean;

  @ApiProperty({ type: [String], maxItems: 2 })
  tags!: string[];

  @ApiProperty(REASONS_PROPERTY)
  reasons!: MatchReason[];
}

// 크리에이터가 넘겨 보는 가게 카드.
export class StoreCardModel {
  @ApiProperty({ enum: ['STORE'] })
  kind!: 'STORE';

  @ApiProperty({ type: StoreSummaryModel })
  store!: StoreSummaryModel;

  @ApiProperty({ maxLength: 40, description: '가게 소개의 첫 문장.' })
  headline!: string;

  @ApiProperty({ type: [String] })
  tags!: string[];

  @ApiProperty({
    type: String,
    nullable: true,
    description: '내 활동 지역과 시·도가 다르면 가게의 시·도, 같으면 null.',
  })
  otherSido!: string | null;

  @ApiProperty({
    description:
      '보상 세 요소를 " + "로 이은 짧은 글. 예: 식사권 + 조회수 수당',
  })
  rewardLine!: string;
}

// 크리에이터의 오늘 목록에 한 줄로 섞여 나오는 카드의 문서 모양. 응답은 kind가 CAMPAIGN이면 CampaignCardModel,
// STORE이면 StoreCardModel과 같은 값이다. oneOf로 적으면 Dart 생성기가 두 모양을 필수 칸으로 합쳐 읽다가 깨지므로,
// 칸을 모두 선택으로 합친 하나의 모양으로 적는다. 앱은 kind를 보고 그 종류의 칸만 읽는다.
export class CampaignListCardModel {
  @ApiProperty({
    enum: ['CAMPAIGN', 'STORE'],
    enumName: 'CampaignListCardKind',
  })
  kind!: 'CAMPAIGN' | 'STORE';

  @ApiProperty({
    description: '캠페인이면 캠페인 한 줄, 가게면 소개의 첫 문장.',
  })
  headline!: string;

  @ApiProperty({ type: [String] })
  tags!: string[];

  @ApiProperty({ format: 'uuid', required: false, description: 'CAMPAIGN만.' })
  campaignId?: string;

  @ApiProperty({ required: false, description: 'CAMPAIGN만.' })
  brandName?: string;

  @ApiProperty({
    type: String,
    nullable: true,
    required: false,
    description: 'CAMPAIGN만.',
  })
  brandTagline?: string | null;

  @ApiProperty({
    type: String,
    nullable: true,
    required: false,
    description: 'CAMPAIGN만.',
  })
  photoUrl?: string | null;

  @ApiProperty({ type: 'integer', required: false, description: 'CAMPAIGN만.' })
  fee?: number;

  @ApiProperty({ required: false, description: 'CAMPAIGN만.' })
  productProvided?: boolean;

  @ApiProperty({
    ...REASONS_PROPERTY,
    required: false,
    description: 'CAMPAIGN만. 크리에이터의 협업 원칙과 겹치는 규칙.',
  })
  reasons?: MatchReason[];

  @ApiProperty({
    type: StoreSummaryModel,
    required: false,
    description: 'STORE만.',
  })
  store?: StoreSummaryModel;

  @ApiProperty({
    type: String,
    nullable: true,
    required: false,
    description: 'STORE만. 내 활동 지역과 시·도가 다르면 가게의 시·도.',
  })
  otherSido?: string | null;

  @ApiProperty({
    required: false,
    description: 'STORE만. 보상 세 요소를 " + "로 이은 짧은 글.',
  })
  rewardLine?: string;
}

// 역할이 없는 사용자에게 보여 주는 읽기 전용 크리에이터 카드. 인스타그램 아이디와 잘 맞는 이유는 없다.
export class PreviewCardModel {
  @ApiProperty({ format: 'uuid' })
  creatorId!: string;

  @ApiProperty()
  displayName!: string;

  @ApiProperty({ type: String, nullable: true, maxLength: 40 })
  headline!: string | null;

  @ApiProperty({ type: String, nullable: true })
  photoUrl!: string | null;

  @ApiProperty({ enum: FeeBand, enumName: 'FeeBand' })
  feeBand!: FeeBand;

  @ApiProperty({ type: [String] })
  tags!: string[];
}
