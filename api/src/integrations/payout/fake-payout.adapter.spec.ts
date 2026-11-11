import { FakePayoutAdapter } from './fake-payout.adapter';
import { PayoutFailedError } from './payout.port';

const base = { bankCode: '004', accountNumber: '1234567890', amount: 1000 };

describe('FakePayoutAdapter', () => {
  it('always succeeds and returns the same id for the same idempotency key', async () => {
    const adapter = new FakePayoutAdapter();
    const a = await adapter.send({
      ...base,
      holderName: '김크리',
      idempotencyKey: 'k1',
    });
    const b = await adapter.send({
      ...base,
      holderName: '김크리',
      idempotencyKey: 'k1',
    });
    expect(a.externalId).toBe(b.externalId);
    expect(adapter.sent).toHaveLength(1);
  });

  it('fails when the holder name contains fail', async () => {
    const adapter = new FakePayoutAdapter();
    await expect(
      adapter.send({
        ...base,
        holderName: 'fail 예금주',
        idempotencyKey: 'k2',
      }),
    ).rejects.toBeInstanceOf(PayoutFailedError);
    expect(adapter.sent).toHaveLength(0);
  });
});
