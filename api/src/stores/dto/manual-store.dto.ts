import { ApiProperty } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import {
  IsIn,
  IsString,
  MaxLength,
  MinLength,
  ValidateIf,
  ValidateNested,
} from 'class-validator';
import { SIDO_LIST } from '../../common/regions';
import type { Sido } from '../../common/regions';

const trim = ({ value }: { value: unknown }): unknown =>
  typeof value === 'string' ? value.trim() : value;

// 빠진(undefined) 항목만 건너뛴다. IsOptional은 null도 건너뛰므로 쓰지 않는다.
const Optional = () => ValidateIf((_object, value) => value !== undefined);

// 골라 둔 지점. 동네와 시·도, 구·군은 findMyStoreBranches가 준 값을 그대로 보낸다.
export class ManualBranchDto {
  @ApiProperty({ minLength: 1, maxLength: 30 })
  @Transform(trim)
  @IsString()
  @MinLength(1)
  @MaxLength(30)
  label!: string;

  @ApiProperty({ required: false, maxLength: 50 })
  @Optional()
  @Transform(trim)
  @IsString()
  @MaxLength(50)
  neighborhood?: string;

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
}

// 링크 없이 가게 정보를 직접 넣는다(F7).
export class ManualStoreDto {
  @ApiProperty({ minLength: 1, maxLength: 30 })
  @Transform(trim)
  @IsString()
  @MinLength(1)
  @MaxLength(30)
  name!: string;

  @ApiProperty({ required: false, type: ManualBranchDto })
  @Optional()
  @ValidateNested()
  @Type(() => ManualBranchDto)
  branch?: ManualBranchDto;

  @ApiProperty({ required: false, maxLength: 50 })
  @Optional()
  @Transform(trim)
  @IsString()
  @MaxLength(50)
  signatureMenu?: string;

  // POST /uploads/photos(STORE_COVER)가 준 경로. 서버가 소유자를 다시 확인한다.
  @ApiProperty({ required: false })
  @Optional()
  @IsString()
  coverPhotoPath?: string;
}

export class FindBranchesQueryDto {
  @ApiProperty({ minLength: 1, maxLength: 30, description: '가게 이름.' })
  @Transform(trim)
  @IsString()
  @MinLength(1)
  @MaxLength(30)
  name!: string;
}
