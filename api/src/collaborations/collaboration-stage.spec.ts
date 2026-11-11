import { CollaborationStage as S } from '@prisma/client';
import {
  canTransition,
  initialStoreOfferState,
  isMoneyHeld,
  settlementMethodOf,
  storeInProgressStages,
} from './collaboration-stage';

const DAY = 24 * 60 * 60 * 1000;
const NOW = new Date('2026-12-01T00:00:00.000Z');

describe('canTransition', () => {
  it('allows the store path AWAITING_PAYMENT → FUNDED → COUNTING → SETTLED', () => {
    expect(canTransition('STORE_OFFER', S.AWAITING_PAYMENT, S.FUNDED)).toBe(
      true,
    );
    expect(canTransition('STORE_OFFER', S.FUNDED, S.COUNTING)).toBe(true);
    expect(canTransition('STORE_OFFER', S.COUNTING, S.SETTLED)).toBe(true);
  });

  it('lets a voucher-only offer go FUNDED → SETTLED directly', () => {
    expect(canTransition('STORE_OFFER', S.FUNDED, S.SETTLED)).toBe(true);
  });

  it('allows FUNDED → REFUNDED and FUNDED → CANCELLED but not COUNTING → CANCELLED', () => {
    expect(canTransition('STORE_OFFER', S.FUNDED, S.REFUNDED)).toBe(true);
    expect(canTransition('STORE_OFFER', S.FUNDED, S.CANCELLED)).toBe(true);
    expect(canTransition('STORE_OFFER', S.AWAITING_PAYMENT, S.CANCELLED)).toBe(
      true,
    );
    expect(canTransition('STORE_OFFER', S.COUNTING, S.CANCELLED)).toBe(false);
  });

  it('rejects skipping from AWAITING_PAYMENT to COUNTING', () => {
    expect(canTransition('STORE_OFFER', S.AWAITING_PAYMENT, S.COUNTING)).toBe(
      false,
    );
    expect(canTransition('STORE_OFFER', S.AWAITING_PAYMENT, S.SETTLED)).toBe(
      false,
    );
  });

  it('rejects leaving a finished store stage and brand stages on the store path', () => {
    for (const end of [S.SETTLED, S.REFUNDED, S.CANCELLED]) {
      expect(canTransition('STORE_OFFER', end, S.FUNDED)).toBe(false);
      expect(canTransition('STORE_OFFER', end, S.HALTED)).toBe(false);
    }
    expect(canTransition('STORE_OFFER', S.INQUIRY, S.MATCHED)).toBe(false);
  });

  it('allows the brand path in order and rejects GUIDED → APPROVED', () => {
    const path = [
      S.INQUIRY,
      S.MATCHED,
      S.NEGOTIATING,
      S.AGREED,
      S.CONTRACTED,
      S.GUIDED,
      S.REVIEWING,
      S.APPROVED,
      S.PUBLISHED,
      S.SETTLED,
    ];
    for (let i = 0; i < path.length - 1; i += 1) {
      expect(canTransition('BRAND_CONTRACT', path[i], path[i + 1])).toBe(true);
    }
    expect(canTransition('BRAND_CONTRACT', S.GUIDED, S.APPROVED)).toBe(false);
    expect(canTransition('BRAND_CONTRACT', S.AWAITING_PAYMENT, S.FUNDED)).toBe(
      false,
    );
  });

  it('allows DROPPED only before the contract', () => {
    for (const from of [S.INQUIRY, S.MATCHED, S.NEGOTIATING, S.AGREED]) {
      expect(canTransition('BRAND_CONTRACT', from, S.DROPPED)).toBe(true);
    }
    expect(canTransition('BRAND_CONTRACT', S.CONTRACTED, S.DROPPED)).toBe(
      false,
    );
  });

  it('allows HALTED only from CONTRACTED onwards for brand contracts', () => {
    for (const from of [S.INQUIRY, S.MATCHED, S.NEGOTIATING, S.AGREED]) {
      expect(canTransition('BRAND_CONTRACT', from, S.HALTED)).toBe(false);
    }
    for (const from of [
      S.CONTRACTED,
      S.GUIDED,
      S.REVIEWING,
      S.APPROVED,
      S.PUBLISHED,
    ]) {
      expect(canTransition('BRAND_CONTRACT', from, S.HALTED)).toBe(true);
    }
    expect(canTransition('BRAND_CONTRACT', S.SETTLED, S.HALTED)).toBe(false);
  });

  it('allows HALTED from FUNDED and COUNTING for store offers', () => {
    expect(canTransition('STORE_OFFER', S.FUNDED, S.HALTED)).toBe(true);
    expect(canTransition('STORE_OFFER', S.COUNTING, S.HALTED)).toBe(true);
    expect(canTransition('STORE_OFFER', S.AWAITING_PAYMENT, S.HALTED)).toBe(
      false,
    );
  });

  it('leaves HALTED only to the stage before it, SETTLED or REFUNDED', () => {
    expect(canTransition('STORE_OFFER', S.HALTED, S.SETTLED)).toBe(true);
    expect(canTransition('STORE_OFFER', S.HALTED, S.REFUNDED)).toBe(true);
    expect(canTransition('STORE_OFFER', S.HALTED, S.COUNTING, S.COUNTING)).toBe(
      true,
    );
    expect(canTransition('STORE_OFFER', S.HALTED, S.FUNDED, S.COUNTING)).toBe(
      false,
    );
    expect(canTransition('STORE_OFFER', S.HALTED, S.CANCELLED)).toBe(false);
    expect(canTransition('BRAND_CONTRACT', S.HALTED, S.REFUNDED)).toBe(true);
    expect(
      canTransition('BRAND_CONTRACT', S.HALTED, S.GUIDED, S.REVIEWING),
    ).toBe(false);
    expect(
      canTransition('BRAND_CONTRACT', S.HALTED, S.REVIEWING, S.REVIEWING),
    ).toBe(true);
  });
});

