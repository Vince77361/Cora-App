import { OfferStatus } from '@prisma/client';
import {
  canUndoDecline,
  DECLINE_UNDO_SECONDS,
  OFFER_RESPONSE_DAYS,
  needsInstagram,
  OfferTimes,
  paymentDaysLeft,
  PAYMENT_DUE_DAYS,
  storedStatusAt,
  viewForCreator,
  viewForStore,
} from './offer-rules';

const T0 = new Date('2026-12-01T00:00:00Z');
const SECOND = 1000;
const HOUR = 60 * 60 * SECOND;
const DAY = 24 * HOUR;
const at = (offsetMs: number): Date => new Date(T0.getTime() + offsetMs);

// T0에 보낸 오퍼.
function sent(over: Partial<OfferTimes> = {}): OfferTimes {
  return {
    status: 'SENT',
    expiresAt: at(OFFER_RESPONSE_DAYS * DAY),
    paymentDueAt: null,
    declinedAt: null,
    ...over,
  };
}
// 수락한 시각 = acceptedAt에 받은 오퍼.
function accepted(acceptedAt: Date): OfferTimes {
  return sent({
    status: 'ACCEPTED',
    paymentDueAt: new Date(acceptedAt.getTime() + PAYMENT_DUE_DAYS * DAY),
  });
}
function declined(declinedAt: Date): OfferTimes {
  return sent({ status: 'DECLINED', declinedAt });
}

describe('offer rules', () => {
  it('uses the agreed policy values', () => {
    expect(OFFER_RESPONSE_DAYS).toBe(7);
    expect(PAYMENT_DUE_DAYS).toBe(3);
    expect(DECLINE_UNDO_SECONDS).toBe(30);
  });

  it('is WAITING for both sides right after sending', () => {
    expect(storedStatusAt(sent(), T0)).toBe('SENT');
    expect(viewForStore(sent(), T0)).toBe('WAITING');
    expect(viewForCreator(sent(), T0)).toBe('WAITING');
  });

  it('expires a sent offer exactly 7 days after sending', () => {
    const offer = sent();
    expect(storedStatusAt(offer, at(7 * DAY - 1))).toBe('SENT');
    expect(storedStatusAt(offer, at(7 * DAY))).toBe('EXPIRED');
    expect(viewForStore(offer, at(7 * DAY))).toBe('EXPIRED');
    expect(viewForCreator(offer, at(7 * DAY))).toBe('EXPIRED');
  });

  it('expires an accepted offer 3 days after acceptance', () => {
    const acceptedAt = at(DAY);
    const offer = accepted(acceptedAt);
    expect(storedStatusAt(offer, at(4 * DAY - 1))).toBe('ACCEPTED');
    expect(viewForStore(offer, at(4 * DAY - 1))).toBe('ACCEPTED');
    expect(storedStatusAt(offer, at(4 * DAY))).toBe('EXPIRED');
    expect(viewForCreator(offer, at(4 * DAY))).toBe('EXPIRED');
  });

  it('does not expire an accepted offer by the 7 day response deadline', () => {
    // 응답 기한(expiresAt)은 SENT에만 걸린다. 수락 뒤에는 결제 기한이 대신한다.
    const offer = sent({
      status: 'ACCEPTED',
      expiresAt: at(DAY),
      paymentDueAt: at(5 * DAY),
    });
    expect(storedStatusAt(offer, at(2 * DAY))).toBe('ACCEPTED');
  });

  it('hides a decline from the store for 30 seconds', () => {
    const offer = declined(T0);
    expect(viewForStore(offer, at(29 * SECOND))).toBe('WAITING');
    expect(viewForStore(offer, at(30 * SECOND))).toBe('DECLINED');
  });

  it('shows a decline to the creator immediately', () => {
    expect(viewForCreator(declined(T0), T0)).toBe('DECLINED');
  });

  it('allows undo only within 30 seconds', () => {
    const offer = declined(T0);
    expect(canUndoDecline(offer, at(29 * SECOND))).toBe(true);
    expect(canUndoDecline(offer, at(30 * SECOND))).toBe(false);
  });

  it('never allows undo for an offer that is not declined', () => {
    const statuses: OfferStatus[] = [
      'SENT',
      'ACCEPTED',
      'EXPIRED',
      'CANCELLED',
    ];
    for (const status of statuses) {
      expect(canUndoDecline(sent({ status, declinedAt: T0 }), T0)).toBe(false);
    }
    expect(canUndoDecline(sent({ status: 'DECLINED' }), T0)).toBe(false);
  });

  it('maps cancelled offers to CANCELLED for both sides', () => {
    const offer = sent({ status: 'CANCELLED' });
    expect(viewForStore(offer, T0)).toBe('CANCELLED');
    expect(viewForCreator(offer, T0)).toBe('CANCELLED');
  });

  it('rounds payment days left up', () => {
    const offer = accepted(T0);
    expect(paymentDaysLeft(offer, T0)).toBe(3);
    expect(paymentDaysLeft(offer, at(DAY - HOUR))).toBe(3);
    expect(paymentDaysLeft(offer, at(DAY))).toBe(2);
    expect(paymentDaysLeft(offer, at(2 * DAY - HOUR))).toBe(2);
    expect(paymentDaysLeft(offer, at(2 * DAY + HOUR))).toBe(1);
    expect(paymentDaysLeft(offer, at(3 * DAY - HOUR))).toBe(1);
  });

  it('has no payment days left unless the offer is accepted and not yet due', () => {
    expect(paymentDaysLeft(sent(), T0)).toBeNull();
    expect(paymentDaysLeft(declined(T0), T0)).toBeNull();
    expect(paymentDaysLeft(accepted(T0), at(3 * DAY))).toBeNull();
  });

  describe('needsInstagram', () => {
    it('needs a connection for a per-view reels or card-news offer', () => {
      for (const format of ['REELS', 'CARD_NEWS'] as const) {
        for (const rewardType of ['PER_VIEW', 'BOTH'] as const) {
          expect(needsInstagram({ format, rewardType }, false)).toBe(true);
          expect(needsInstagram({ format, rewardType }, true)).toBe(false);
        }
      }
    });

    it('does not need one for a voucher-only offer or other formats', () => {
      expect(
        needsInstagram({ format: 'REELS', rewardType: 'VOUCHER' }, false),
      ).toBe(false);
      expect(
        needsInstagram({ format: 'CARD_NEWS', rewardType: 'VOUCHER' }, false),
      ).toBe(false);
      for (const format of ['SHORTS', 'BLOG'] as const) {
        expect(needsInstagram({ format, rewardType: 'PER_VIEW' }, false)).toBe(
          false,
        );
        expect(needsInstagram({ format, rewardType: 'BOTH' }, false)).toBe(
          false,
        );
      }
    });
  });
});
