import { ApiProperty } from '@nestjs/swagger';
import { ContentFormat, UsageRights } from '@prisma/client';
import { Type } from 'class-transformer';
import {
  IsEnum,
  IsObject,
  IsOptional,
  IsUUID,
  ValidateNested,
} from 'class-validator';
import { RewardInputDto } from '../../stores/dto/reward-input.dto';

// 조회수 단가와 상한을 비우면 가게의 모집 조건으로 채운다. 가게 정보는 내 가게를 서버가 찾는다.
export class SendOfferDto {
  @ApiProperty({ format: 'uuid', description: '오퍼를 받을 크리에이터의 ID.' })
  @IsUUID()
  creatorId!: string;

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
    description: '없으면 가게의 기본 사용권.',
  })
  @IsOptional()
  @IsEnum(UsageRights)
  usageRights?: UsageRights;
}
