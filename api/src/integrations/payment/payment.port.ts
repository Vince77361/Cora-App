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

  // 통지를 놓쳤을 때 PG에 직접 묻는다. 환급이 PG 거래 번호를 요구하므로 승인된 결제는 그 번호도 함께 돌려준다
  // (아직 PENDING이거나 PG가 모르는 결제는 null).
  //
  // 돈 안전 계약 — 어댑터는 반드시 지킨다. 서버는 이 답으로 새 결제창을 열지 정한다:
  // - FAILED는 "PG가 이 결제창으로는 더 이상 승인될 수 없다고 확정했다"일 때만 돌려준다: 사용자 취소가 확인됨, 결제 기한 만료,
  //   또는 PG가 이 결제 요청을 모른다고 확정해 답함. 서버(PaymentsService.reconcilePendingBeforeNewPayment)는 FAILED를 받으면
  //   그 결제를 실패로 바꾸고 같은 요청에서 새 결제창을 연다.
  // - 그 결제창으로 아직 돈이 나갈 수 있으면 반드시 PENDING이다: 사용자가 창만 닫았다, 인증·승인 진행 중이다, PG가 아직 기록하지 않았다,
  //   조회가 일시적으로 실패했다. 이때 FAILED를 돌려주면 첫 결제창이 나중에 승인돼 이중 결제가 된다(운영자 수동 환급).
  //   확실하지 않으면 던지거나 PENDING이다(서버는 던진 오류·시간 초과도 PENDING처럼 아무것도 바꾸지 않는다).
  // - APPROVED와 FAILED가 아닌 값은 서버가 대기로 본다(PG의 문자열을 그대로 넘기지 말고 세 값으로 옮긴다).
  abstract fetchStatus(paymentId: string): Promise<{
    status: 'PENDING' | 'APPROVED' | 'FAILED';
    pgTransactionId: string | null;
  }>;

  // 같은 idempotencyKey로 다시 불러도 환급이 한 번만 나가야 한다.
  abstract refund(input: {
    pgTransactionId: string;
    amount: number;
    idempotencyKey: string;
  }): Promise<{ externalId: string }>;
}
