import { feeFor, settleReward } from './settlement-math';

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
