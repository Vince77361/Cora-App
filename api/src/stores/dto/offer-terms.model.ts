import { ApiProperty } from '@nestjs/swagger';
import { ContentFormat, SettlementMethod, UsageRights } from '@prisma/client';

// 가게의 기본 조건과 오퍼 조건이 같은 모양을 쓴다. 보상에 들어가지 않는 항목은 null이다.
// 보상은 세 요소(식사권, 고정 현금, 조회수 수당)로 말하고, 최대 현금 부담과 정산 방식은 서버가 계산해 내려 준다.
export class OfferTermsModel {
  @ApiProperty({ enum: ContentFormat, enumName: 'ContentFormat' })
  format!: ContentFormat;

  @ApiProperty({
    type: 'integer',
    description: '콘텐츠 편 수. 오퍼는 지금 한 편이다.',
  })
  pieces!: number;

  @ApiProperty({ type: String, nullable: true })
  voucherName!: string | null;

  @ApiProperty({ type: 'integer', nullable: true })
  voucherValue!: number | null;

  @ApiProperty({ type: 'integer', nullable: true })
  voucherPeople!: number | null;

  @ApiProperty({ type: 'integer', description: '고정 현금(원). 없으면 0.' })
  fixedCash!: number;

  @ApiProperty({
    type: 'integer',
    nullable: true,
    description: '조회수 수당 단가. 1,000회당 원이다. 수당이 없으면 null.',
  })
  viewRatePerThousand!: number | null;

  @ApiProperty({
    type: 'integer',
    nullable: true,
    description: '조회수 수당 상한(원). 수당이 없으면 null.',
  })
  perViewCap!: number | null;

  @ApiProperty({ enum: UsageRights, enumName: 'UsageRights' })
  usageRights!: UsageRights;

  @ApiProperty({
    type: 'integer',
    description: '최대 현금 부담. 고정 현금 + 조회수 수당 상한이다.',
  })
  maxCashBurden!: number;

  @ApiProperty({ enum: SettlementMethod, enumName: 'SettlementMethod' })
  settlementMethod!: SettlementMethod;
}
