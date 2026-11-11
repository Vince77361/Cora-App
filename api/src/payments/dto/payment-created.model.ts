import { ApiProperty } from '@nestjs/swagger';

export class PaymentCreatedModel {
  @ApiProperty({ format: 'uuid' })
  paymentId!: string;

  @ApiProperty({ description: '앱이 여는 결제창 주소.' })
  checkoutUrl!: string;
}
