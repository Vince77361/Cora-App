import { ApiProperty } from '@nestjs/swagger';
import { ContentFormat, RewardType } from '@prisma/client';
import { Transform } from 'class-transformer';
import {
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  Min,
  MinLength,
} from 'class-validator';

const trim = ({ value }: { value: unknown }): unknown =>
  typeof value === 'string' ? value.trim() : value;

// 조회 단가와 상한은 받지 않는다. 서버가 정한 값을 쓴다. 가게 정보는 내 가게를 서버가 찾는다.
export class SendOfferDto {
  @ApiProperty({ format: 'uuid', description: '오퍼를 받을 크리에이터의 ID.' })
  @IsUUID()
  creatorId!: string;

  @ApiProperty({ enum: ContentFormat, enumName: 'ContentFormat' })
  @IsEnum(ContentFormat)
  format!: ContentFormat;

  @ApiProperty({ enum: RewardType, enumName: 'RewardType' })
  @IsEnum(RewardType)
  rewardType!: RewardType;

  @ApiProperty({
    required: false,
    minLength: 1,
    maxLength: 20,
    description: '식사권이 보상에 들어갈 때만 쓴다. 없으면 "2인 식사권".',
  })
  @IsOptional()
  @Transform(trim)
  @IsString()
  @MinLength(1)
  @MaxLength(20)
  voucherName?: string;

  @ApiProperty({
    required: false,
    type: 'integer',
    minimum: 1000,
    maximum: 1000000,
    description: '식사권이 보상에 들어갈 때만 쓴다. 없으면 40000.',
  })
  @IsOptional()
  @IsInt()
  @Min(1000)
  @Max(1000000)
  voucherValue?: number;
}
