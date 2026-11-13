import { OfferVersion } from '@prisma/client';
import { OfferVersionModel } from './dto/offer-version.model';
import {
  changedFields,
  daysLeftToAnswer,
  defaultsOfVersion,
  endKind,
  endStatusOf,
  isCounter,
  partyOf,
  proposalExtras,
  proposalGroup,
  turnAfter,
  versionModelOf,
} from './proposal-rules';
import type { ProposalOfferState } from './proposal-rules';

const T0 = new Date('2026-12-01T00:00:00.000Z');
const DAY = 24 * 60 * 60 * 1000;

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

describe('endStatusOf', () => {
  it('cancels when the writer of the latest version ends it and declines when the receiver does', () => {
    // 차례(turn)는 받은 쪽이다.
    expect(endStatusOf('STORE', 'STORE')).toBe('DECLINED');
    expect(endStatusOf('CREATOR', 'STORE')).toBe('CANCELLED');
    expect(endStatusOf('CREATOR', 'CREATOR')).toBe('DECLINED');
    expect(endStatusOf('STORE', 'CREATOR')).toBe('CANCELLED');
  });
});

describe('proposalExtras', () => {
  it('keeps the idea and principles only for the creator', () => {
    const input = { idea: ' 내 방식 ', principles: ['광고 티 안 내기'] };
    expect(proposalExtras('CREATOR', input)).toEqual({
      idea: '내 방식',
      principles: ['광고 티 안 내기'],
      series: null,
    });
    expect(proposalExtras('STORE', input)).toEqual({
      idea: null,
      principles: [],
      series: null,
    });
  });

  it('copies the series only for the creator', () => {
    const series = {
      name: '오늘의 한 컵',
      format: 'REELS',
      note: '아침',
    } as const;
    expect(proposalExtras('CREATOR', {}, series).series).toEqual(series);
    expect(proposalExtras('STORE', {}, series).series).toBeNull();
  });

  it('stores an empty idea as null', () => {
    expect(proposalExtras('CREATOR', { idea: '  ' })).toEqual({
      idea: null,
      principles: [],
      series: null,
    });
  });
});

describe('defaultsOfVersion', () => {
  it('fills blanks from the previous version terms', () => {
    const row = {
      voucherName: '식사권',
      voucherValue: 40000,
      voucherPeople: 2,
      viewRatePerThousand: 3000,
      perViewCap: 90000,
      usageRights: 'STORE_REPOST_6M',
    } as OfferVersion;
    expect(defaultsOfVersion(row)).toEqual({
      voucherName: '식사권',
      voucherValue: 40000,
      voucherPeople: 2,
      viewRatePerThousand: 3000,
      perViewCap: 90000,
      usageRights: 'STORE_REPOST_6M',
    });
  });
});

describe('proposalGroup', () => {
  const offer = (
    over: Partial<ProposalOfferState> = {},
  ): ProposalOfferState => ({
    status: 'SENT',
    turn: 'CREATOR',
    expiresAt: new Date(T0.getTime() + 3 * DAY),
    paymentDueAt: null,
    declinedAt: null,
    ...over,
  });

  it('groups an offer by whose turn it is', () => {
    expect(proposalGroup(offer({ turn: 'CREATOR' }), 'CREATOR', T0)).toBe(
      'MY_TURN',
    );
    expect(proposalGroup(offer({ turn: 'CREATOR' }), 'STORE', T0)).toBe(
      'WAITING',
    );
    expect(proposalGroup(offer({ turn: 'STORE' }), 'STORE', T0)).toBe(
      'MY_TURN',
    );
  });

  it('puts accepted, declined, cancelled and expired offers in the ended group', () => {
    for (const status of ['ACCEPTED', 'DECLINED', 'CANCELLED'] as const) {
      expect(proposalGroup(offer({ status }), 'CREATOR', T0)).toBe('ENDED');
      expect(proposalGroup(offer({ status }), 'STORE', T0)).toBe('ENDED');
    }
    expect(proposalGroup(offer({ status: 'EXPIRED' }), 'STORE', T0)).toBe(
      'ENDED',
    );
  });

  it('treats an unanswered offer past its deadline as ended even before it is stored', () => {
    const late = offer({ expiresAt: new Date(T0.getTime() - 1) });
    expect(proposalGroup(late, 'CREATOR', T0)).toBe('ENDED');
    expect(endKind(late, T0)).toBe('EXPIRED');
  });

  it('keeps a decline waiting for the store until the creator can no longer undo it', () => {
    const declined = offer({
      status: 'DECLINED',
      declinedAt: new Date(T0.getTime() - 10 * 1000),
    });
    expect(proposalGroup(declined, 'STORE', T0)).toBe('WAITING');
    expect(proposalGroup(declined, 'CREATOR', T0)).toBe('ENDED');
    const later = new Date(T0.getTime() + 25 * 1000);
    expect(proposalGroup(declined, 'STORE', later)).toBe('ENDED');
  });
});

describe('endKind', () => {
  const base = {
    turn: 'CREATOR' as const,
    expiresAt: new Date(T0.getTime() + DAY),
    paymentDueAt: null,
    declinedAt: null,
  };

  it('calls an accepted offer agreed and a chosen end ended', () => {
    expect(endKind({ ...base, status: 'ACCEPTED' }, T0)).toBe('AGREED');
    expect(endKind({ ...base, status: 'DECLINED' }, T0)).toBe('ENDED');
    expect(endKind({ ...base, status: 'CANCELLED' }, T0)).toBe('ENDED');
    expect(endKind({ ...base, status: 'EXPIRED' }, T0)).toBe('EXPIRED');
  });

  it('is null while the offer is still open', () => {
    expect(endKind({ ...base, status: 'SENT' }, T0)).toBeNull();
  });

  it('calls an accepted offer whose payment time ran out expired', () => {
    const unpaid = {
      ...base,
      status: 'ACCEPTED' as const,
      paymentDueAt: new Date(T0.getTime() - 1),
    };
    expect(endKind(unpaid, T0)).toBe('EXPIRED');
  });
});

describe('daysLeftToAnswer', () => {
  it('counts the days left, rounding up', () => {
    expect(daysLeftToAnswer(new Date(T0.getTime() + 2 * DAY), T0)).toBe(2);
    expect(daysLeftToAnswer(new Date(T0.getTime() + 2 * DAY + 1000), T0)).toBe(
      3,
    );
    expect(daysLeftToAnswer(new Date(T0.getTime() + DAY), T0)).toBe(1);
  });

  it('is zero for less than a day and for a deadline already passed', () => {
    expect(daysLeftToAnswer(new Date(T0.getTime() + DAY - 1), T0)).toBe(0);
    expect(daysLeftToAnswer(new Date(T0.getTime() - DAY), T0)).toBe(0);
  });
});

describe('isCounter', () => {
  it('is a counter proposal when the other party wrote version 2 or later', () => {
    expect(isCounter({ number: 2, authorParty: 'CREATOR' }, 'STORE')).toBe(
      true,
    );
    expect(isCounter({ number: 3, authorParty: 'STORE' }, 'CREATOR')).toBe(
      true,
    );
  });

  it('is not one for my own version or the first version', () => {
    expect(isCounter({ number: 2, authorParty: 'CREATOR' }, 'CREATOR')).toBe(
      false,
    );
    expect(isCounter({ number: 1, authorParty: 'STORE' }, 'CREATOR')).toBe(
      false,
    );
  });
});
