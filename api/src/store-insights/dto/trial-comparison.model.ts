import { ApiProperty } from '@nestjs/swagger';
import { ContentFormat } from '@prisma/client';

export class TrialSideModel {
  @ApiProperty({ type: 'integer', description: '월 계약 금액(원).' })
  monthlyFee!: number;

  @ApiProperty({
    example: '2026-12-10',
    description: '계약 종료일(한국 날짜, YYYY-MM-DD).',
  })
  endsOn!: string;

  @ApiProperty({ type: 'integer', description: '석 달 동안 받은 글 수.' })
  postCount!: number;

  @ApiProperty({
    type: 'integer',
    description: '석 달 동안 들어간 돈(원). 월 계약 금액 × 3.',
  })
  spent!: number;
}

export class ContentCountModel {
  @ApiProperty({ enum: ContentFormat, enumName: 'ContentFormat' })
  format!: ContentFormat;

  @ApiProperty({ type: 'integer' })
  count!: number;
}

export class CoraSideModel {
  @ApiProperty({ type: 'integer', description: '끝난 협업 수(오퍼 건수).' })
  offerCount!: number;

  @ApiProperty({
    type: 'integer',
    description: '들어간 돈(원). 끝난 협업의 크리에이터 지급액과 수수료의 합.',
  })
  spent!: number;

  @ApiProperty({
    type: [ContentCountModel],
    description: '형식별 생긴 콘텐츠 수. 0편인 형식은 없다.',
  })
  contentByFormat!: ContentCountModel[];

  @ApiProperty({
    type: 'integer',
    nullable: true,
    description:
      '평소 대비 배수(10배 한 정수, 26 = 2.6배)의 평균, 소수 첫째 자리까지 내림. 배수가 있는 협업이 없으면 null.',
  })
  averageMultiplierTenths!: number | null;
}

// 체험단 재계약 전 비교(G3). Cora 칸은 오늘부터 달력으로 석 달 전까지 끝난 내 가게 협업이다.
export class TrialComparisonModel {
  @ApiProperty({ type: TrialSideModel })
  trial!: TrialSideModel;

  @ApiProperty({ type: CoraSideModel })
  cora!: CoraSideModel;
}
