import { createHmac } from 'crypto';
import { AppError } from '../../common/errors/app-error';
import { FakePaymentAdapter } from './fake-payment.adapter';

const SECRET = 'test-secret';

describe('FakePaymentAdapter', () => {
  it('creates a checkout url that carries the payment id', async () => {
    const adapter = new FakePaymentAdapter(SECRET);
    const { checkoutUrl } = await adapter.createCheckout({
      paymentId: 'pay_1',
      amount: 50000,
      method: 'CARD',
      orderName: '협업',
    });
    expect(checkoutUrl).toBe('cora-dev://fake-pay?paymentId=pay_1');
  });

  it('verifies a webhook signed with the shared secret', () => {
    const adapter = new FakePaymentAdapter(SECRET);
    const { rawBody, signature } = adapter.recordFakeResult({
      paymentId: 'pay_1',
      status: 'APPROVED',
    });
    expect(adapter.verifyWebhook(rawBody, signature)).toEqual({
      paymentId: 'pay_1',
      pgTransactionId: 'fake-tx-pay_1',
      status: 'APPROVED',
    });
  });

  it('signs with HMAC-SHA256 over the raw body using the secret', () => {
    const adapter = new FakePaymentAdapter(SECRET);
    const { rawBody, signature } = adapter.recordFakeResult({
      paymentId: 'pay_1',
      status: 'FAILED',
    });
    expect(signature).toBe(
      createHmac('sha256', SECRET).update(rawBody).digest('hex'),
    );
  });

  it('rejects a tampered body, a wrong signature and a different secret', () => {
    const adapter = new FakePaymentAdapter(SECRET);
    const { rawBody, signature } = adapter.recordFakeResult({
      paymentId: 'pay_1',
      status: 'FAILED',
    });
    const tampered = rawBody.replace('FAILED', 'APPROVED');
    expect(adapter.verifyWebhook(tampered, signature)).toBeNull();
    expect(adapter.verifyWebhook(rawBody, 'deadbeef')).toBeNull();
    expect(adapter.verifyWebhook(rawBody, '')).toBeNull();
    expect(
      new FakePaymentAdapter('other').verifyWebhook(rawBody, signature),
    ).toBeNull();
  });

  it('rejects a correctly signed body that is not a valid notice', () => {
    const adapter = new FakePaymentAdapter(SECRET);
    const body = '{"hello":1}';
    const signature = createHmac('sha256', SECRET).update(body).digest('hex');
    expect(adapter.verifyWebhook(body, signature)).toBeNull();
    const notJson = 'nope';
    const sig2 = createHmac('sha256', SECRET).update(notJson).digest('hex');
    expect(adapter.verifyWebhook(notJson, sig2)).toBeNull();
  });

  it('reports PENDING until a fake result is recorded, then that result', async () => {
    const adapter = new FakePaymentAdapter(SECRET);
    await expect(adapter.fetchStatus('pay_1')).resolves.toBe('PENDING');
    adapter.recordFakeResult({ paymentId: 'pay_1', status: 'APPROVED' });
    await expect(adapter.fetchStatus('pay_1')).resolves.toBe('APPROVED');
  });

  it('returns the same refund id for the same idempotency key', async () => {
    const adapter = new FakePaymentAdapter(SECRET);
    const a = await adapter.refund({
      pgTransactionId: 't',
      amount: 100,
      idempotencyKey: 'k1',
    });
    const b = await adapter.refund({
      pgTransactionId: 't',
      amount: 100,
      idempotencyKey: 'k1',
    });
    const c = await adapter.refund({
      pgTransactionId: 't',
      amount: 100,
      idempotencyKey: 'k2',
    });
    expect(a.externalId).toBe(b.externalId);
    expect(c.externalId).not.toBe(a.externalId);
    expect(adapter.refunds).toHaveLength(2);
  });

  it('throws a Korean error naming PAYMENT_WEBHOOK_SECRET when the secret is missing', () => {
    const adapter = new FakePaymentAdapter(undefined);
    expect(() => adapter.verifyWebhook('{}', 'x')).toThrow(
      /PAYMENT_WEBHOOK_SECRET/,
    );
    expect(() =>
      adapter.recordFakeResult({ paymentId: 'p', status: 'APPROVED' }),
    ).toThrow(AppError);
  });
});
