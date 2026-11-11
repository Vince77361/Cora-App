import { ApiProperty } from '@nestjs/swagger';
import { ContentFormat } from '@prisma/client';

// 결제 화면(A8)이 그리는 값. 금액은 모두 원 단위 정수이고, 서버가 계산한 값만 쓴다.
export class PaymentQuoteModel {
  @ApiProperty({
    type: 'integer',
    description: '에스크로에 보관할 금액. 조건의 조회수당 상한이다.',
  })
  escrow!: number;

  @ApiProperty({
    type: 'integer',
    description: '서비스 수수료. 상한 × 수수료율을 내림한 값.',
  })
  fee!: number;

  @ApiProperty({ type: 'integer', description: '수수료율(%).' })
  feeRate!: number;

  @ApiProperty({
    type: 'integer',
    description: '지금 결제할 금액(상한 + 수수료).',
  })
  total!: number;

  @ApiProperty({ description: 'PG에 넘기는 주문 이름.' })
  orderName!: string;

  @ApiProperty({ description: '오퍼를 수락한 크리에이터의 활동 이름.' })
  creatorName!: string;

  @ApiProperty({ type: String, nullable: true })
  creatorPhotoUrl!: string | null;

  @ApiProperty({ enum: ContentFormat, enumName: 'ContentFormat' })
  format!: ContentFormat;

  @ApiProperty({
    type: 'integer',
    description: '콘텐츠 편 수. 오퍼는 지금 한 편이다.',
  })
  pieces!: number;

  @ApiProperty({
    type: String,
    nullable: true,
    description: '식사권 이름. 보상에 식사권이 없으면 null.',
  })
  voucherName!: string | null;
}
