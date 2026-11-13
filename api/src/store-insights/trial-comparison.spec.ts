import { compareTrial } from './trial-comparison';

const trial = { monthlyFee: 120000, postCount: 9 };
const collab = (
  payout: number,
  fee: number,
  format: 'REELS' | 'SHORTS' | 'CARD_NEWS' | 'BLOG' = 'REELS',
  multiplierTenths: number | null = null,
) => ({ payout, fee, format, multiplierTenths });

describe('compareTrial', () => {
  it('sums three months of trial fees and the cora payouts plus fees', () => {
    const result = compareTrial({
      trial,
      collaborations: [
        collab(30000, 8000),
        collab(25000, 8000),
        collab(35000, 8000),
        collab(30000, 8000),
      ],
    });
    expect(result.trialSpent).toBe(360000);
    expect(result.coraSpent).toBe(152000);
    expect(result.coraCount).toBe(4);
  });

  it('counts submitted content by format', () => {
    const result = compareTrial({
      trial,
      collaborations: [
        collab(1, 0, 'REELS'),
        collab(1, 0, 'BLOG'),
        collab(1, 0, 'REELS'),
        collab(1, 0, 'SHORTS'),
      ],
    });
    // 형식 목록의 순서(쇼츠, 릴스, 카드뉴스, 블로그)로 나오고 0편인 형식은 빠진다.
    expect(result.contentByFormat).toEqual([
      { format: 'SHORTS', count: 1 },
      { format: 'REELS', count: 2 },
      { format: 'BLOG', count: 1 },
    ]);
  });

  it('averages only the collaborations that have a multiplier, rounded down', () => {
    const result = compareTrial({
      trial,
      collaborations: [
        collab(1, 0, 'REELS', 31),
        collab(1, 0, 'REELS', 22),
        collab(1, 0, 'REELS', null),
        collab(1, 0, 'REELS', 20),
      ],
    });
    // (31 + 22 + 20) / 3 = 24.33 → 24
    expect(result.averageMultiplierTenths).toBe(24);
  });

  it('leaves the average empty when no collaboration has a multiplier', () => {
    expect(
      compareTrial({ trial, collaborations: [collab(1, 0, 'REELS', null)] })
        .averageMultiplierTenths,
    ).toBeNull();
  });

  it('returns zeros for a store without cora collaborations', () => {
    expect(compareTrial({ trial, collaborations: [] })).toEqual({
      trialSpent: 360000,
      coraSpent: 0,
      coraCount: 0,
      contentByFormat: [],
      averageMultiplierTenths: null,
    });
  });
});
