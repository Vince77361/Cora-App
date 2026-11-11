import { feeFor, settle } from './settlement-math';

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

describe('settle', () => {
  it('pays views times unit up to the cap', () => {
    expect(settle({ views: 4320, perViewAmount: 10, cap: 100000 })).toEqual({
      payout: 43200,
      refund: 56800,
    });
  });

  it('pays nothing and refunds everything for zero views', () => {
    expect(settle({ views: 0, perViewAmount: 10, cap: 100000 })).toEqual({
      payout: 0,
      refund: 100000,
    });
  });

  it('caps the payout and refunds nothing when views exceed the cap', () => {
    expect(settle({ views: 250000, perViewAmount: 10, cap: 100000 })).toEqual({
      payout: 100000,
      refund: 0,
    });
  });

  it('pays exactly the cap when views times unit equals it', () => {
    expect(settle({ views: 10000, perViewAmount: 10, cap: 100000 })).toEqual({
      payout: 100000,
      refund: 0,
    });
  });

  it('rejects negative or fractional views', () => {
    expect(() =>
      settle({ views: -1, perViewAmount: 10, cap: 100000 }),
    ).toThrow();
    expect(() =>
      settle({ views: 1.5, perViewAmount: 10, cap: 100000 }),
    ).toThrow();
    expect(() =>
      settle({ views: NaN, perViewAmount: 10, cap: 100000 }),
    ).toThrow();
  });
});
