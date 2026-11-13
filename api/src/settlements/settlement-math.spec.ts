import {
  feeFor,
  MAX_MULTIPLIER_TENTHS,
  multiplierTenthsOf,
  pickFinalViews,
  settleReward,
} from './settlement-math';

describe('feeFor', () => {
  it('charges a 10 percent fee rounded down', () => {
    expect(feeFor(100000, 10)).toBe(10000);
    expect(feeFor(33333, 10)).toBe(3333);
  });

  it('charges nothing for a zero amount or a zero rate', () => {
    expect(feeFor(0, 10)).toBe(0);
    expect(feeFor(100000, 0)).toBe(0);
  });
});

describe('settleReward', () => {
  it('pays 25000 for 12500 views at 2000 won per thousand', () => {
    expect(
      settleReward({
        views: 12500,
        ratePerThousand: 2000,
        cap: 60000,
        fixedCash: 0,
      }),
    ).toEqual({
      viewPay: 25000,
      payout: 25000,
      refund: 35000,
      capApplied: false,
    });
  });

  it('rounds the view pay down', () => {
    expect(
      settleReward({
        views: 1,
        ratePerThousand: 2000,
        cap: 60000,
        fixedCash: 0,
      }).viewPay,
    ).toBe(2);
    expect(
      settleReward({
        views: 499,
        ratePerThousand: 1500,
        cap: 60000,
        fixedCash: 0,
      }).viewPay,
    ).toBe(748);
  });

  it('caps the view pay and marks the cap as applied', () => {
    expect(
      settleReward({
        views: 40000,
        ratePerThousand: 2000,
        cap: 60000,
        fixedCash: 0,
      }),
    ).toEqual({ viewPay: 60000, payout: 60000, refund: 0, capApplied: true });
    // 딱 상한이면 상한에 걸린 것이 아니다.
    expect(
      settleReward({
        views: 30000,
        ratePerThousand: 2000,
        cap: 60000,
        fixedCash: 0,
      }).capApplied,
    ).toBe(false);
  });

  it('pays only fixed cash and refunds the whole cap for zero views', () => {
    expect(
      settleReward({
        views: 0,
        ratePerThousand: 2000,
        cap: 60000,
        fixedCash: 30000,
      }),
    ).toEqual({ viewPay: 0, payout: 30000, refund: 60000, capApplied: false });
  });

  it('adds fixed cash on top of the view pay and never refunds it', () => {
    expect(
      settleReward({
        views: 12500,
        ratePerThousand: 2000,
        cap: 60000,
        fixedCash: 30000,
      }),
    ).toEqual({
      viewPay: 25000,
      payout: 55000,
      refund: 35000,
      capApplied: false,
    });
  });

  it('matches the old per-view calculation for every legacy collaboration shape', () => {
    for (let i = 0; i < 200; i += 1) {
      const views = Math.round((i * 250000) / 199);
      // 옛 계산: 조회수 × 건당 10원, 상한 10만 원까지 지급하고 남은 상한을 환급한다.
      const payout = Math.min(views * 10, 100000);
      const old = { payout, refund: 100000 - payout };
      const next = settleReward({
        views,
        ratePerThousand: 10000,
        cap: 100000,
        fixedCash: 0,
      });
      expect({ payout: next.payout, refund: next.refund }).toEqual(old);
    }
  });

  it('never pays or refunds more than fixed cash plus cap in total', () => {
    for (const fixedCash of [0, 30000, 1000000]) {
      for (let views = 0; views <= 250000; views += 997) {
        const r = settleReward({
          views,
          ratePerThousand: 2000,
          cap: 60000,
          fixedCash,
        });
        expect(r.payout + r.refund).toBe(fixedCash + 60000);
      }
    }
  });

  it('rejects negative or fractional inputs', () => {
    const ok = { views: 100, ratePerThousand: 2000, cap: 60000, fixedCash: 0 };
    expect(() => settleReward({ ...ok, views: -1 })).toThrow();
    expect(() => settleReward({ ...ok, views: 1.5 })).toThrow();
    expect(() => settleReward({ ...ok, ratePerThousand: -1 })).toThrow();
    expect(() => settleReward({ ...ok, ratePerThousand: 1.5 })).toThrow();
    expect(() => settleReward({ ...ok, cap: -1 })).toThrow();
    expect(() => settleReward({ ...ok, fixedCash: 0.5 })).toThrow();
  });
});

describe('multiplierTenthsOf', () => {
  it('rounds the multiplier down to one decimal place', () => {
    expect(multiplierTenthsOf(12500, 4000)).toBe(31);
    expect(multiplierTenthsOf(7999, 4000)).toBe(19);
    expect(multiplierTenthsOf(0, 4000)).toBe(0);
  });

  it('gives no multiplier when the usual views are zero or less', () => {
    expect(multiplierTenthsOf(12500, 0)).toBeNull();
    expect(multiplierTenthsOf(12500, -1)).toBeNull();
  });

  it('caps the multiplier so it always fits the 32-bit integer column', () => {
    expect(MAX_MULTIPLIER_TENTHS).toBe(9999);
    // 평소 1회, 이번 2억 회: 계산값 2,000,000,000은 int32 안이지만 상한(9999)을 넘는다.
    expect(multiplierTenthsOf(200_000_000, 1)).toBe(9999);
    // 평소 1회, 이번 3억 회: 계산값 3,000,000,000이 int32(2,147,483,647)를 넘는다.
    expect(multiplierTenthsOf(300_000_000, 1)).toBe(9999);
    expect(multiplierTenthsOf(999_900, 1000)).toBe(9999);
    expect(multiplierTenthsOf(999_800, 1000)).toBe(9998);
    expect(multiplierTenthsOf(1_000_000, 1000)).toBe(9999);
  });
});

describe('pickFinalViews', () => {
  it('takes the last day value when it was read', () => {
    expect(
      pickFinalViews(
        [
          { dayIndex: 6, views: 100 },
          { dayIndex: 7, views: 200 },
        ],
        7,
      ),
    ).toBe(200);
  });

  it('falls back to the latest readable day when the last day was not read', () => {
    expect(
      pickFinalViews(
        [
          { dayIndex: 4, views: 100 },
          { dayIndex: 6, views: 300 },
          { dayIndex: 7, views: null },
        ],
        7,
      ),
    ).toBe(300);
  });

  it('returns null when nothing was read', () => {
    expect(pickFinalViews([{ dayIndex: 7, views: null }], 7)).toBeNull();
    expect(pickFinalViews([], 7)).toBeNull();
  });

  it('follows a longer counting period', () => {
    expect(
      pickFinalViews(
        [
          { dayIndex: 7, views: 200 },
          { dayIndex: 14, views: 900 },
        ],
        14,
      ),
    ).toBe(900);
  });
});
