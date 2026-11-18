import { ApiProperty } from '@nestjs/swagger';
import { SwipeDecisionKind } from '@prisma/client';
import { Transform, Type } from 'class-transformer';
import {
  IsBoolean,
  IsEnum,
  IsIn,
  IsInt,
  IsObject,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  ValidateNested,
} from 'class-validator';
import { NOTE_MAX } from '../discovery-rules';

export const DECISION_TARGET_KINDS = ['CREATOR', 'CAMPAIGN'] as const;

const trim = ({ value }: { value: unknown }): unknown =>
  typeof value === 'string' ? value.trim() : value;

// 성과 추가(조회수 수당). 범위는 가게 흐름 개정 계획의 서버 설정과 같고 서비스가 한 곳에서 검사한다.
export class ProposalPerformanceDto {
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

// 브랜드가 관심에 붙이는 제안(04의 "…에게 제안"). 서로 관심이 닿으면 이 값이 조건 버전 1이 된다.
export class BrandProposalDto {
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
    type: ProposalPerformanceDto,
    nullable: true,
    required: false,
    description:
      '성과 추가. 없으면 null. 캠페인 형식이 블로그 글이면 받지 않는다.',
  })
  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => ProposalPerformanceDto)
  performance?: ProposalPerformanceDto | null;
}

export class PutDecisionDto {
  @ApiProperty({
    enum: DECISION_TARGET_KINDS,
    enumName: 'DecisionTargetKind',
    description: '브랜드는 CREATOR만, 크리에이터는 CAMPAIGN만 보낸다.',
  })
  @IsIn(DECISION_TARGET_KINDS)
  targetKind!: (typeof DECISION_TARGET_KINDS)[number];

  @ApiProperty({
    format: 'uuid',
    description: '크리에이터(사용자) 또는 캠페인의 id.',
  })
  @IsUUID()
  targetId!: string;

  @ApiProperty({ enum: SwipeDecisionKind, enumName: 'SwipeDecisionKind' })
  @IsEnum(SwipeDecisionKind)
  decision!: SwipeDecisionKind;

  @ApiProperty({
    required: false,
    nullable: true,
    maxLength: NOTE_MAX.BRAND,
    description:
      'LIKE에 붙이는 글. 크리에이터는 40자(조건 버전의 제목), 브랜드는 100자(좋아한 점). 사장님은 글을 받지 않아요(보내면 400).',
  })
  @IsOptional()
  @Transform(trim)
  @IsString()
  @MaxLength(NOTE_MAX.BRAND)
  note?: string | null;

  @ApiProperty({
    type: BrandProposalDto,
    required: false,
    nullable: true,
    description:
      '브랜드의 LIKE에만 붙인다(크리에이터가 보내면 400). 이미 LIKE인 결정에 다시 보내면 값만 덮어쓴다.',
  })
  @IsOptional()
  @IsObject()
  @ValidateNested()
  @Type(() => BrandProposalDto)
  proposal?: BrandProposalDto | null;
}
