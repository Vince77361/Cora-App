import { ApiProperty } from '@nestjs/swagger';
import { IndustryCategory } from '@prisma/client';
import { Transform } from 'class-transformer';
import {
  IsEnum,
  IsIn,
  IsString,
  MaxLength,
  MinLength,
  ValidateIf,
} from 'class-validator';
import { SIDO_LIST } from '../../common/regions';
import type { Sido } from '../../common/regions';

const trim = ({ value }: { value: unknown }): unknown =>
  typeof value === 'string' ? value.trim() : value;

// 빠진(undefined) 항목만 건너뛴다. IsOptional은 null도 건너뛰어 서비스까지 null이 가므로 쓰지 않는다.
const Optional = () => ValidateIf((_object, value) => value !== undefined);

// 일부만 고치는 요청이다. 빠진 항목은 그대로 두고, 이름 말고는 빈 문자열을 보내면 지운다(null).
export class UpdateStoreDto {
  @ApiProperty({ required: false, minLength: 1, maxLength: 30 })
  @Optional()
  @Transform(trim)
  @IsString()
  @MinLength(1)
  @MaxLength(30)
  name?: string;

  @ApiProperty({
    required: false,
    maxLength: 50,
    description: '표시용 업종(예: 라멘집).',
  })
  @Optional()
  @Transform(trim)
  @IsString()
  @MaxLength(50)
  category?: string;

  @ApiProperty({
    required: false,
    enum: IndustryCategory,
    enumName: 'IndustryCategory',
    description: '업종 분류(공통 모델 3장).',
  })
  @Optional()
  @IsEnum(IndustryCategory)
  industry?: IndustryCategory;

  @ApiProperty({
    required: false,
    maxLength: 50,
    description: '표시용 동네(예: 성수동).',
  })
  @Optional()
  @Transform(trim)
  @IsString()
  @MaxLength(50)
  neighborhood?: string;

  // 한글 값이라 enum으로 노출하면 Dart 생성기가 열거형 이름을 만들지 못한다. 문자열로 두고 서버가 검증한다.
  @ApiProperty({
    required: false,
    description: '시·도 고정 목록(SIDO_LIST) 중 하나.',
  })
  @Optional()
  @IsIn(SIDO_LIST)
  regionSido?: Sido;

  @ApiProperty({ required: false, maxLength: 20 })
  @Optional()
  @Transform(trim)
  @IsString()
  @MaxLength(20)
  regionSigungu?: string;

  @ApiProperty({ required: false, maxLength: 50 })
  @Optional()
  @Transform(trim)
  @IsString()
  @MaxLength(50)
  signatureMenu?: string;

  @ApiProperty({ required: false, maxLength: 50 })
  @Optional()
  @Transform(trim)
  @IsString()
  @MaxLength(50)
  hours?: string;

  @ApiProperty({ required: false, maxLength: 50 })
  @Optional()
  @Transform(trim)
  @IsString()
  @MaxLength(50)
  seats?: string;

  @ApiProperty({ required: false, maxLength: 50 })
  @Optional()
  @Transform(trim)
  @IsString()
  @MaxLength(50)
  bestShootingTime?: string;

  @ApiProperty({ required: false, maxLength: 300 })
  @Optional()
  @Transform(trim)
  @IsString()
  @MaxLength(300)
  intro?: string;

  // POST /uploads/photos(STORE_COVER)가 준 경로. 서버가 소유자를 다시 확인한다.
  @ApiProperty({ required: false })
  @Optional()
  @IsString()
  coverPhotoPath?: string;
}
