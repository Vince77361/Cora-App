import { ApiProperty } from '@nestjs/swagger';
import { PaymentStatus } from '@prisma/client';

export class PaymentStatusModel {
  @ApiProperty({
    enum: PaymentStatus,
    enumName: 'PaymentStatus',
    description:
      '결제 완료 여부는 결제창의 결과가 아니라 서버가 PG에서 받은 통지로 정해진다. 앱은 창이 닫힌 뒤 이 값을 묻는다.',
  })
  status!: PaymentStatus;
}
