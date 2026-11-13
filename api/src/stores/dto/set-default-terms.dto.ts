import { ApiProperty } from '@nestjs/swagger';
import { ContentFormat, UsageRights } from '@prisma/client';
import { Type } from 'class-transformer';
import { IsEnum, IsObject, IsOptional, ValidateNested } from 'class-validator';
import { RewardInputDto } from './reward-input.dto';

// 가게의 기본 오퍼 조건. 조회수 단가와 상한을 비우면 서버의 기본값(2000원, 60000원)을 채워 저장한다.
export class SetDefaultTermsDto {
  @ApiProperty({ enum: ContentFormat, enumName: 'ContentFormat' })
  @IsEnum(ContentFormat)
  format!: ContentFormat;

  @ApiProperty({ type: RewardInputDto })
  @IsObject()
  @ValidateNested()
  @Type(() => RewardInputDto)
  reward!: RewardInputDto;

  @ApiProperty({
    required: false,
    enum: UsageRights,
    enumName: 'UsageRights',
    description: '없으면 STORE_REPOST_3M.',
  })
  @IsOptional()
  @IsEnum(UsageRights)
  usageRights?: UsageRights;
}
