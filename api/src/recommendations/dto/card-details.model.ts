import { ApiProperty } from '@nestjs/swagger';
import { NotRequired, ProductTrialDays } from '@prisma/client';
import {
  CampaignCardModel,
  CreatorCardModel,
} from './recommendation-cards.model';

export const SAVED_DECISIONS = ['LIKE', 'HOLD'] as const;
export type SavedDecision = (typeof SAVED_DECISIONS)[number];

const MY_DECISION = {
  enum: SAVED_DECISIONS,
  enumName: 'SavedDecision',
  nullable: true,
  description:
    '내가 저장한 결정(하트 또는 저장). 결정하지 않았으면 null. 넘긴 카드는 상세가 404라서 PASS는 나오지 않는다.',
} as const;

// 브랜드가 카드를 눌러 읽는 크리에이터 상세: 카드 + 내 결정.
export class CreatorCardDetailModel extends CreatorCardModel {
  @ApiProperty(MY_DECISION)
  myDecision!: SavedDecision | null;
}

// D1 캠페인 상세: 카드 + 일정, 제품 사용 기간, 꼭 담을 것, 요구하지 않는 것, 겹치는 규칙의 수, 내 결정.
// 캠페인의 예산은 담지 않는다.
export class CampaignDetailModel extends CampaignCardModel {
  @ApiProperty({ type: String, format: 'date', description: '시작 가능한 날.' })
  startFrom!: string;

  @ApiProperty({ enum: ProductTrialDays, enumName: 'ProductTrialDays' })
  trialDays!: ProductTrialDays;

  @ApiProperty({ type: [String], description: '꼭 담을 것.' })
  mustInclude!: string[];

  @ApiProperty({
    enum: NotRequired,
    enumName: 'NotRequired',
    isArray: true,
    description: '요구하지 않는 것.',
  })
  notRequired!: NotRequired[];

  @ApiProperty({
    type: 'integer',
    description: '"내 협업 원칙과 N개가 겹쳐요"의 N(reasons의 개수).',
  })
  overlapCount!: number;

  @ApiProperty(MY_DECISION)
  myDecision!: SavedDecision | null;
}
