import { ApiProperty } from '@nestjs/swagger';
import {
  CampaignStatus,
  ContentFormat,
  NotRequired,
  ProductTrialDays,
} from '@prisma/client';
import { CAMPAIGN_RULES } from '../campaign-rules';

export class CampaignModel {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ enum: CampaignStatus, enumName: 'CampaignStatus' })
  status!: CampaignStatus;

  @ApiProperty({ minLength: 1, maxLength: CAMPAIGN_RULES.headlineMax })
  headline!: string;

  @ApiProperty({
    type: 'integer',
    description: '크리에이터 한 명에게 주는 현금 고정비의 기본값(원).',
  })
  fee!: number;

  @ApiProperty({
    type: 'integer',
    description:
      '이 캠페인에 쓰려는 현금의 합(원). 브랜드만 보는 값이라 크리에이터가 받는 응답에는 넣지 않는다.',
  })
  budget!: number;

  @ApiProperty()
  productProvided!: boolean;

  @ApiProperty({ enum: ContentFormat, enumName: 'ContentFormat' })
  format!: ContentFormat;

  @ApiProperty({ type: String, format: 'date', example: '2026-11-20' })
  startFrom!: string;

  @ApiProperty({ enum: ProductTrialDays, enumName: 'ProductTrialDays' })
  trialDays!: ProductTrialDays;

  @ApiProperty({
    type: [String],
    maxItems: CAMPAIGN_RULES.mustIncludeMax,
    description: '꼭 담을 것. 줄마다 20자까지.',
  })
  mustInclude!: string[];

  @ApiProperty({
    enum: NotRequired,
    enumName: 'NotRequired',
    isArray: true,
    description: '요구하지 않는 것.',
  })
  notRequired!: NotRequired[];
}
