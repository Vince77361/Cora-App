import { OfferVersion } from '@prisma/client';
import { OfferVersionModel } from './dto/offer-version.model';
import {
  changedFields,
  partyOf,
  turnAfter,
  versionModelOf,
} from './proposal-rules';

const T0 = new Date('2026-12-01T00:00:00.000Z');

function version(over: Partial<OfferVersionModel> = {}): OfferVersionModel {
  return {
    number: 1,
    authorParty: 'STORE',
    terms: {
      format: 'REELS',
      pieces: 1,
      voucherName: '식사권',
      voucherValue: 40000,
      voucherPeople: 2,
      fixedCash: 0,
      viewRatePerThousand: 2000,
      perViewCap: 60000,
      usageRights: 'STORE_REPOST_3M',
      maxCashBurden: 60000,
      settlementMethod: 'PER_VIEW',
    },
    idea: null,
    principles: [],
    series: null,
    createdAt: T0,
    ...over,
  };
}

function withTerms(
  base: OfferVersionModel,
  terms: Partial<OfferVersionModel['terms']>,
): OfferVersionModel {
  return {
    ...base,
    number: base.number + 1,
    terms: { ...base.terms, ...terms },
  };
}

describe('turnAfter', () => {
  it('gives the turn to the party that did not write the latest version', () => {
    expect(turnAfter('STORE')).toBe('CREATOR');
    expect(turnAfter('CREATOR')).toBe('STORE');
  });
});

describe('partyOf', () => {
  const offer = { creatorId: 'creator-1' };

  it('tells the store owner and the creator apart', () => {
    expect(partyOf(offer, 'owner-1', 'owner-1')).toBe('STORE');
    expect(partyOf(offer, 'creator-1', 'owner-1')).toBe('CREATOR');
  });

  it('returns null for someone who is not a party to the offer', () => {
    expect(partyOf(offer, 'stranger', 'owner-1')).toBeNull();
  });
});

describe('changedFields', () => {
  const first = version();

  it('lists nothing for the first version', () => {
    expect(changedFields(null, first)).toEqual([]);
  });

  it('lists nothing when the terms are the same', () => {
    expect(changedFields(first, { ...first, number: 2 })).toEqual([]);
  });

  it('lists the fields that changed between two versions', () => {
    const next: OfferVersionModel = {
      ...withTerms(first, {
        format: 'CARD_NEWS',
        voucherValue: 50000,
        fixedCash: 30000,
        perViewCap: 80000,
        usageRights: 'NONE',
      }),
      idea: '신메뉴 소개',
      principles: ['사진은 밝게'],
      series: { name: '월간 한 컵', format: 'REELS', note: null },
    };
    expect(changedFields(first, next)).toEqual([
      'FORMAT',
      'VOUCHER',
      'FIXED_CASH',
      'VIEW_PAY',
      'USAGE_RIGHTS',
      'IDEA',
      'PRINCIPLES',
      'SERIES',
    ]);
  });

  it('lists only the field that changed', () => {
    expect(
      changedFields(first, withTerms(first, { fixedCash: 30000 })),
    ).toEqual(['FIXED_CASH']);
    expect(
      changedFields(first, withTerms(first, { viewRatePerThousand: 3000 })),
    ).toEqual(['VIEW_PAY']);
    expect(
      changedFields(first, withTerms(first, { voucherPeople: 3 })),
    ).toEqual(['VOUCHER']);
  });

  it('compares principles in order and the series by each part', () => {
    const a = { ...first, principles: ['a', 'b'] };
    expect(changedFields(a, { ...a, principles: ['a', 'b'] })).toEqual([]);
    expect(changedFields(a, { ...a, principles: ['b', 'a'] })).toEqual([
      'PRINCIPLES',
    ]);
    const s = { ...first, series: { name: '연재', format: null, note: null } };
    expect(
      changedFields(s, { ...s, series: { ...s.series, note: '메모' } }),
    ).toEqual(['SERIES']);
    expect(changedFields(s, { ...s, series: null })).toEqual(['SERIES']);
  });
});

describe('versionModelOf', () => {
  const row: OfferVersion = {
    id: 'v-1',
    offerId: 'o-1',
    number: 2,
    authorParty: 'CREATOR',
    format: 'REELS',
    pieces: 1,
    voucherName: null,
    voucherValue: null,
    voucherPeople: null,
    fixedCash: 30000,
    viewRatePerThousand: null,
    perViewCap: null,
    usageRights: 'NONE',
    idea: null,
    principles: [],
    seriesName: null,
    seriesFormat: null,
    seriesNote: null,
    createdAt: T0,
    updatedAt: T0,
    deletedAt: null,
  };

  it('keeps database-only columns out of the terms and derives the cash values', () => {
    const model = versionModelOf(row);
    expect(model.terms).toEqual({
      format: 'REELS',
      pieces: 1,
      voucherName: null,
      voucherValue: null,
      voucherPeople: null,
      fixedCash: 30000,
      viewRatePerThousand: null,
      perViewCap: null,
      usageRights: 'NONE',
      maxCashBurden: 30000,
      settlementMethod: 'FIXED',
    });
    expect(model).toMatchObject({
      number: 2,
      authorParty: 'CREATOR',
      series: null,
    });
  });

  it('returns the series only when one of its parts is set', () => {
    expect(versionModelOf({ ...row, seriesName: '월간 한 컵' }).series).toEqual(
      { name: '월간 한 컵', format: null, note: null },
    );
  });
});
