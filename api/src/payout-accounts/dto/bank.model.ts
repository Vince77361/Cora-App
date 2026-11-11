import { ApiProperty } from '@nestjs/swagger';

export class BankModel {
  @ApiProperty({ description: '금융결제원 은행 코드(세 자리).' })
  code!: string;

  @ApiProperty({ description: '고르는 목록에 쓰는 이름. 예: 국민' })
  name!: string;

  @ApiProperty({ description: '계좌 화면에 보이는 이름. 예: 국민은행' })
  fullName!: string;
}
