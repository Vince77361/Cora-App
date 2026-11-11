import { Controller, HttpCode, Param, Post } from '@nestjs/common';
import { ApiExcludeController } from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthUser } from '../auth/current-user.decorator';
import { AppError } from '../common/errors/app-error';
import { FakePaymentAdapter } from '../integrations/payment/fake-payment.adapter';
import { PaymentPort } from '../integrations/payment/payment.port';
import { PaymentStatusModel } from './dto/payment-status.model';
import { PaymentsService } from './payments.service';

// 앱의 가짜 결제창이 부르는 개발 전용 경로. PaymentsDevModule이 운영이 아니고 PAYMENT_ADAPTER=fake일 때만 등록하므로
// 그 밖에서는 라우트가 없다(404). 서명은 하지 않고 가짜 PG에 결과를 기록한 뒤 웹훅과 같은 applyResult로 넘긴다.
@ApiExcludeController()
@Controller('dev/fake-payments')
export class PaymentsDevController {
  constructor(
    private readonly paymentPort: PaymentPort,
    private readonly payments: PaymentsService,
  ) {}

  @Post(':id/approve')
  @HttpCode(200)
  approve(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
  ): Promise<PaymentStatusModel> {
    return this.settle(user.userId, id, 'APPROVED');
  }

  @Post(':id/fail')
  @HttpCode(200)
  fail(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
  ): Promise<PaymentStatusModel> {
    return this.settle(user.userId, id, 'FAILED');
  }

  // 개발 경로라도 그 결제를 만든 사장님만 결과를 낼 수 있다.
  private async settle(
    userId: string,
    id: string,
    status: 'APPROVED' | 'FAILED',
  ): Promise<PaymentStatusModel> {
    const payment = await this.payments.requireOwnedPayment(userId, id);
    if (!(this.paymentPort instanceof FakePaymentAdapter)) {
      throw new AppError('INTERNAL', '가짜 결제 어댑터가 아니에요.');
    }
    const notice = this.paymentPort.recordResult({
      paymentId: payment.id,
      status,
    });
    await this.payments.applyResult(notice, { swallowNotifyErrors: true });
    return this.payments.getStatus(userId, id);
  }
}
