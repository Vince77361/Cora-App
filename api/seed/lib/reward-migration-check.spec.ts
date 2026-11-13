import {
  AfterSnapshot,
  BeforeSnapshot,
  compareReward,
} from './reward-migration-check';

const settledLegacy = {
  id: 'c-1',
  rewardType: 'BOTH',
  voucherName: '2인 식사권',
  perViewAmount: 10,
  perViewCap: 100000,
  paidEscrow: 100000,
  settlement: { finalViews: 4320, payoutAmount: 43200, refundAmount: 56800 },
};

function before(): BeforeSnapshot {
  return {
    recordedAt: '2026-11-12T00:00:00.000Z',
    collaborations: [settledLegacy],
    offers: [
      {
        id: 'o-1',
        rewardType: 'BOTH',
        voucherName: '2인 식사권',
        voucherValue: 40000,
        perViewAmount: 10,
        perViewCap: 100000,
      },
    ],
    stores: [
      {
        id: 's-1',
        defaultRewardType: 'BOTH',
        defaultVoucherName: '2인 식사권',
        defaultVoucherValue: 40000,
      },
    ],
    counts: { payments: 1, settlements: 1 },
  };
}

function after(): AfterSnapshot {
  return {
    collaborations: [
      {
        id: 'c-1',
        terms: {
          format: 'REELS',
          pieces: 1,
          voucherName: '식사권',
          voucherValue: 40000,
          voucherPeople: 2,
          fixedCash: 0,
          viewRatePerThousand: 10000,
          perViewCap: 100000,
          usageRights: 'NONE',
        },
        paidEscrow: 100000,
        postedEscrow: 100000,
        settlement: {
          finalViews: 4320,
          payoutAmount: 43200,
          refundAmount: 56800,
        },
      },
    ],
    offers: [
      {
        id: 'o-1',
        voucherName: '식사권',
        voucherValue: 40000,
        voucherPeople: 2,
        fixedCash: 0,
        viewRatePerThousand: 10000,
        perViewCap: 100000,
        usageRights: 'NONE',
      },
    ],
    stores: [
      {
        id: 's-1',
        defaultVoucherName: '식사권',
        defaultVoucherValue: 40000,
        defaultVoucherPeople: 2,
        defaultFixedCash: 0,
        defaultViewRatePerThousand: 2000,
        defaultPerViewCap: 60000,
        defaultUsageRights: 'STORE_REPOST_3M',
      },
    ],
    counts: { payments: 1, settlements: 1 },
  };
}

describe('compareReward', () => {
  it('passes when every legacy amount is carried over', () => {
    expect(compareReward(before(), after())).toEqual({
      problems: [],
      collaborations: 1,
    });
  });

  it('reports a rate that was not multiplied by 1000', () => {
    const a = after();
    (a.collaborations[0].terms as Record<string, unknown>).viewRatePerThousand =
      10;
    const { problems } = compareReward(before(), a);
    expect(problems.join('\n')).toContain('단가가 맞지 않아요');
  });

  it('reports a rate multiplied twice', () => {
    const a = after();
    (a.collaborations[0].terms as Record<string, unknown>).viewRatePerThousand =
      10_000_000;
    expect(compareReward(before(), a).problems.length).toBeGreaterThan(0);
  });

  it('reports a changed settlement, escrow or row count', () => {
    const a = after();
    a.collaborations[0].settlement = {
      finalViews: 4320,
      payoutAmount: 43201,
      refundAmount: 56799,
    };
    a.collaborations[0].paidEscrow = 99999;
    a.counts.payments = 2;
    const text = compareReward(before(), a).problems.join('\n');
    expect(text).toContain('정산 값이 달라졌어요');
    expect(text).toContain('결제 보관액이 달라졌어요');
    expect(text).toContain('payments 행 수가 달라졌어요');
  });

  it('reports a legacy key left in the copy', () => {
    const a = after();
    (a.collaborations[0].terms as Record<string, unknown>).perViewAmount = 10;
    expect(compareReward(before(), a).problems.join('\n')).toContain('옛 키');
  });

  it('accepts a voucher only collaboration with no rate and cap', () => {
    const b = before();
    b.collaborations = [
      {
        id: 'c-2',
        rewardType: 'VOUCHER',
        voucherName: '커피 2잔',
        perViewAmount: null,
        perViewCap: null,
        paidEscrow: null,
        settlement: null,
      },
    ];
    const a = after();
    a.collaborations = [
      {
        id: 'c-2',
        terms: {
          format: 'SHORTS',
          pieces: 1,
          voucherName: '커피 2잔',
          voucherValue: 9000,
          voucherPeople: null,
          fixedCash: 0,
          viewRatePerThousand: null,
          perViewCap: null,
          usageRights: 'NONE',
        },
        paidEscrow: null,
        postedEscrow: null,
        settlement: null,
      },
    ];
    expect(compareReward(b, a)).toEqual({ problems: [], collaborations: 1 });
  });

  it('reports an offer or store whose values differ from the migration rule', () => {
    const a = after();
    a.offers[0].viewRatePerThousand = 2000;
    a.stores[0].defaultPerViewCap = 100000;
    const text = compareReward(before(), a).problems.join('\n');
    expect(text).toContain('오퍼 o-1');
    expect(text).toContain('가게 s-1');
  });
});
