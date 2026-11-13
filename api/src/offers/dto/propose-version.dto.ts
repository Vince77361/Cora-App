import { ApiProperty } from '@nestjs/swagger';
import { ContentFormat, UsageRights } from '@prisma/client';
import { Transform, Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsEnum,
  IsObject,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  MinLength,
  ValidateNested,
} from 'class-validator';
import { PROPOSAL_POLICY } from '../../common/collaboration-policy';
import { RewardInputDto } from '../../stores/dto/reward-input.dto';

const trim = ({ value }: { value: unknown }): unknown =>
  typeof value === 'string' ? value.trim() : value;

// 새 판본의 조건. 범위와 단위는 buildTerms가 한 곳에서 검사한다. 비운 값은 앞 판본의 값으로 채운다.
// idea와 principles는 크리에이터가 쓸 때만 저장한다(사장님이 보내면 무시한다).
export class ProposeVersionDto {
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
    description: '없으면 앞 판본의 사용권.',
  })
  @IsOptional()
  @IsEnum(UsageRights)
  usageRights?: UsageRights;

  @ApiProperty({
    required: false,
    format: 'uuid',
    description:
      '내 시리즈의 id. 이름·형식·설명이 판본에 사본으로 들어간다. 크리에이터만 쓴다.',
  })
  @IsOptional()
  @IsUUID()
  seriesId?: string;

  @ApiProperty({
    required: false,
    maxLength: PROPOSAL_POLICY.ideaMax,
    description: '내 방식의 한 줄 설명. 크리에이터만 쓴다.',
  })
  @IsOptional()
  @Transform(trim)
  @IsString()
  @MaxLength(PROPOSAL_POLICY.ideaMax)
  idea?: string;

  @ApiProperty({
    required: false,
    type: [String],
    description: `내가 지키는 원칙. 최대 ${PROPOSAL_POLICY.principlesMax}개, 각 ${PROPOSAL_POLICY.principleLength}자까지. 크리에이터만 쓴다.`,
  })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(PROPOSAL_POLICY.principlesMax)
  @Transform(({ value }: { value: unknown }) =>
    Array.isArray(value) ? value.map((v) => trim({ value: v })) : value,
  )
  @IsString({ each: true })
  @MinLength(1, { each: true })
  @MaxLength(PROPOSAL_POLICY.principleLength, { each: true })
  principles?: string[];
}
