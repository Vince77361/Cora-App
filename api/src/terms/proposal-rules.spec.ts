import type { TermsVersion } from '@prisma/client';
import { nextTermsValues, proposalProblem, sameReward } from './proposal-rules';

const proposal = {
  fee: 450000,
  productProvided: false,
  performance: { ratePer1000: 2000, cap: 60000 },
};

describe('proposalProblem', () => {
  const ok = { fee: 450000, productProvided: true, performance: null };

  it('accepts amounts inside the ranges', () => {
    expect(proposalProblem(ok, 'REELS')).toBeNull();
    expect(proposalProblem(proposal, 'CARD_NEWS')).toBeNull();
    expect(proposalProblem({ ...ok, fee: 10000 }, 'BLOG')).toBeNull();
    expect(proposalProblem({ ...ok, fee: 10000000 }, 'BLOG')).toBeNull();
  });

  it('rejects a fee outside 10,000 to 10,000,000 or off the 10,000 step', () => {
    for (const fee of [0, 5000, 455000, 10010000]) {
      expect(proposalProblem({ ...ok, fee }, 'REELS')).not.toBeNull();
    }
  });

  it('rejects a bonus on a blog', () => {
    expect(proposalProblem(proposal, 'BLOG')).not.toBeNull();
  });

  it('rejects a rate or cap outside the policy', () => {
    const withPerf = (ratePer1000: number, cap: number) =>
      proposalProblem({ ...ok, performance: { ratePer1000, cap } }, 'REELS');
    expect(withPerf(1000, 10000)).toBeNull();
    expect(withPerf(5000, 300000)).toBeNull();
    expect(withPerf(500, 60000)).not.toBeNull();
    expect(withPerf(5500, 60000)).not.toBeNull();
    expect(withPerf(2200, 60000)).not.toBeNull();
    expect(withPerf(2000, 5000)).not.toBeNull();
    expect(withPerf(2000, 310000)).not.toBeNull();
    expect(withPerf(2000, 65000)).not.toBeNull();
  });
});

const latest = {
  version: 1,
  title: '아침 한 컵',
  fee: 300000,
  startDate: new Date('2026-11-20T00:00:00Z'),
  format: 'REELS',
  pieces: 2,
  productProvided: true,
  revisionScope: 'GUIDE_1',
  usageRights: 'ADS_TOO',
  payoutDays: 14,
  perfRatePerThousand: null,
  perfCap: null,
} as unknown as TermsVersion;

describe('sameReward', () => {
  it('is true only when money, benefit and performance all match the latest version', () => {
    const same = { fee: 300000, productProvided: true, performance: null };
    expect(sameReward(latest, same)).toBe(true);
    expect(sameReward(latest, { ...same, fee: 310000 })).toBe(false);
    expect(sameReward(latest, { ...same, productProvided: false })).toBe(false);
    expect(
      sameReward(latest, { ...same, performance: proposal.performance }),
    ).toBe(false);
    const withPerf = {
      ...latest,
      perfRatePerThousand: 2000,
      perfCap: 60000,
    } as TermsVersion;
    expect(
      sameReward(withPerf, { ...same, performance: proposal.performance }),
    ).toBe(true);
    expect(
      sameReward(withPerf, {
        ...same,
        performance: { ratePer1000: 2000, cap: 70000 },
      }),
    ).toBe(false);
  });
});

describe('nextTermsValues', () => {
  const now = new Date('2026-11-11T03:00:00Z');

  it('changes only money and benefit and carries every other item over', () => {
    const next = nextTermsValues(latest, proposal, 'BRAND', now);
    expect(next).toMatchObject({
      title: '아침 한 컵',
      fee: 450000,
      productProvided: false,
      perfRatePerThousand: 2000,
      perfCap: 60000,
      startDate: latest.startDate,
      format: 'REELS',
      pieces: 2,
      revisionScope: 'GUIDE_1',
      usageRights: 'ADS_TOO',
      payoutDays: 14,
    });
  });

  it('marks only the proposer as confirmed', () => {
    expect(nextTermsValues(latest, proposal, 'BRAND', now)).toMatchObject({
      brandConfirmedAt: now,
      creatorConfirmedAt: null,
    });
    expect(nextTermsValues(latest, proposal, 'CREATOR', now)).toMatchObject({
      brandConfirmedAt: null,
      creatorConfirmedAt: now,
    });
  });

  it('drops the performance bonus when the proposal has none', () => {
    const next = nextTermsValues(
      latest,
      { fee: 300000, productProvided: true, performance: null },
      'CREATOR',
      now,
    );
    expect(next.perfRatePerThousand).toBeNull();
    expect(next.perfCap).toBeNull();
  });
});
