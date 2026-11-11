import { OffersService } from '../offers.service';
import { PaymentDueExpiryHandler } from './payment-due-expiry.handler';

// 만료할지는 서비스가 읽을 때 만료와 같은 길로 정한다(서비스 spec). 처리기는 작업 내용을 서비스에 넘기기만 한다.
class FakeOffersService extends OffersService {
  readonly expiredIds: string[] = [];
  constructor() {
    super(
      null as never,
      null as never,
      null as never,
      null as never,
      null as never,
      null as never,
      null as never,
      null as never,
      null as never,
      null as never,
    );
  }
  expireUnpaid(offerId: string): Promise<void> {
    this.expiredIds.push(offerId);
    return Promise.resolve();
  }
}

describe('PaymentDueExpiryHandler', () => {
  it('hands the offer id of the job to the offers service', async () => {
    const offers = new FakeOffersService();
    await new PaymentDueExpiryHandler(offers).run({ offerId: 'o1' });
    expect(offers.expiredIds).toEqual(['o1']);
  });

  it('fails a job that carries no offer id so the queue shows it', async () => {
    const offers = new FakeOffersService();
    await expect(
      new PaymentDueExpiryHandler(offers).run({ collaborationId: 'c1' }),
    ).rejects.toThrow('offerId');
    expect(offers.expiredIds).toEqual([]);
  });
});
