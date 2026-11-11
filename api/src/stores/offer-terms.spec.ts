import { AppError } from '../common/errors/app-error';
import { buildTerms } from './offer-terms';

describe('buildTerms', () => {
  it('fills voucher defaults when a voucher reward has no name or value', () => {
    expect(buildTerms({ format: 'REELS', rewardType: 'VOUCHER' })).toEqual({
      format: 'REELS',
      rewardType: 'VOUCHER',
      voucherName: '2인 식사권',
      voucherValue: 40000,
      perViewAmount: null,
      perViewCap: null,
    });
    // 공백뿐인 이름도 비어 있는 것으로 본다.
    expect(
      buildTerms({
        format: 'REELS',
        rewardType: 'BOTH',
        voucherName: '  ',
      }).voucherName,
    ).toBe('2인 식사권');
  });

  it('keeps a given voucher name and value', () => {
    const terms = buildTerms({
      format: 'SHORTS',
      rewardType: 'VOUCHER',
      voucherName: '커피 2잔',
      voucherValue: 9000,
    });
    expect(terms.voucherName).toBe('커피 2잔');
    expect(terms.voucherValue).toBe(9000);
  });

  it('drops voucher fields for a per-view reward', () => {
    expect(
      buildTerms({
        format: 'SHORTS',
        rewardType: 'PER_VIEW',
        voucherName: '커피 2잔',
        voucherValue: 9000,
      }),
    ).toEqual({
      format: 'SHORTS',
      rewardType: 'PER_VIEW',
      voucherName: null,
      voucherValue: null,
      perViewAmount: 10,
      perViewCap: 100000,
    });
  });

  it('always uses 10 won per view capped at 100000', () => {
    for (const rewardType of ['PER_VIEW', 'BOTH'] as const) {
      const terms = buildTerms({ format: 'REELS', rewardType });
      expect(terms.perViewAmount).toBe(10);
      expect(terms.perViewCap).toBe(100000);
    }
    const voucherOnly = buildTerms({ format: 'REELS', rewardType: 'VOUCHER' });
    expect(voucherOnly.perViewAmount).toBeNull();
    expect(voucherOnly.perViewCap).toBeNull();
  });

  it('rejects blog with a per-view reward', () => {
    for (const rewardType of ['PER_VIEW', 'BOTH'] as const) {
      try {
        buildTerms({ format: 'BLOG', rewardType });
        throw new Error('should have thrown');
      } catch (e) {
        expect(e).toBeInstanceOf(AppError);
        expect((e as AppError).code).toBe('VALIDATION_FAILED');
        expect((e as AppError).message).toBe(
          '블로그 글은 조회수를 셀 수 없어요.',
        );
      }
    }
  });

  it('allows blog with a voucher reward', () => {
    expect(buildTerms({ format: 'BLOG', rewardType: 'VOUCHER' }).format).toBe(
      'BLOG',
    );
  });
});
