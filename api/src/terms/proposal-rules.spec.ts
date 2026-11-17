import type { TermsVersion } from '@prisma/client';
import {
  nextTermsValues,
  proposalProblem,
  termsProblem,
} from './proposal-rules';

const proposalEdit = {
  fee: 450000,
  productProvided: false,
  performance: { ratePer1000: 2000, cap: 60000 },
};
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

describe('nextTermsValues', () => {
  const now = new Date('2026-11-11T03:00:00Z');
  const withBonus = {
    ...latest,
    perfRatePerThousand: 2000,
    perfCap: 60000,
  } as TermsVersion;

  it('changes only money and benefit and carries every other item over', () => {
    const next = nextTermsValues(latest, proposalEdit, 'BRAND', now);
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
    expect(nextTermsValues(latest, proposalEdit, 'BRAND', now)).toMatchObject({
      brandConfirmedAt: now,
      creatorConfirmedAt: null,
    });
    expect(nextTermsValues(latest, proposalEdit, 'CREATOR', now)).toMatchObject(
      {
        brandConfirmedAt: null,
        creatorConfirmedAt: now,
      },
    );
  });

  it('drops the performance bonus when the edit sets it to null', () => {
    const next = nextTermsValues(
      withBonus,
      { performance: null },
      'CREATOR',
      now,
    );
    expect(next.perfRatePerThousand).toBeNull();
    expect(next.perfCap).toBeNull();
  });

  it('keeps the performance bonus when the edit leaves it out', () => {
    const next = nextTermsValues(withBonus, { fee: 320000 }, 'BRAND', now);
    expect(next).toMatchObject({
      fee: 320000,
      perfRatePerThousand: 2000,
      perfCap: 60000,
    });
  });

  it('overlays every editable item and keeps the date as a date-only value', () => {
    const next = nextTermsValues(
      latest,
      {
        title: '새 제목',
        startDate: '2026-12-01',
        format: 'SHORTS',
        pieces: 3,
        revisionScope: 'DRAFT_2',
        usageRights: 'NONE',
        payoutDays: 7,
      },
      'BRAND',
      now,
    );
    expect(next).toMatchObject({
      title: '새 제목',
      fee: 300000,
      startDate: new Date('2026-12-01T00:00:00.000Z'),
      format: 'SHORTS',
      pieces: 3,
      productProvided: true,
      revisionScope: 'DRAFT_2',
      usageRights: 'NONE',
      payoutDays: 7,
    });
  });
});

describe('termsProblem', () => {
  const ok = {
    title: '아침 한 컵',
    fee: 300000,
    format: 'REELS' as const,
    pieces: 1,
    payoutDays: 7,
    perfRatePerThousand: null,
    perfCap: null,
    productProvided: true,
  };
  const today = '2026-11-11';

  it('accepts a valid whole version', () => {
    expect(termsProblem(ok, undefined, today)).toBeNull();
    expect(termsProblem(ok, '2026-11-11', today)).toBeNull();
    expect(
      termsProblem({ ...ok, payoutDays: 14, pieces: 3 }, '2027-01-01', today),
    ).toBeNull();
  });

  it('rejects a title outside 1 to 40 characters', () => {
    expect(
      termsProblem({ ...ok, title: '  ' }, undefined, today),
    ).not.toBeNull();
    expect(
      termsProblem({ ...ok, title: 'ㄱ'.repeat(41) }, undefined, today),
    ).not.toBeNull();
    expect(
      termsProblem({ ...ok, title: 'ㄱ'.repeat(40) }, undefined, today),
    ).toBeNull();
  });

  it('rejects pieces outside 1 to 3 and a payout that is not 7 or 14 days', () => {
    expect(termsProblem({ ...ok, pieces: 0 }, undefined, today)).not.toBeNull();
    expect(termsProblem({ ...ok, pieces: 4 }, undefined, today)).not.toBeNull();
    expect(
      termsProblem({ ...ok, payoutDays: 10 }, undefined, today),
    ).not.toBeNull();
  });

  it('rejects a changed start date before today but not an unchanged one', () => {
    expect(termsProblem(ok, '2026-11-10', today)).not.toBeNull();
    expect(termsProblem(ok, undefined, today)).toBeNull();
  });

  it('rejects a performance bonus left on a blog post with the blog message', () => {
    expect(
      termsProblem(
        { ...ok, format: 'BLOG', perfRatePerThousand: 2000, perfCap: 60000 },
        undefined,
        today,
      ),
    ).toBe('블로그 글은 조회수를 셀 수 없어요.');
  });

  it('applies the fee and performance ranges', () => {
    expect(
      termsProblem({ ...ok, fee: 455000 }, undefined, today),
    ).not.toBeNull();
    expect(
      termsProblem(
        { ...ok, perfRatePerThousand: 500, perfCap: 60000 },
        undefined,
        today,
      ),
    ).not.toBeNull();
  });
});
