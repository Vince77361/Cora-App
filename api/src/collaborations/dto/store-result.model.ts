import { ApiProperty } from '@nestjs/swagger';
import { ContentFormat } from '@prisma/client';

export class StoreResultCreatorModel {
  @ApiProperty({ format: 'uuid' })
  userId!: string;

  @ApiProperty({ description: '크리에이터의 활동 이름.' })
  name!: string;

  @ApiProperty({ type: String, nullable: true })
  photoUrl!: string | null;
}

// 사장님의 7일 결과(G1). 끝난(SETTLED) 가게 오퍼 협업 한 건의 결과다.
export class StoreResultModel {
  @ApiProperty({ type: StoreResultCreatorModel })
  creator!: StoreResultCreatorModel;

  @ApiProperty({ enum: ContentFormat, enumName: 'ContentFormat' })
  format!: ContentFormat;

  @ApiProperty({
    format: 'date-time',
    description: '크리에이터가 게시 링크를 낸 시각(ISO 8601).',
  })
  postedAt!: string;

  @ApiProperty({ description: '크리에이터가 낸 게시 링크.' })
  postUrl!: string;

  @ApiProperty({
    type: 'integer',
    nullable: true,
    description: '정산에 쓴 최종 조회수. 조회수를 세지 않은 협업은 null.',
  })
  views!: number | null;

  @ApiProperty({
    type: 'integer',
    nullable: true,
    description:
      '가게 인스타그램 계정의 평소 조회수. 링크가 없거나 읽지 못했으면 null이고, 그러면 비교 상자를 숨긴다.',
  })
  usualViews!: number | null;

  @ApiProperty({
    type: 'integer',
    nullable: true,
    description:
      '평소 대비 배수를 10배 한 정수(31 = 3.1배, 소수 첫째 자리까지 내림). 평소 조회수가 없으면 null.',
  })
  multiplierTenths!: number | null;

  @ApiProperty({ type: 'integer', description: '크리에이터 지급액(원).' })
  payout!: number;

  @ApiProperty({ type: 'integer', description: '사장님께 환불한 금액(원).' })
  refund!: number;

  @ApiProperty({
    description:
      '고정 현금만 있던 협업이면 true. 조회수를 세지 않아 조회수와 비교 상자가 없다.',
  })
  fixedCashOnly!: boolean;

  @ApiProperty({
    type: 'integer',
    description: '고정 현금(원). 없으면 0.',
  })
  fixedCash!: number;
}
