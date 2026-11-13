import { STORE_PAGE_POLICY } from '../common/collaboration-policy';
import { kstDateString } from '../common/kst';

export type TrialBanner = 'COMPARE' | 'HINT';
export const TRIAL_BANNERS: readonly TrialBanner[] = ['COMPARE', 'HINT'];

const DAY_MS = 24 * 60 * 60 * 1000;

export interface TrialBannerInput {
  trialMonthlyFee: number | null;
  trialEndsOn: Date | null;
  trialPostCount: number | null;
  trialSnoozedUntil: Date | null;
  trialHintSeenAt: Date | null;
  hasReviewPostLink: boolean;
}

// 홈에 보여 줄 체험단 줄. 날짜는 한국 날짜 기준이다(종료일은 날짜만 저장한다).
// COMPARE: 체험단 정보가 있고 종료일이 30일 안(지나지 않음)이고 숨김 기간이 아닐 때.
// HINT: 체험단 정보가 없고 후기 글 링크가 있고 아직 본 적 없을 때.
export function trialBannerOf(
  store: TrialBannerInput,
  now: Date,
): TrialBanner | null {
  const hasInfo =
    store.trialMonthlyFee !== null &&
    store.trialEndsOn !== null &&
    store.trialPostCount !== null;
  if (!hasInfo) {
    return store.hasReviewPostLink && store.trialHintSeenAt === null
      ? 'HINT'
      : null;
  }
  const today = Date.parse(kstDateString(now));
  // @db.Date는 UTC 0시로 읽히므로 날짜 문자열끼리 비교한다.
  const endsOn = Date.parse(store.trialEndsOn!.toISOString().slice(0, 10));
  const daysLeft = Math.round((endsOn - today) / DAY_MS);
  if (daysLeft < 0 || daysLeft > STORE_PAGE_POLICY.trialBannerDays) return null;
  if (store.trialSnoozedUntil && store.trialSnoozedUntil > now) return null;
  return 'COMPARE';
}
