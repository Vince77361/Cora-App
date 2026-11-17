import { ApiProperty } from '@nestjs/swagger';
import { BrandUsageRights, ContentFormat, RevisionScope } from '@prisma/client';
import { Transform, Type } from 'class-transformer';
import {
  IsBoolean,
  IsEnum,
  IsISO8601,
  IsInt,
  IsObject,
  IsOptional,
  IsString,
  Matches,
  Max,
  MaxLength,
  Min,
  MinLength,
  ValidateNested,
} from 'class-validator';
import { CAMPAIGN_RULES } from '../../campaigns/campaign-rules';

// 성과 추가(조회수 수당). 범위는 서버 설정과 같고 서비스가 한 곳에서 검사한다.
export class RewardPerformanceDto {
  @ApiProperty({
    type: 'integer',
    description: '조회수 단가(1,000회당 원). 500원 단위.',
  })
  @IsInt()
  ratePer1000!: number;

  @ApiProperty({ type: 'integer', description: '조회수 수당 상한(원).' })
  @IsInt()
  cap!: number;
}

const trim = ({ value }: { value: unknown }): unknown =>
  typeof value === 'string' ? value.trim() : value;

// 협업 중에 새 판본을 낸다. 돈과 혜택만 바꾸는 길(F2)과 모든 항목을 바꾸는 수정 제안 화면이 이 한 본문을 쓴다.
// baseVersion만 필수이고 나머지는 빠지면 직전 판본 그대로다(성과 추가만 null이 "끔"이다).
export class ProposeRewardDto {
  @ApiProperty({
    type: 'integer',
    minimum: 1,
    description:
      '내가 보고 있던 판본 번호. 최신이 아니면 409 STALE_VERSION이다.',
  })
  @IsInt()
  @Min(1)
  baseVersion!: number;

  @ApiProperty({
    required: false,
    minLength: 1,
    maxLength: CAMPAIGN_RULES.headlineMax,
    description: '콘텐츠 제목(1~40자). 빠지면 그대로.',
  })
  @IsOptional()
  @Transform(trim)
  @IsString()
  @MinLength(1)
  @MaxLength(CAMPAIGN_RULES.headlineMax)
  title?: string;

  @ApiProperty({
    type: 'integer',
    required: false,
    description: '제작비(원). 1만 원 단위, 10000~10000000. 빠지면 그대로.',
  })
  @IsOptional()
  @IsInt()
  fee?: number;

  @ApiProperty({
    type: RewardPerformanceDto,
    nullable: true,
    required: false,
    description:
      '성과 추가. 빠지면 그대로, null이면 끈다. 블로그 글에는 붙일 수 없다.',
  })
  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => RewardPerformanceDto)
  performance?: RewardPerformanceDto | null;

  @ApiProperty({
    type: String,
    format: 'date',
    required: false,
    example: '2026-11-20',
    description: '제작 시작(YYYY-MM-DD). 바꾸는 값은 한국 시간 오늘 이후.',
  })
  @IsOptional()
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  @IsISO8601({ strict: true })
  startDate?: string;

  @ApiProperty({
    enum: ContentFormat,
    enumName: 'ContentFormat',
    required: false,
  })
  @IsOptional()
  @IsEnum(ContentFormat)
  format?: ContentFormat;

  @ApiProperty({ type: 'integer', required: false, minimum: 1, maximum: 3 })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(3)
  pieces?: number;

  @ApiProperty({
    required: false,
    description: '제품 제공 여부. 빠지면 그대로.',
  })
  @IsOptional()
  @IsBoolean()
  productProvided?: boolean;

  @ApiProperty({
    enum: RevisionScope,
    enumName: 'RevisionScope',
    required: false,
  })
  @IsOptional()
  @IsEnum(RevisionScope)
  revisionScope?: RevisionScope;

  @ApiProperty({
    enum: BrandUsageRights,
    enumName: 'BrandUsageRights',
    required: false,
  })
  @IsOptional()
  @IsEnum(BrandUsageRights)
  usageRights?: BrandUsageRights;

  @ApiProperty({
    type: 'integer',
    required: false,
    description: '게시 뒤 지급까지 걸리는 날(7 또는 14).',
  })
  @IsOptional()
  @IsInt()
  payoutDays?: number;
}
