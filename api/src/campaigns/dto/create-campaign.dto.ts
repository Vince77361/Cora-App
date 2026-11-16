import { ApiProperty } from '@nestjs/swagger';
import { ContentFormat, NotRequired, ProductTrialDays } from '@prisma/client';
import { Transform } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayUnique,
  IsArray,
  IsBoolean,
  IsDivisibleBy,
  IsEnum,
  IsInt,
  IsISO8601,
  IsString,
  Matches,
  Max,
  MaxLength,
  Min,
  MinLength,
} from 'class-validator';
import { CAMPAIGN_RULES } from '../campaign-rules';

const trim = ({ value }: { value: unknown }): unknown =>
  typeof value === 'string' ? value.trim() : value;

const trimEach = ({ value }: { value: unknown }): unknown =>
  Array.isArray(value)
    ? value.map((item: unknown) =>
        typeof item === 'string' ? item.trim() : item,
      )
    : value;

// 금액은 모양과 범위만 여기서 본다. 예산이 제작비 이상인지는 두 값이 함께 필요해 서비스가 본다.
export class CreateCampaignDto {
  @ApiProperty({ minLength: 1, maxLength: CAMPAIGN_RULES.headlineMax })
  @Transform(trim)
  @IsString()
  @MinLength(1)
  @MaxLength(CAMPAIGN_RULES.headlineMax)
  headline!: string;

  @ApiProperty({
    type: 'integer',
    minimum: CAMPAIGN_RULES.feeMin,
    maximum: CAMPAIGN_RULES.feeMax,
    multipleOf: CAMPAIGN_RULES.moneyStep,
    description: '제작비(원). 1만 원 단위.',
  })
  @IsInt()
  @Min(CAMPAIGN_RULES.feeMin)
  @Max(CAMPAIGN_RULES.feeMax)
  @IsDivisibleBy(CAMPAIGN_RULES.moneyStep)
  fee!: number;

  @ApiProperty({
    type: 'integer',
    minimum: CAMPAIGN_RULES.feeMin,
    maximum: CAMPAIGN_RULES.budgetMax,
    multipleOf: CAMPAIGN_RULES.moneyStep,
    description: '캠페인 예산(원). 1만 원 단위, 제작비 이상.',
  })
  @IsInt()
  @Min(CAMPAIGN_RULES.feeMin)
  @Max(CAMPAIGN_RULES.budgetMax)
  @IsDivisibleBy(CAMPAIGN_RULES.moneyStep)
  budget!: number;

  @ApiProperty()
  @IsBoolean()
  productProvided!: boolean;

  @ApiProperty({ enum: ContentFormat, enumName: 'ContentFormat' })
  @IsEnum(ContentFormat)
  format!: ContentFormat;

  @ApiProperty({
    type: String,
    format: 'date',
    example: '2026-11-20',
    description: '시작 가능한 날(YYYY-MM-DD). 한국 시간 오늘 이후.',
  })
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  @IsISO8601({ strict: true })
  startFrom!: string;

  @ApiProperty({ enum: ProductTrialDays, enumName: 'ProductTrialDays' })
  @IsEnum(ProductTrialDays)
  trialDays!: ProductTrialDays;

  @ApiProperty({
    type: [String],
    maxItems: CAMPAIGN_RULES.mustIncludeMax,
    description: '꼭 담을 것. 최대 3줄, 줄마다 1~20자.',
  })
  @Transform(trimEach)
  @IsArray()
  @ArrayMaxSize(CAMPAIGN_RULES.mustIncludeMax)
  @IsString({ each: true })
  @MinLength(1, { each: true })
  @MaxLength(CAMPAIGN_RULES.mustIncludeLength, { each: true })
  mustInclude!: string[];

  @ApiProperty({
    enum: NotRequired,
    enumName: 'NotRequired',
    isArray: true,
    description: '요구하지 않는 것.',
  })
  @IsArray()
  @ArrayUnique()
  @IsEnum(NotRequired, { each: true })
  notRequired!: NotRequired[];
}
