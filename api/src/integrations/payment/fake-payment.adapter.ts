import { createHmac, timingSafeEqual } from 'crypto';
import { Logger } from '@nestjs/common';
import type { PaymentMethod } from '@prisma/client';
import { AppError } from '../../common/errors/app-error';
import { PaymentNotice, PaymentPort } from './payment.port';

// 가짜 PG. 개발 서버와 테스트에서 실제 결제 없이 결제 흐름을 끝까지 돌려 본다.
// 통지는 실제 PG처럼 본문 전체에 대한 HMAC-SHA256 서명을 단다.
export class FakePaymentAdapter extends PaymentPort {
  private readonly logger = new Logger(FakePaymentAdapter.name);
  // fetchStatus가 보는 "PG 쪽 기록". 가짜 통지를 만들 때마다 여기에 남는다.
  private readonly results = new Map<string, PaymentNotice>();
  readonly refunds: {
    pgTransactionId: string;
    amount: number;
    idempotencyKey: string;
    externalId: string;
  }[] = [];

  constructor(private readonly webhookSecret: string | undefined) {
    super();
  }

  createCheckout(input: {
    paymentId: string;
    amount: number;
    method: PaymentMethod;
    orderName: string;
  }): Promise<{ checkoutUrl: string }> {
    return Promise.resolve({
      checkoutUrl: `cora-dev://fake-pay?paymentId=${encodeURIComponent(input.paymentId)}`,
    });
  }

  verifyWebhook(rawBody: string, signature: string): PaymentNotice | null {
    const expected = this.sign(rawBody);
    const given = Buffer.from(signature, 'utf8');
    const want = Buffer.from(expected, 'utf8');
    // 길이가 다르면 timingSafeEqual이 던지므로 먼저 거른다. 길이는 비밀이 아니다.
    if (given.length !== want.length || !timingSafeEqual(given, want)) {
      return null;
    }
    try {
      const body = JSON.parse(rawBody) as Partial<PaymentNotice>;
      if (
        typeof body.paymentId !== 'string' ||
        typeof body.pgTransactionId !== 'string' ||
        (body.status !== 'APPROVED' && body.status !== 'FAILED')
      ) {
        return null;
      }
      return {
        paymentId: body.paymentId,
        pgTransactionId: body.pgTransactionId,
        status: body.status,
      };
    } catch {
      return null;
    }
  }

  fetchStatus(paymentId: string): Promise<{
    status: 'PENDING' | 'APPROVED' | 'FAILED';
    pgTransactionId: string | null;
  }> {
    // 개발 서버를 다시 띄우면 메모리 기록이 사라져 PENDING으로 돌아온다. 호출한 쪽은 이를 "아직 모름"으로 본다.
    const recorded = this.results.get(paymentId);
    return Promise.resolve({
      status: recorded?.status ?? 'PENDING',
      pgTransactionId: recorded?.pgTransactionId ?? null,
    });
  }

  refund(input: {
    pgTransactionId: string;
    amount: number;
    idempotencyKey: string;
  }): Promise<{ externalId: string }> {
    const externalId = `fake-refund-${input.idempotencyKey}`;
    if (!this.refunds.some((r) => r.idempotencyKey === input.idempotencyKey)) {
      this.refunds.push({ ...input, externalId });
      this.logger.log(
        `환급(가짜) amount=${input.amount} key=${input.idempotencyKey}`,
      );
    }
    return Promise.resolve({ externalId });
  }

  // 개발용 통지 경로가 쓴다: PG가 결과를 냈다는 기록만 남긴다. 서명하지 않으므로 PAYMENT_WEBHOOK_SECRET 없이도 된다.
  recordResult(input: {
    paymentId: string;
    status: 'APPROVED' | 'FAILED';
    pgTransactionId?: string;
  }): PaymentNotice {
    const notice = this.noticeOf(input);
    this.results.set(input.paymentId, notice);
    return notice;
  }

  // 서명 경로(웹훅) 테스트가 쓴다: 결과를 기록하고, 서명된 본문을 돌려준다.
  recordFakeResult(input: {
    paymentId: string;
    status: 'APPROVED' | 'FAILED';
    pgTransactionId?: string;
  }): { rawBody: string; signature: string } {
    const notice = this.noticeOf(input);
    const rawBody = JSON.stringify(notice);
    // 서명이 실패하면(비밀값 없음) 기록도 남기지 않는다.
    const signature = this.sign(rawBody);
    this.results.set(input.paymentId, notice);
    return { rawBody, signature };
  }

  private noticeOf(input: {
    paymentId: string;
    status: 'APPROVED' | 'FAILED';
    pgTransactionId?: string;
  }): PaymentNotice {
    return {
      paymentId: input.paymentId,
      pgTransactionId: input.pgTransactionId ?? `fake-tx-${input.paymentId}`,
      status: input.status,
    };
  }

  private sign(rawBody: string): string {
    if (!this.webhookSecret) {
      throw new AppError(
        'INTERNAL',
        'PAYMENT_WEBHOOK_SECRET이 없어서 결제 통지 서명을 만들거나 확인할 수 없어요. api/.env에 값을 넣어 주세요.',
      );
    }
    return createHmac('sha256', this.webhookSecret)
      .update(rawBody)
      .digest('hex');
  }
}
