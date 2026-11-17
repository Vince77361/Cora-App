import { Collaboration, Payout, Settlement } from '@prisma/client';
import { buildWalletEntries } from './wallet-entries';

const T0 = new Date('2026-12-01T03:00:00.000Z');

function brand(over: Partial<Collaboration> = {}): Collaboration {
  return {
    id: 'b1',
    kind: 'BRAND_CONTRACT',
    stage: 'PUBLISHED',
    commissionerId: 'brand-user',
    creatorId: 'creator-user',
    offerId: null,
    storeId: null,
    campaignId: null,
    terms: {},
    settlementMethod: 'NONE',
    fundedAt: null,
    submitDueAt: null,
    submittedUrl: null,
    submittedAt: null,
    countingEndsAt: null,
    haltedReason: null,
    stageBeforeHalt: null,
    creatorNote: null,
    dropReason: null,
    droppedById: null,
    contractedAt: T0,
    extraRevisionsAllowed: 0,
    createdAt: new Date('2026-11-20T03:00:00.000Z'),
    updatedAt: T0,
    deletedAt: null,
    ...over,
  };
}

const input = (collaborations: Collaboration[]) => ({
  collaborations,
  settlements: new Map<string, Settlement>(),
  payouts: [] as Payout[],
  escrow: new Map<string, number>(),
  names: new Map<string, string>([['b1', '느린결']]),
  brandTerms: new Map([['b1', { format: 'REELS' as const, pieces: 2 }]]),
});

describe('buildWalletEntries for a brand contract', () => {
  it('shows the held money with the contract format and piece count', () => {
    const entries = buildWalletEntries({
      ...input([brand()]),
      escrow: new Map([['b1', 410000]]),
    });
    expect(entries).toEqual([
      expect.objectContaining({
        collaborationId: 'b1',
        kind: 'HELD',
        amount: 410000,
        counterpartName: '느린결',
        format: 'REELS',
        pieces: 2,
        stage: 'PUBLISHED',
        at: T0.toISOString(),
      }),
    ]);
  });

  it('leaves out a brand collaboration without a concluded contract', () => {
    const entries = buildWalletEntries({
      ...input([brand({ stage: 'AGREED' })]),
      brandTerms: new Map(),
      escrow: new Map([['b1', 410000]]),
    });
    expect(entries).toEqual([]);
  });

  it('shows a scheduled payout once the settlement is confirmed', () => {
    const payout = {
      id: 'p1',
      collaborationId: 'b1',
      amount: 375000,
      status: 'PENDING',
      createdAt: T0,
      updatedAt: T0,
    } as Payout;
    const settlement = {
      status: 'CONFIRMED',
      finalViews: 12500,
      settledAt: T0,
    } as Settlement;
    const entries = buildWalletEntries({
      ...input([brand({ stage: 'SETTLED' })]),
      payouts: [payout],
      settlements: new Map([['b1', settlement]]),
    });
    expect(entries).toEqual([
      expect.objectContaining({
        kind: 'PAYOUT_SCHEDULED',
        amount: 375000,
        views: 12500,
        format: 'REELS',
        pieces: 2,
      }),
    ]);
  });
});
