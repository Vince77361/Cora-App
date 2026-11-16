import { ApiProperty } from '@nestjs/swagger';
import { IndustryCategory } from '@prisma/client';
import { Transform } from 'class-transformer';
import {
  IsIn,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';
import {
  GENERAL_INDUSTRIES,
  SENSITIVE_INDUSTRIES,
} from '../../common/industry';

const trim = ({ value }: { value: unknown }): unknown =>
  typeof value === 'string' ? value.trim() : value;

// 브랜드는 주류·대출 같은 민감 업종일 수도 있어서 열세 개 업종을 모두 고를 수 있다.
// (크리에이터가 피하는 업종과 걸러지는 것은 공통 필터가 한다.)
const BRAND_INDUSTRIES = [...GENERAL_INDUSTRIES, ...SENSITIVE_INDUSTRIES];

// 전체 교체 요청이다. 빠진 선택 항목과 빈 문자열은 서버가 null로 저장한다.
export class UpsertBrandProfileDto {
  @ApiProperty({ minLength: 1, maxLength: 30 })
  @Transform(trim)
  @IsString()
  @MinLength(1)
  @MaxLength(30)
  name!: string;

  @ApiProperty({ required: false, maxLength: 40 })
  @IsOptional()
  @Transform(trim)
  @IsString()
  @MaxLength(40)
  tagline?: string;

  @ApiProperty({ enum: IndustryCategory, enumName: 'IndustryCategory' })
  @IsIn(BRAND_INDUSTRIES)
  industry!: IndustryCategory;

  // POST /uploads/photos(BRAND_PHOTO)가 준 경로. 서버가 소유자를 다시 확인한다.
  @ApiProperty({
    required: false,
    description:
      '대표 사진 경로. 이 요청은 전체 교체라서 비우거나 빠뜨리면 지운다.',
  })
  @IsOptional()
  @IsString()
  photoPath?: string;
}
