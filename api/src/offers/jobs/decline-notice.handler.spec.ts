import { OffersService } from '../offers.service';
import { DeclineNoticeHandler } from './decline-notice.handler';

// 알림을 보낼지는 서비스가 오퍼의 현재 상태로 정한다(서비스 spec). 처리기는 작업 내용을 서비스에 넘기기만 한다.
class FakeOffersService extends OffersService {
  readonly noticed: [string, Date][] = [];
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
  sendDeclineNotice(offerId: string, declinedAt: Date): Promise<void> {
    this.noticed.push([offerId, declinedAt]);
    return Promise.resolve();
  }
}

describe('DeclineNoticeHandler', () => {
  it('hands the offer id and the decline time of the job to the offers service', async () => {
    const offers = new FakeOffersService();
    await new DeclineNoticeHandler(offers).run({
      offerId: 'o1',
      declinedAt: '2026-12-01T00:00:00.000Z',
    });
    expect(offers.noticed).toEqual([['o1', new Date('2026-12-01T00:00:00Z')]]);
  });

  it('fails a job that carries no decline time, so an old-format job cannot notify blindly', async () => {
    const offers = new FakeOffersService();
    await expect(
      new DeclineNoticeHandler(offers).run({ offerId: 'o1' }),
    ).rejects.toThrow('declinedAt');
    expect(offers.noticed).toEqual([]);
  });

  it('fails a job that carries no offer id so the queue shows it', async () => {
    const offers = new FakeOffersService();
    await expect(
      new DeclineNoticeHandler(offers).run({ collaborationId: 'c1' }),
    ).rejects.toThrow('offerId');
    expect(offers.noticed).toEqual([]);
  });
});
