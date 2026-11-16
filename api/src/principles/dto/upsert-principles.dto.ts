import { ApiProperty } from '@nestjs/swagger';
import { FeeBand, IndustryCategory, ProductTrialDays } from '@prisma/client';
import {
  ArrayMinSize,
  ArrayUnique,
  IsArray,
  IsBoolean,
  IsEnum,
  IsIn,
} from 'class-validator';
import {
  GENERAL_INDUSTRIES,
  SENSITIVE_INDUSTRIES,
} from '../../common/industry';

// 전체 교체 요청이다. 받고 싶은 분야에는 일반 업종만, 피하는 업종에는 민감 업종만 들어간다.
export class UpsertPrinciplesDto {
  // 일반 업종 아홉 개 중 1개 이상, 같은 값을 두 번 보내면 400. 문서 설명은 enum에 번지지 않게 주석으로만 둔다.
  @ApiProperty({
    enum: IndustryCategory,
    enumName: 'IndustryCategory',
    isArray: true,
    minItems: 1,
  })
  @IsArray()
  @ArrayMinSize(1)
  @ArrayUnique()
  @IsIn(GENERAL_INDUSTRIES, { each: true })
  fields!: IndustryCategory[];

  // 민감 업종(주류, 도박·사행성, 대출·금융, 다이어트 보조제) 중 0개 이상.
  @ApiProperty({
    enum: IndustryCategory,
    enumName: 'IndustryCategory',
    isArray: true,
  })
  @IsArray()
  @ArrayUnique()
  @IsIn(SENSITIVE_INDUSTRIES, { each: true })
  blockedIndustries!: IndustryCategory[];

  @ApiProperty()
  @IsBoolean()
  faceOk!: boolean;

  @ApiProperty()
  @IsBoolean()
  scriptOk!: boolean;

  @ApiProperty()
  @IsBoolean()
  honestReview!: boolean;

  @ApiProperty({ enum: FeeBand, enumName: 'FeeBand' })
  @IsEnum(FeeBand)
  feeBand!: FeeBand;

  @ApiProperty({ enum: ProductTrialDays, enumName: 'ProductTrialDays' })
  @IsEnum(ProductTrialDays)
  trialDays!: ProductTrialDays;
}
