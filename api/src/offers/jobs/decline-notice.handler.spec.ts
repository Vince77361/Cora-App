import { OffersService } from '../offers.service';
import { DeclineNoticeHandler } from './decline-notice.handler';

// 알림을 보낼지는 서비스가 오퍼의 현재 상태로 정한다(서비스 spec). 처리기는 작업 내용을 서비스에 넘기기만 한다.
class FakeOffersService extends OffersService {
  readonly noticed: string[] = [];
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
    );
  }
  sendDeclineNotice(offerId: string): Promise<void> {
    this.noticed.push(offerId);
    return Promise.resolve();
  }
}

describe('DeclineNoticeHandler', () => {
  it('hands the offer id of the job to the offers service', async () => {
    const offers = new FakeOffersService();
    await new DeclineNoticeHandler(offers).run({ offerId: 'o1' });
    expect(offers.noticed).toEqual(['o1']);
  });

  it('fails a job that carries no offer id so the queue shows it', async () => {
    const offers = new FakeOffersService();
    await expect(
      new DeclineNoticeHandler(offers).run({ collaborationId: 'c1' }),
    ).rejects.toThrow('offerId');
    expect(offers.noticed).toEqual([]);
  });
});
