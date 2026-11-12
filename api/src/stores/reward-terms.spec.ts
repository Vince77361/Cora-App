import { AppError } from '../common/errors/app-error';
import {
  buildReward,
  fromLegacyTerms,
  hasViewPay,
  maxCashBurden,
  settlementMethodOfReward,
} from './reward-terms';

const store = { format: 'REELS' as const };

describe('buildReward', () => {
  it('fills the store defaults when the view pay values are omitted', () => {
    const r = buildReward({ perView: {} }, store);
    expect(r.viewRatePerThousand).toBe(2000);
    expect(r.perViewCap).toBe(60000);
    expect(r.fixedCash).toBe(0);
  });

  it('prefers the store recruit defaults over the policy defaults', () => {
    const r = buildReward(
      { perView: {} },
      {
        ...store,
        defaults: { viewRatePerThousand: 3000, perViewCap: 100000 },
      },
    );
    expect(r.viewRatePerThousand).toBe(3000);
    expect(r.perViewCap).toBe(100000);
  });

  it('fills the voucher defaults and trims a given name', () => {
    expect(buildReward({ voucher: {} }, store)).toMatchObject({
      voucherName: '식사권',
      voucherValue: 40000,
      voucherPeople: 2,
    });
    expect(
      buildReward(
        { voucher: { name: '  커피  ', value: 9000, people: 1 } },
        store,
      ),
    ).toMatchObject({
      voucherName: '커피',
      voucherValue: 9000,
      voucherPeople: 1,
    });
  });

  it('treats a null voucher or per view as absent', () => {
    const r = buildReward(
      { voucher: null, perView: null, fixedCash: 30000 },
      store,
    );
    expect(r).toEqual({
      voucherName: null,
      voucherValue: null,
      voucherPeople: null,
      fixedCash: 30000,
      viewRatePerThousand: null,
      perViewCap: null,
    });
  });

  it('adds fixed cash and the view pay cap into the maximum cash burden', () => {
    const r = buildReward({ fixedCash: 30000, perView: {} }, store);
    expect(maxCashBurden(r)).toBe(90000);
  });

  it('reports zero burden for a voucher only reward', () => {
    const r = buildReward({ voucher: {} }, store);
    expect(maxCashBurden(r)).toBe(0);
    expect(hasViewPay(r)).toBe(false);
  });

  it('names the settlement method from the two amounts', () => {
    const none = buildReward({ voucher: {} }, store);
    const fixed = buildReward({ fixedCash: 30000 }, store);
    const perView = buildReward({ perView: {} }, store);
    const both = buildReward({ fixedCash: 30000, perView: {} }, store);
    expect(settlementMethodOfReward(none)).toBe('NONE');
    expect(settlementMethodOfReward(fixed)).toBe('FIXED');
    expect(settlementMethodOfReward(perView)).toBe('PER_VIEW');
    expect(settlementMethodOfReward(both)).toBe('FIXED_AND_PER_VIEW');
    expect(hasViewPay(both)).toBe(true);
  });

  it('rejects view pay for a blog post with the existing wording', () => {
    expect(() => buildReward({ perView: {} }, { format: 'BLOG' })).toThrow(
      new AppError('VALIDATION_FAILED', '블로그 글은 조회수를 셀 수 없어요.'),
    );
    // 고정 현금과 식사권은 블로그 글에도 쓸 수 있다.
    expect(() =>
      buildReward({ voucher: {}, fixedCash: 30000 }, { format: 'BLOG' }),
    ).not.toThrow();
  });

  it('rejects a rate off the 500 won step or outside 1000 to 5000', () => {
    for (const ratePerThousand of [999, 1250, 500, 5500, 0]) {
      expect(() =>
        buildReward({ perView: { ratePerThousand } }, store),
      ).toThrow(AppError);
    }
    for (const ratePerThousand of [1000, 1500, 5000]) {
      expect(() =>
        buildReward({ perView: { ratePerThousand } }, store),
      ).not.toThrow();
    }
  });

  it('rejects a cap off the 10000 won step or outside 10000 to 300000', () => {
    for (const cap of [0, 5000, 15000, 310000, 60001]) {
      expect(() => buildReward({ perView: { cap } }, store)).toThrow(AppError);
    }
    for (const cap of [10000, 60000, 300000]) {
      expect(() => buildReward({ perView: { cap } }, store)).not.toThrow();
    }
  });

  it('rejects fixed cash above one million for a store or off the 10000 won step', () => {
    expect(() => buildReward({ fixedCash: 1010000 }, store)).toThrow(AppError);
    expect(() => buildReward({ fixedCash: 35000 }, store)).toThrow(AppError);
    expect(() =>
      buildReward({ fixedCash: -10000, voucher: {} }, store),
    ).toThrow(AppError);
    expect(() => buildReward({ fixedCash: 1000000 }, store)).not.toThrow();
  });

  it('allows fixed cash up to ten million for a brand', () => {
    expect(
      buildReward({ fixedCash: 10000000 }, { ...store, commissioner: 'BRAND' })
        .fixedCash,
    ).toBe(10000000);
    expect(() =>
      buildReward({ fixedCash: 10010000 }, { ...store, commissioner: 'BRAND' }),
    ).toThrow(AppError);
  });

  it('rejects a reward with no element', () => {
    expect(() => buildReward({}, store)).toThrow(
      new AppError('VALIDATION_FAILED', '보상을 하나 이상 정해 주세요.'),
    );
    expect(() =>
      buildReward({ voucher: null, fixedCash: 0, perView: null }, store),
    ).toThrow('보상을 하나 이상 정해 주세요.');
  });

  it('rejects a voucher with an unusable value or head count', () => {
    expect(() => buildReward({ voucher: { value: 500 } }, store)).toThrow(
      AppError,
    );
    expect(() => buildReward({ voucher: { people: 0 } }, store)).toThrow(
      AppError,
    );
    expect(() => buildReward({ voucher: { people: 11 } }, store)).toThrow(
      AppError,
    );
  });
});

describe('fromLegacyTerms', () => {
  it('converts a legacy copy to 10000 won per thousand without range checks', () => {
    const r = fromLegacyTerms({
      rewardType: 'PER_VIEW',
      voucherName: null,
      voucherValue: null,
      perViewAmount: 10,
      perViewCap: 100000,
    });
    expect(r).toEqual({
      voucherName: null,
      voucherValue: null,
      voucherPeople: null,
      fixedCash: 0,
      viewRatePerThousand: 10000,
      perViewCap: 100000,
    });
    // 단가 10000은 새 범위(1000~5000)를 벗어나지만 옛 협업은 그대로 읽는다.
    expect(maxCashBurden(r)).toBe(100000);
  });

  it('turns the legacy default voucher name into name plus two people', () => {
    const r = fromLegacyTerms({
      rewardType: 'VOUCHER',
      voucherName: '2인 식사권',
      voucherValue: 40000,
      perViewAmount: null,
      perViewCap: null,
    });
    expect(r).toMatchObject({
      voucherName: '식사권',
      voucherPeople: 2,
      voucherValue: 40000,
      viewRatePerThousand: null,
      perViewCap: null,
    });
  });

  it('keeps a custom legacy voucher name and leaves people empty', () => {
    const r = fromLegacyTerms({
      rewardType: 'BOTH',
      voucherName: '커피 2잔',
      voucherValue: 9000,
      perViewAmount: 10,
      perViewCap: 100000,
    });
    expect(r).toMatchObject({
      voucherName: '커피 2잔',
      voucherPeople: null,
      voucherValue: 9000,
      viewRatePerThousand: 10000,
    });
  });
});
