import { Clock } from '../../common/clock';
import { ViewCountPort, ViewCountUnavailableError } from './view-count.port';

const DAY_MS = 24 * 60 * 60 * 1000;
const VIEWS_PER_DAY = 600;
// 가짜 계정의 평소 조회수(캔버스 G1의 "평소 약 4,000회").
const ACCOUNT_AVERAGE_VIEWS = 4000;

// 가짜 조회수. 주소로 시나리오를 고른다:
// notmine → 내 계정이 아님, unavailable → 읽기 실패, views=<숫자> → 그 값, 그 밖에는 하루 600회씩 늘어난다.
// 계정 평균은 아이디에 unavailable이 있으면 읽기 실패, 그 밖에는 4,000이다.
export class FakeViewCountAdapter extends ViewCountPort {
  constructor(private readonly clock: Clock) {
    super();
  }

  isOwnedBy(url: string): Promise<boolean> {
    return Promise.resolve(!url.includes('notmine'));
  }

  read(input: { url: string; submittedAt: Date }): Promise<number> {
    if (input.url.includes('unavailable')) {
      return Promise.reject(new ViewCountUnavailableError());
    }
    const given = /[?&]views=(\d+)/.exec(input.url);
    if (given) return Promise.resolve(Number(given[1]));
    const days = Math.floor(
      (this.clock.now().getTime() - input.submittedAt.getTime()) / DAY_MS,
    );
    return Promise.resolve(VIEWS_PER_DAY * Math.max(0, days));
  }

  readAccountAverage(handle: string): Promise<number> {
    if (handle.includes('unavailable')) {
      return Promise.reject(new ViewCountUnavailableError());
    }
    return Promise.resolve(ACCOUNT_AVERAGE_VIEWS);
  }
}
