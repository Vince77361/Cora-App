import { ApiProperty } from '@nestjs/swagger';
import {
  CampaignListCardModel,
  CreatorCardModel,
  PreviewCardModel,
} from './recommendation-cards.model';

export class CreatorRecommendationsModel {
  @ApiProperty({ type: String, format: 'date', example: '2026-11-11' })
  day!: string;

  @ApiProperty({
    type: 'integer',
    description: '오늘 목록의 전체 수(이미 결정한 카드 포함).',
  })
  total!: number;

  @ApiProperty({ type: [CreatorCardModel] })
  cards!: CreatorCardModel[];
}

export class CampaignRecommendationsModel {
  @ApiProperty({ type: String, format: 'date', example: '2026-11-11' })
  day!: string;

  @ApiProperty({
    type: 'integer',
    description: '오늘 목록의 전체 수(이미 결정한 카드 포함).',
  })
  total!: number;

  @ApiProperty({ type: [CampaignListCardModel] })
  cards!: CampaignListCardModel[];
}

export class PreviewCardsModel {
  @ApiProperty({ type: 'integer' })
  total!: number;

  @ApiProperty({ type: [PreviewCardModel] })
  cards!: PreviewCardModel[];
}
