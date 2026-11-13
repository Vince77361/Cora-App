import { ApiProperty } from '@nestjs/swagger';
import { ContentFormat } from '@prisma/client';
import { PROPOSAL_POLICY } from '../../common/collaboration-policy';

// 크리에이터가 만들어 둔 시리즈. 제안을 낼 때 고르면 이름·형식·설명이 판본에 사본으로 들어간다.
export class CreatorSeriesModel {
  @ApiProperty({ format: 'uuid' })
  id!: string;

  @ApiProperty({ maxLength: PROPOSAL_POLICY.seriesNameMax })
  name!: string;

  @ApiProperty({ enum: ContentFormat, enumName: 'ContentFormat' })
  format!: ContentFormat;

  @ApiProperty({
    type: String,
    nullable: true,
    maxLength: PROPOSAL_POLICY.seriesNoteMax,
  })
  note!: string | null;
}
