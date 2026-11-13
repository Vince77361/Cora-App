import { ContentFormat, OfferStatus } from '@prisma/client';
import { PAYMENT_DUE_DAYS } from '../collaborations/collaboration-stage';
import { PROPOSAL_POLICY } from '../common/collaboration-policy';

// 오퍼 상태 규칙은 모두 순수 함수다. 시각은 인자로 받는다(Clock은 서비스가 쥔다).
// 결제 기한은 협업의 첫 상태를 정하는 collaboration-stage가 원본이다. 읽는 쪽이 이 파일에서 그대로 쓰도록 다시 내보낸다.
export { PAYMENT_DUE_DAYS };
export const DECLINE_UNDO_SECONDS = PROPOSAL_POLICY.declineUndoSeconds;

const SECOND_MS = 1000;
const DAY_MS = 24 * 60 * 60 * SECOND_MS;

export const OFFER_VIEWS = [
  'WAITING',
  'ACCEPTED',
  'DECLINED',
  'EXPIRED',
  'CANCELLED',
] as const;
export type OfferView = (typeof OFFER_VIEWS)[number];

// 규칙이 보는 오퍼의 필드만. Prisma Offer 행이 그대로 들어간다.
export interface OfferTimes {
  status: OfferStatus;
  expiresAt: Date;
  paymentDueAt: Date | null;
  declinedAt: Date | null;
}

// 저장된 상태가 아니라 "지금 이 시각이면 어떤 상태여야 하는가". 만료는 시각이 지나면 저절로 되므로
// 저장된 값이 뒤처질 수 있고, 읽는 곳이 이 값과 저장된 값이 다르면 그 자리에서 맞춰 저장한다.
export function storedStatusAt(offer: OfferTimes, now: Date): OfferStatus {
  if (offer.status === 'SENT' && offer.expiresAt.getTime() <= now.getTime()) {
    return 'EXPIRED';
  }
  if (
    offer.status === 'ACCEPTED' &&
    offer.paymentDueAt !== null &&
    offer.paymentDueAt.getTime() <= now.getTime()
  ) {
    return 'EXPIRED';
  }
  return offer.status;
}

// 거절 직후 30초는 되돌릴 수 있는 시간이다. 그동안 사장님에게는 거절이 보이지 않는다.
export function canUndoDecline(offer: OfferTimes, now: Date): boolean {
  return (
    offer.status === 'DECLINED' &&
    offer.declinedAt !== null &&
    offer.declinedAt.getTime() + DECLINE_UNDO_SECONDS * SECOND_MS >
      now.getTime()
  );
}

function viewOf(status: OfferStatus): OfferView {
  return status === 'SENT' ? 'WAITING' : status;
}

export function viewForStore(offer: OfferTimes, now: Date): OfferView {
  const status = storedStatusAt(offer, now);
  if (status === 'DECLINED' && canUndoDecline(offer, now)) return 'WAITING';
  return viewOf(status);
}

export function viewForCreator(offer: OfferTimes, now: Date): OfferView {
  return viewOf(storedStatusAt(offer, now));
}

// 수락됐고 아직 기한 전일 때만 남은 날(올림). 3일 기한이 막 시작되면 3.
export function paymentDaysLeft(offer: OfferTimes, now: Date): number | null {
  if (storedStatusAt(offer, now) !== 'ACCEPTED' || !offer.paymentDueAt) {
    return null;
  }
  return Math.ceil((offer.paymentDueAt.getTime() - now.getTime()) / DAY_MS);
}

// 조회수 수당을 받으려면 인스타그램을 연결해 조회수를 읽을 수 있어야 한다(공통 모델 2장).
// 릴스와 카드뉴스에 조회수 수당(다른 보상과 함께여도)이 있는데 연결이 없으면 수락할 수 없다.
// 쇼츠와 블로그의 조회수는 이 연결로 읽지 않는다.
export function needsInstagram(
  terms: { format: ContentFormat; perViewCap: number | null },
  connected: boolean,
): boolean {
  if (connected) return false;
  if (terms.format !== 'REELS' && terms.format !== 'CARD_NEWS') return false;
  return terms.perViewCap !== null;
}
