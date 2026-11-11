import { FakeClock } from '../../test/support/fake-clock';
import {
  UPLOAD_URL_LIMIT,
  UPLOAD_URL_WINDOW_MS,
  UploadRateLimiter,
} from './upload-rate-limiter';

describe('UploadRateLimiter', () => {
  let clock: FakeClock;
  let limiter: UploadRateLimiter;
  // 내부 맵 크기를 보려고 타입을 좁혀 읽는다(메모리가 무한히 늘지 않는지 확인).
  const sizeOf = () =>
    (limiter as unknown as { issued: Map<string, number[]> }).issued.size;

  beforeEach(() => {
    clock = new FakeClock();
    limiter = new UploadRateLimiter(clock);
  });

  it('allows up to the limit and then refuses', () => {
    for (let i = 0; i < UPLOAD_URL_LIMIT; i++) {
      expect(limiter.tryAcquire('a')).toBe(true);
    }
    expect(limiter.tryAcquire('a')).toBe(false);
  });

  it('does not count a refused attempt', () => {
    for (let i = 0; i < UPLOAD_URL_LIMIT; i++) limiter.tryAcquire('a');
    for (let i = 0; i < 5; i++) limiter.tryAcquire('a');
    clock.advance(UPLOAD_URL_WINDOW_MS + 1);
    expect(limiter.tryAcquire('a')).toBe(true);
  });

  it('release gives one slot back', () => {
    for (let i = 0; i < UPLOAD_URL_LIMIT; i++) limiter.tryAcquire('a');
    limiter.release('a');
    expect(limiter.tryAcquire('a')).toBe(true);
    expect(limiter.tryAcquire('a')).toBe(false);
  });

  it('release for an unknown user does nothing', () => {
    expect(() => limiter.release('nobody')).not.toThrow();
  });

  it('drops users with no recent timestamps so memory does not grow', () => {
    for (let i = 0; i < 100; i++) limiter.tryAcquire(`user-${i}`);
    expect(sizeOf()).toBe(100);
    clock.advance(UPLOAD_URL_WINDOW_MS + 1);
    limiter.tryAcquire('someone-new');
    expect(sizeOf()).toBe(1);
  });
});
