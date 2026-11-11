import { ApiProperty } from '@nestjs/swagger';

export class PayoutAccountModel {
  @ApiProperty()
  bankCode!: string;

  @ApiProperty({ description: '고르는 목록에 쓰는 은행 이름. 예: 국민' })
  bankName!: string;

  @ApiProperty({ description: '계좌 화면에 보이는 은행 이름. 예: 국민은행' })
  bankFullName!: string;

  @ApiProperty({
    description:
      '계좌번호 뒤 4자리. 전체 번호는 응답에 나가지 않는다. 화면은 뒤 2자리만 보여 준다.',
  })
  accountLast4!: string;

  @ApiProperty()
  holderName!: string;
}
