import { ApiProperty } from '@nestjs/swagger';
import { ContentFormat, RewardType } from '@prisma/client';

// 가게의 기본 조건과 오퍼 조건이 같은 모양을 쓴다. 보상에 들어가지 않는 항목은 null이다.
export class OfferTermsModel {
  @ApiProperty({ enum: ContentFormat, enumName: 'ContentFormat' })
  format!: ContentFormat;

  @ApiProperty({ enum: RewardType, enumName: 'RewardType' })
  rewardType!: RewardType;

  @ApiProperty({ type: String, nullable: true })
  voucherName!: string | null;

  @ApiProperty({ type: 'integer', nullable: true })
  voucherValue!: number | null;

  @ApiProperty({ type: 'integer', nullable: true })
  perViewAmount!: number | null;

  @ApiProperty({ type: 'integer', nullable: true })
  perViewCap!: number | null;
}
