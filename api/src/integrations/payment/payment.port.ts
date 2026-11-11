import type { PaymentMethod } from '@prisma/client';

export type PaymentNotice = {
  paymentId: string;
  pgTransactionId: string;
  status: 'APPROVED' | 'FAILED';
};

// 결제대행사(PG) 포트. 구현체는 IntegrationsModule이 PAYMENT_ADAPTER 값으로 고른다.
export abstract class PaymentPort {
  abstract createCheckout(input: {
    paymentId: string;
    amount: number;
    method: PaymentMethod;
    orderName: string;
  }): Promise<{ checkoutUrl: string }>;

  // 서명이 맞지 않거나 형식이 틀리면 null이다. 호출한 쪽은 null이면 아무것도 바꾸지 않고 거절한다.
  abstract verifyWebhook(
    rawBody: string,
    signature: string,
  ): PaymentNotice | null;

  abstract fetchStatus(
    paymentId: string,
  ): Promise<'PENDING' | 'APPROVED' | 'FAILED'>;

  // 같은 idempotencyKey로 다시 불러도 환급이 한 번만 나가야 한다.
  abstract refund(input: {
    pgTransactionId: string;
    amount: number;
    idempotencyKey: string;
  }): Promise<{ externalId: string }>;
}
