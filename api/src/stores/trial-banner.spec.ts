import { trialBannerOf } from './trial-banner';

const NOW = new Date('2026-11-13T03:00:00.000Z'); // 한국 시간 11월 13일 낮 12시
const day = (iso: string) => new Date(`${iso}T00:00:00.000Z`);
const INFO = {
  trialMonthlyFee: 300000,
  trialPostCount: 12,
  trialSnoozedUntil: null,
  trialHintSeenAt: null,
  hasReviewPostLink: false,
};

describe('trialBannerOf', () => {
  it('shows the compare banner within 30 days of the trial end, counting the end day', () => {
    expect(
      trialBannerOf({ ...INFO, trialEndsOn: day('2026-12-13') }, NOW),
    ).toBe('COMPARE');
    expect(
      trialBannerOf({ ...INFO, trialEndsOn: day('2026-11-13') }, NOW),
    ).toBe('COMPARE');
    expect(
      trialBannerOf({ ...INFO, trialEndsOn: day('2026-12-14') }, NOW),
    ).toBeNull();
  });

  it('hides it once the trial has ended', () => {
    expect(
      trialBannerOf({ ...INFO, trialEndsOn: day('2026-11-12') }, NOW),
    ).toBeNull();
  });

  it('counts the day in Korean time, not UTC', () => {
    // UTC로는 11월 12일 16시지만 한국은 11월 13일 새벽 1시다.
    const late = new Date('2026-11-12T16:00:00.000Z');
    expect(
      trialBannerOf({ ...INFO, trialEndsOn: day('2026-11-13') }, late),
    ).toBe('COMPARE');
  });

  it('hides the compare banner while snoozed and shows it again after', () => {
    const snoozed = {
      ...INFO,
      trialEndsOn: day('2026-12-01'),
      trialSnoozedUntil: new Date('2026-11-20T03:00:00.000Z'),
    };
    expect(trialBannerOf(snoozed, NOW)).toBeNull();
    expect(trialBannerOf(snoozed, new Date('2026-11-20T03:00:00.000Z'))).toBe(
      'COMPARE',
    );
  });

  it('shows the hint once for a store with a review post link and no trial info', () => {
    const empty = {
      trialMonthlyFee: null,
      trialEndsOn: null,
      trialPostCount: null,
      trialSnoozedUntil: null,
      trialHintSeenAt: null,
      hasReviewPostLink: true,
    };
    expect(trialBannerOf(empty, NOW)).toBe('HINT');
    expect(trialBannerOf({ ...empty, trialHintSeenAt: NOW }, NOW)).toBeNull();
    expect(
      trialBannerOf({ ...empty, hasReviewPostLink: false }, NOW),
    ).toBeNull();
  });

  it('shows nothing for a store whose trial info is not near its end', () => {
    expect(
      trialBannerOf(
        { ...INFO, trialEndsOn: day('2027-03-01'), hasReviewPostLink: true },
        NOW,
      ),
    ).toBeNull();
  });
});
