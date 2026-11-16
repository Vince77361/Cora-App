import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsBoolean,
  IsInt,
  IsObject,
  IsOptional,
  Min,
  ValidateNested,
} from 'class-validator';

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

// 협업 중에 돈과 혜택만 바꿔 새 판본을 낸다. 나머지 항목은 직전 판본에서 그대로 옮긴다.
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
    type: 'integer',
    description: '제작비(원). 1만 원 단위, 10000~10000000.',
  })
  @IsInt()
  fee!: number;

  @ApiProperty({ description: '제품 제공 여부.' })
  @IsBoolean()
  productProvided!: boolean;

  @ApiProperty({
    type: RewardPerformanceDto,
    nullable: true,
    required: false,
    description: '성과 추가. 없으면 null. 블로그 글에는 붙일 수 없다.',
  })
  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => RewardPerformanceDto)
  performance?: RewardPerformanceDto | null;
}
