import { draftTerms } from './draft-terms';

const campaign = {
  headline: '나만의 아침 루틴 속 작은 포인트',
  fee: 300000,
  startFrom: new Date('2026-11-20T00:00:00.000Z'),
  format: 'REELS' as const,
  productProvided: true,
};
const creator = { cardHeadline: '하루 한 컵의 기록' };

describe('draftTerms', () => {
  it('drafts version 1 from the campaign with the documented defaults', () => {
    expect(draftTerms(campaign, creator, null, null)).toEqual({
      proposedById: null,
      title: '나만의 아침 루틴 속 작은 포인트',
      fee: 300000,
      startDate: new Date('2026-11-20T00:00:00.000Z'),
      format: 'REELS',
      pieces: 1,
      productProvided: true,
      revisionScope: 'GUIDE_1',
      usageRights: 'REPOST_ONLY',
      payoutDays: 7,
      perfRatePerThousand: null,
      perfCap: null,
      brandConfirmedAt: null,
      creatorConfirmedAt: null,
    });
  });

  it('uses the creator note as the title when present', () => {
    expect(
      draftTerms(campaign, creator, '  출근길 한 컵 이야기 ', null).title,
    ).toBe('출근길 한 컵 이야기');
  });

  it('falls back to the campaign headline for a blank note', () => {
    expect(draftTerms(campaign, creator, '   ', null).title).toBe(
      campaign.headline,
    );
  });

  it('takes money and benefit from the brand proposal and leaves the rest as defaults', () => {
    const terms = draftTerms(campaign, creator, null, {
      fee: 450000,
      productProvided: false,
      performance: { ratePer1000: 2000, cap: 60000 },
    });
    expect(terms).toMatchObject({
      fee: 450000,
      productProvided: false,
      perfRatePerThousand: 2000,
      perfCap: 60000,
      pieces: 1,
      revisionScope: 'GUIDE_1',
      usageRights: 'REPOST_ONLY',
      payoutDays: 7,
    });
  });

  it('leaves version 1 without a proposer and unconfirmed by both sides even from a proposal', () => {
    const terms = draftTerms(campaign, creator, null, {
      fee: 450000,
      productProvided: true,
      performance: null,
    });
    expect(terms.proposedById).toBeNull();
    expect(terms.brandConfirmedAt).toBeNull();
    expect(terms.creatorConfirmedAt).toBeNull();
    expect(terms.perfRatePerThousand).toBeNull();
    expect(terms.perfCap).toBeNull();
  });
});