describe('isMoneyHeld', () => {
  it('reports money held for FUNDED, COUNTING and HALTED store collaborations only', () => {
    for (const stage of [S.FUNDED, S.COUNTING, S.HALTED]) {
      expect(isMoneyHeld('STORE_OFFER', stage)).toBe(true);
    }
    for (const stage of [
      S.AWAITING_PAYMENT,
      S.SETTLED,
      S.REFUNDED,
      S.CANCELLED,
    ]) {
      expect(isMoneyHeld('STORE_OFFER', stage)).toBe(false);
    }
  });

  it('reports money held for brand CONTRACTED through PUBLISHED and HALTED', () => {
    for (const stage of [
      S.CONTRACTED,
      S.GUIDED,
      S.REVIEWING,
      S.APPROVED,
      S.PUBLISHED,
      S.HALTED,
    ]) {
      expect(isMoneyHeld('BRAND_CONTRACT', stage)).toBe(true);
    }
    for (const stage of [S.INQUIRY, S.AGREED, S.SETTLED, S.DROPPED]) {
      expect(isMoneyHeld('BRAND_CONTRACT', stage)).toBe(false);
    }
  });
});

describe('storeInProgressStages', () => {
  it('lists AWAITING_PAYMENT, FUNDED and COUNTING', () => {
    expect(storeInProgressStages).toEqual([
      S.AWAITING_PAYMENT,
      S.FUNDED,
      S.COUNTING,
    ]);
  });
});

describe('settlementMethodOf', () => {
  it('is PER_VIEW when the reward has a per-view part and NONE for a voucher only', () => {
    expect(settlementMethodOf('PER_VIEW')).toBe('PER_VIEW');
    expect(settlementMethodOf('BOTH')).toBe('PER_VIEW');
    expect(settlementMethodOf('VOUCHER')).toBe('NONE');
  });
});

describe('initialStoreOfferState', () => {
  it('waits for payment with a 3 day payment due date for a per-view offer', () => {
    expect(initialStoreOfferState('BOTH', NOW)).toEqual({
      settlementMethod: 'PER_VIEW',
      stage: 'AWAITING_PAYMENT',
      paymentDueAt: new Date(NOW.getTime() + 3 * DAY),
      fundedAt: null,
      submitDueAt: null,
    });
  });

  it('is funded at once with a 14 day submit date and no payment due date for a voucher-only offer', () => {
    expect(initialStoreOfferState('VOUCHER', NOW)).toEqual({
      settlementMethod: 'NONE',
      stage: 'FUNDED',
      paymentDueAt: null,
      fundedAt: NOW,
      submitDueAt: new Date(NOW.getTime() + 14 * DAY),
    });
  });
});
