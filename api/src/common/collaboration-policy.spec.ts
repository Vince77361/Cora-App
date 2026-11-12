import {
  PROPOSAL_POLICY,
  RECOMMEND_POLICY,
  REWARD_POLICY,
  STORE_PAGE_POLICY,
  VIEW_REPORT_POLICY,
} from './collaboration-policy';

describe('collaboration policy', () => {
  it('keeps the reward defaults inside their own ranges and steps', () => {
    const { viewRate, perViewCap } = REWARD_POLICY;
    expect(viewRate.default).toBeGreaterThanOrEqual(viewRate.min);
    expect(viewRate.default).toBeLessThanOrEqual(viewRate.max);
    expect(viewRate.default % viewRate.step).toBe(0);
    expect(perViewCap.default).toBeGreaterThanOrEqual(perViewCap.min);
    expect(perViewCap.default).toBeLessThanOrEqual(perViewCap.max);
    expect(perViewCap.default % perViewCap.step).toBe(0);
  });

  it('offers fixed cash presets that fit the store maximum and step', () => {
    const { fixedCash } = REWARD_POLICY;
    for (const preset of fixedCash.presets) {
      expect(preset).toBeLessThanOrEqual(fixedCash.maxByCommissioner.STORE);
      expect(preset % fixedCash.step).toBe(0);
    }
  });

  it('allows a larger fixed cash for a brand than for a store', () => {
    const { maxByCommissioner } = REWARD_POLICY.fixedCash;
    expect(maxByCommissioner.BRAND).toBeGreaterThan(maxByCommissioner.STORE);
  });

  it('holds the values the owner confirmed for the proposal and report rules', () => {
    expect(REWARD_POLICY.usageRightsDefault).toBe('STORE_REPOST_3M');
    expect(REWARD_POLICY.voucher.defaultName).toBe('식사권');
    expect(PROPOSAL_POLICY.maxVersions).toBe(10);
    expect(VIEW_REPORT_POLICY.confirmHours).toBe(48);
    expect(VIEW_REPORT_POLICY.evidenceWaitDays).toBe(3);
    expect(STORE_PAGE_POLICY.trialBannerDays).toBe(30);
    expect(RECOMMEND_POLICY.picks).toBe(3);
  });
});
