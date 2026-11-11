import { ApiProperty } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import {
  IsIn,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';
import { SIDO_LIST } from '../../common/regions';
import type { Sido } from '../../common/regions';

// 길이는 앞뒤 공백을 자른 뒤에 잰다. 문자열이 아니면 그대로 둬서 IsString이 거절하게 한다.
const trim = ({ value }: { value: unknown }): unknown =>
  typeof value === 'string' ? value.trim() : value;

// 인스타그램 아이디는 앞의 @ 하나만 떼고 검증한다. @@ 같은 입력은 정규식이 거절한다.
const stripAt = ({ value }: { value: unknown }): unknown => {
  const text = trim({ value });
  return typeof text === 'string' && text.startsWith('@')
    ? text.slice(1)
    : text;
};

// 전체 교체 요청이다. 빠진 선택 항목과 빈 문자열은 서버가 null로 저장한다.
export class UpsertCreatorProfileDto {
  @ApiProperty({ minLength: 1, maxLength: 20 })
  @Transform(trim)
  @IsString()
  @MinLength(1)
  @MaxLength(20)
  displayName!: string;

  @ApiProperty({ required: false, maxLength: 30 })
  @IsOptional()
  @Transform(trim)
  @IsString()
  @MaxLength(30)
  contentFocus?: string;

  @ApiProperty({
    required: false,
    maxLength: 30,
    description: '영문, 숫자, 점, 밑줄. 앞의 @ 하나는 떼고 저장한다.',
  })
  @IsOptional()
  @Transform(stripAt)
  @IsString()
  @Matches(/^([A-Za-z0-9._]{1,30})?$/, {
    message: '인스타그램 아이디는 영문, 숫자, 점, 밑줄만 쓸 수 있어요.',
  })
  instagramHandle?: string;

  // POST /uploads/photos(CREATOR_PHOTO)가 준 경로. 서버가 소유자를 다시 확인한다.
  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  photoPath?: string;

  // 한글 값이라 enum으로 노출하면 Dart 생성기가 열거형 이름을 만들지 못한다. 문자열로 두고 서버가 검증한다.
  @ApiProperty({ description: '시·도 고정 목록(SIDO_LIST) 중 하나.' })
  @IsIn(SIDO_LIST)
  regionSido!: Sido;

  @ApiProperty({ required: false, maxLength: 20 })
  @IsOptional()
  @Transform(trim)
  @IsString()
  @MaxLength(20)
  regionSigungu?: string;
}
