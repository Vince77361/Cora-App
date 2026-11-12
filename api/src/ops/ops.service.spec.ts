import { OpsError } from './ops-error';
import { OpsService } from './ops.service';

const ID = '11111111-1111-4111-8111-111111111111';
const actor = { operator: '김운영', reason: '확인 후 처리' };

// 입력 검사는 DB·큐·PG에 닿기 전에 끝나야 한다: 무엇이든 건드리면 던지는 가짜로 확인한다.
function untouchable(): never {
  throw new Error('입력 검사 전에 의존성을 건드렸어요.');
}
const trap = new Proxy({}, { get: untouchable });
const service = new OpsService(
  trap as never,
  trap as never,
  trap as never,
  trap as never,
  trap as never,
  trap as never,
  trap as never,
  trap as never,
  trap as never,
  trap as never,
);

describe('OpsService input checks', () => {
  it.each([
    ['halt', () => service.halt(ID, { operator: '', reason: '확인' })],
    ['resume', () => service.resume(ID, { operator: '김운영', reason: '  ' })],
    [
      'force-refund',
      () => service.forceRefund(ID, { operator: '김운영', reason: '' }),
    ],
    [
      'retry-payout',
      () => service.retryPayout(ID, { operator: '', reason: '' }),
    ],
    [
      'refund-payment',
      () => service.refundPayment(ID, { operator: ' ', reason: '확인' }),
    ],
  ])(
    'refuses %s without operator and reason before touching anything',
    async (_name, run) => {
      await expect(run()).rejects.toBeInstanceOf(OpsError);
    },
  );

  it('refuses over-long operator and reason text', async () => {
    await expect(
      service.halt(ID, { operator: 'a'.repeat(101), reason: '확인' }),
    ).rejects.toThrow(/operator/);
    await expect(
      service.halt(ID, { operator: '김운영', reason: 'a'.repeat(1001) }),
    ).rejects.toThrow(/reason/);
  });

  it('refuses ids that are not UUIDs and amounts that are not whole won', async () => {
    await expect(service.halt('abc', actor)).rejects.toThrow(/id 형식/);
    await expect(service.show('abc')).rejects.toThrow(/id 형식/);
    await expect(service.forcePayout(ID, 1.5, actor)).rejects.toThrow(/정수/);
    await expect(service.forcePayout(ID, -1, actor)).rejects.toThrow(/정수/);
    await expect(service.forcePayout(ID, 0, actor)).rejects.toThrow(
      /force-refund/,
    );
    await expect(service.resumeSettlement(ID, -5, actor)).rejects.toThrow(
      /정수/,
    );
  });
});
