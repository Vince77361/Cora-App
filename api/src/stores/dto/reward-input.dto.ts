import { ApiProperty } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import {
  IsInt,
  IsObject,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
  ValidateNested,
} from 'class-validator';

const trim = ({ value }: { value: unknown }): unknown =>
  typeof value === 'string' ? value.trim() : value;

// 범위와 단위는 reward-terms.ts(buildReward)가 한 곳에서 검사한다. 여기서는 모양만 본다.
export class VoucherInputDto {
  @ApiProperty({
    required: false,
    minLength: 1,
    maxLength: 20,
    description: '식사권 이름. 없으면 "식사권".',
  })
  @IsOptional()
  @Transform(trim)
  @IsString()
  @MinLength(1)
  @MaxLength(20)
  name?: string;

  @ApiProperty({
    required: false,
    type: 'integer',
    description: '식사권 금액(원). 없으면 가게의 기본값, 그것도 없으면 40000.',
  })
  @IsOptional()
  @IsInt()
  value?: number;

  @ApiProperty({
    required: false,
    type: 'integer',
    description: '식사권 인원. 없으면 가게의 기본값, 그것도 없으면 2.',
  })
  @IsOptional()
  @IsInt()
  people?: number;
}

export class PerViewInputDto {
  @ApiProperty({
    required: false,
    type: 'integer',
    description:
      '조회수 단가(1,000회당 원). 없으면 가게의 모집 조건, 그것도 없으면 2000.',
  })
  @IsOptional()
  @IsInt()
  ratePerThousand?: number;

  @ApiProperty({
    required: false,
    type: 'integer',
    description:
      '조회수 수당 상한(원). 없으면 가게의 모집 조건, 그것도 없으면 60000.',
  })
  @IsOptional()
  @IsInt()
  cap?: number;
}

// 보상의 세 요소 입력. voucher나 perView를 주면(빈 객체도) 그 요소가 켜진다. null이나 생략은 없음이다.
export class RewardInputDto {
  @ApiProperty({ required: false, type: VoucherInputDto, nullable: true })
  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => VoucherInputDto)
  voucher?: VoucherInputDto | null;

  @ApiProperty({
    required: false,
    type: 'integer',
    description: '고정 현금(원). 없으면 0.',
  })
  @IsOptional()
  @IsInt()
  fixedCash?: number;

  @ApiProperty({ required: false, type: PerViewInputDto, nullable: true })
  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => PerViewInputDto)
  perView?: PerViewInputDto | null;
}
