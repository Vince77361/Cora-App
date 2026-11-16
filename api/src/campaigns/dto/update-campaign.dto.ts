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
  ValidateIf,
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

// 빠진(undefined) 항목만 건너뛴다. IsOptional은 null도 건너뛰어 서비스까지 null이 가므로 쓰지 않는다.
const Optional = () => ValidateIf((_object, value) => value !== undefined);

// 일부만 고치는 요청이다. 빠진 항목은 그대로 두고, 보낸 항목은 만들 때와 같은 규칙을 지킨다.
export class UpdateCampaignDto {
  @ApiProperty({
    required: false,
    minLength: 1,
    maxLength: CAMPAIGN_RULES.headlineMax,
  })
  @Optional()
  @Transform(trim)
  @IsString()
  @MinLength(1)
  @MaxLength(CAMPAIGN_RULES.headlineMax)
  headline?: string;

  @ApiProperty({
    required: false,
    type: 'integer',
    minimum: CAMPAIGN_RULES.feeMin,
    maximum: CAMPAIGN_RULES.feeMax,
    multipleOf: CAMPAIGN_RULES.moneyStep,
  })
  @Optional()
  @IsInt()
  @Min(CAMPAIGN_RULES.feeMin)
  @Max(CAMPAIGN_RULES.feeMax)
  @IsDivisibleBy(CAMPAIGN_RULES.moneyStep)
  fee?: number;

  @ApiProperty({
    required: false,
    type: 'integer',
    minimum: CAMPAIGN_RULES.feeMin,
    maximum: CAMPAIGN_RULES.budgetMax,
    multipleOf: CAMPAIGN_RULES.moneyStep,
    description: '고친 뒤에도 제작비 이상이어야 한다.',
  })
  @Optional()
  @IsInt()
  @Min(CAMPAIGN_RULES.feeMin)
  @Max(CAMPAIGN_RULES.budgetMax)
  @IsDivisibleBy(CAMPAIGN_RULES.moneyStep)
  budget?: number;

  @ApiProperty({ required: false })
  @Optional()
  @IsBoolean()
  productProvided?: boolean;

  @ApiProperty({
    required: false,
    enum: ContentFormat,
    enumName: 'ContentFormat',
  })
  @Optional()
  @IsEnum(ContentFormat)
  format?: ContentFormat;

  @ApiProperty({
    required: false,
    type: String,
    format: 'date',
    description:
      '바꿀 때만 한국 시간 오늘 이후여야 한다. 그대로 보내면 통과한다.',
  })
  @Optional()
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  @IsISO8601({ strict: true })
  startFrom?: string;

  @ApiProperty({
    required: false,
    enum: ProductTrialDays,
    enumName: 'ProductTrialDays',
  })
  @Optional()
  @IsEnum(ProductTrialDays)
  trialDays?: ProductTrialDays;

  @ApiProperty({
    required: false,
    type: [String],
    maxItems: CAMPAIGN_RULES.mustIncludeMax,
  })
  @Optional()
  @Transform(trimEach)
  @IsArray()
  @ArrayMaxSize(CAMPAIGN_RULES.mustIncludeMax)
  @IsString({ each: true })
  @MinLength(1, { each: true })
  @MaxLength(CAMPAIGN_RULES.mustIncludeLength, { each: true })
  mustInclude?: string[];

  @ApiProperty({
    required: false,
    enum: NotRequired,
    enumName: 'NotRequired',
    isArray: true,
  })
  @Optional()
  @IsArray()
  @ArrayUnique()
  @IsEnum(NotRequired, { each: true })
  notRequired?: NotRequired[];
}
