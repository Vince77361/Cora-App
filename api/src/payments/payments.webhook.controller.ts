import { Controller, Headers, HttpCode, Post, Req } from '@nestjs/common';
import type { RawBodyRequest } from '@nestjs/common';
import { ApiExcludeController } from '@nestjs/swagger';
import type { Request } from 'express';
import { Public } from '../auth/public.decorator';
import { AppError } from '../common/errors/app-error';
import { PaymentPort } from '../integrations/payment/payment.port';
import { PaymentsService } from './payments.service';

// PG가 부르는 주소라 앱 API 문서와 생성 클라이언트에 넣지 않는다.
@ApiExcludeController()
@Controller()
export class PaymentsWebhookController {
  constructor(
    private readonly paymentPort: PaymentPort,
    private readonly payments: PaymentsService,
  ) {}

  // 로그인 없이 열려 있으므로 서명을 통과한 요청만 처리한다. 서명은 파싱된 JSON이 아니라 받은 본문 그대로에 대한 것이다.
  @Public()
  @Post('webhooks/payments')
  @HttpCode(200)
  async receive(
    @Req() req: RawBodyRequest<Request>,
    @Headers('x-cora-signature') signature?: string | string[],
  ): Promise<void> {
    // 헤더나 본문이 없으면 빈 문자열로 넘긴다: 서명 검증이 TypeError로 죽지 않고 거절(401)로 끝나게.
    const notice = this.paymentPort.verifyWebhook(
      req.rawBody?.toString('utf8') ?? '',
      typeof signature === 'string' ? signature : '',
    );
    if (!notice) {
      throw new AppError(
        'UNAUTHENTICATED',
        '결제 통지의 서명이 올바르지 않아요.',
      );
    }
    await this.payments.applyResult(notice, { swallowNotifyErrors: true });
  }
}
