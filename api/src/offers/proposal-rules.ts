import { ContentFormat, OfferParty, OfferVersion } from '@prisma/client';
import { OfferTermsModel } from '../stores/dto/offer-terms.model';
import { RewardDefaults, termsModelOf } from '../stores/reward-terms';
import { OfferVersionModel } from './dto/offer-version.model';
import { canUndoDecline, OfferTimes, storedStatusAt } from './offer-rules';

// 판본을 주고받는 규칙은 모두 순수 함수다. 시각과 DB를 모른다.

// 응답할 차례는 최신 판본을 쓰지 않은 쪽이다.
export function turnAfter(author: OfferParty): OfferParty {
  return author === 'STORE' ? 'CREATOR' : 'STORE';
}

// 제안을 끝냈을 때의 상태. 차례인 쪽(= 받은 쪽)이 끝내면 거절(DECLINED), 최신 판본을 쓴 쪽이 끝내면 취소(CANCELLED)다.
export function endStatusOf(
  party: OfferParty,
  turn: OfferParty,
): 'CANCELLED' | 'DECLINED' {
  return party === turn ? 'DECLINED' : 'CANCELLED';
}

// 이 오퍼에서 내가 어느 쪽인가. 당사자가 아니면 null이다(호출하는 쪽이 404로 바꾼다).
export function partyOf(
  offer: { creatorId: string },
  userId: string,
  storeOwnerId: string,
): OfferParty | null {
  if (userId === storeOwnerId) return 'STORE';
  if (userId === offer.creatorId) return 'CREATOR';
  return null;
}

export type ChangedField =
  | 'FORMAT'
  | 'VOUCHER'
  | 'FIXED_CASH'
  | 'VIEW_PAY'
  | 'USAGE_RIGHTS'
  | 'IDEA'
  | 'PRINCIPLES'
  | 'SERIES';

// 앞 판본과 달라진 항목. 첫 판본은 비교할 것이 없어 비어 있다. 순서는 화면이 보여 주는 순서다.
export function changedFields(
  prev: OfferVersionModel | null,
  next: OfferVersionModel,
): ChangedField[] {
  if (!prev) return [];
  const changed: ChangedField[] = [];
  const a = prev.terms;
  const b = next.terms;
  if (a.format !== b.format) changed.push('FORMAT');
  if (
    a.voucherName !== b.voucherName ||
    a.voucherValue !== b.voucherValue ||
    a.voucherPeople !== b.voucherPeople
  ) {
    changed.push('VOUCHER');
  }
  if (a.fixedCash !== b.fixedCash) changed.push('FIXED_CASH');
  if (
    a.viewRatePerThousand !== b.viewRatePerThousand ||
    a.perViewCap !== b.perViewCap
  ) {
    changed.push('VIEW_PAY');
  }
  if (a.usageRights !== b.usageRights) changed.push('USAGE_RIGHTS');
  if (prev.idea !== next.idea) changed.push('IDEA');
  if (
    prev.principles.length !== next.principles.length ||
    prev.principles.some((p, i) => p !== next.principles[i])
  ) {
    changed.push('PRINCIPLES');
  }
  if (
    prev.series?.name !== next.series?.name ||
    prev.series?.format !== next.series?.format ||
    prev.series?.note !== next.series?.note
  ) {
    changed.push('SERIES');
  }
  return changed;
}

// 판본 행의 조건을 응답용 조건으로. 행 전체를 넘기면 id 같은 열이 응답에 섞이므로 조건 열만 골라 넘긴다.
export function termsOfVersion(row: OfferVersion): OfferTermsModel {
  return termsModelOf(
    row.format,
    {
      voucherName: row.voucherName,
      voucherValue: row.voucherValue,
      voucherPeople: row.voucherPeople,
      fixedCash: row.fixedCash,
      viewRatePerThousand: row.viewRatePerThousand,
      perViewCap: row.perViewCap,
    },
    row.usageRights,
  );
}

// 저장된 판본 행을 응답 모양으로. 연재는 세 값이 모두 비면 null이다.
export function versionModelOf(row: OfferVersion): OfferVersionModel {
  const hasSeries =
    row.seriesName !== null ||
    row.seriesFormat !== null ||
    row.seriesNote !== null;
  return {
    number: row.number,
    authorParty: row.authorParty,
    terms: termsOfVersion(row),
    idea: row.idea,
    principles: row.principles,
    series: hasSeries
      ? {
          name: row.seriesName,
          format: row.seriesFormat,
          note: row.seriesNote,
        }
      : null,
    createdAt: row.createdAt,
  };
}

// 새 판본에서 비워 둔 값은 앞 판본의 값으로 채운다. 가게의 기본 조건은 크리에이터가 쓸 때 알 수 없고,
// 고쳐 보내는 화면도 앞 판본에서 출발하기 때문이다.
export function defaultsOfVersion(row: OfferVersion): RewardDefaults {
  return {
    voucherName: row.voucherName,
    voucherValue: row.voucherValue,
    voucherPeople: row.voucherPeople,
    viewRatePerThousand: row.viewRatePerThousand,
    perViewCap: row.perViewCap,
    usageRights: row.usageRights,
  };
}

// 시리즈는 판본에 사본으로 넣는다(원본을 고치거나 지워도 이미 낸 판본은 그대로여야 해서).
export interface SeriesCopy {
  name: string | null;
  format: ContentFormat | null;
  note: string | null;
}

// 사장님이 보낸 idea·principles·시리즈는 저장하지 않는다. 한 줄 설명과 원칙, 시리즈는 크리에이터의 판본에만 있다.
export function proposalExtras(
  author: OfferParty,
  input: { idea?: string; principles?: string[] },
  series: SeriesCopy | null = null,
): { idea: string | null; principles: string[]; series: SeriesCopy | null } {
  if (author !== 'CREATOR') return { idea: null, principles: [], series: null };
  const idea = input.idea?.trim() ?? '';
  return {
    idea: idea === '' ? null : idea,
    principles: input.principles ?? [],
    series,
  };
}

// 제안함의 묶음. 차례가 나인 것, 상대가 답할 차례인 것, 끝난 것.
export const PROPOSAL_GROUPS = ['MY_TURN', 'WAITING', 'ENDED'] as const;
export type ProposalGroup = (typeof PROPOSAL_GROUPS)[number];

// 끝난 까닭의 갈래. 합의(수락), 사유를 골라 끝냄(거절·취소), 기한이 지나 끝남.
export const END_KINDS = ['AGREED', 'ENDED', 'EXPIRED'] as const;
export type EndKind = (typeof END_KINDS)[number];

export interface ProposalOfferState extends OfferTimes {
  turn: OfferParty;
}

const DAY_MS = 24 * 60 * 60 * 1000;

// 제안함에서 이 오퍼가 어느 묶음인가. 저장된 상태가 아니라 지금 시각의 상태로 본다(만료는 저장이 뒤처질 수 있어서).
// 크리에이터가 방금 거절해 30초 안에 되돌릴 수 있는 오퍼는 사장님에게 아직 거절로 보이지 않아 기다리는 중이다.
export function proposalGroup(
  offer: ProposalOfferState,
  me: OfferParty,
  now: Date,
): ProposalGroup {
  const status = storedStatusAt(offer, now);
  if (status === 'SENT') return offer.turn === me ? 'MY_TURN' : 'WAITING';
  if (status === 'DECLINED' && me === 'STORE' && canUndoDecline(offer, now)) {
    return 'WAITING';
  }
  return 'ENDED';
}

// 끝난 오퍼가 어떻게 끝났는가. 수락은 "합의 완료"(AGREED)다. 끝나지 않았으면 null.
export function endKind(offer: OfferTimes, now: Date): EndKind | null {
  switch (storedStatusAt(offer, now)) {
    case 'ACCEPTED':
      return 'AGREED';
    case 'EXPIRED':
      return 'EXPIRED';
    case 'CANCELLED':
    case 'DECLINED':
      return 'ENDED';
    default:
      return null;
  }
}

// 남은 응답 기한(일, 올림). 하루가 안 남았으면 0이다("오늘 안에 답이 와요").
export function daysLeftToAnswer(expiresAt: Date, now: Date): number {
  const left = expiresAt.getTime() - now.getTime();
  return left < DAY_MS ? 0 : Math.ceil(left / DAY_MS);
}

// 상대가 쓴 판본이 최신이고 번호가 2 이상이면 역제안(고쳐서 다시 온 제안)이다. 번호 1은 처음 제안이다.
export function isCounter(
  latest: Pick<OfferVersionModel, 'number' | 'authorParty'>,
  me: OfferParty,
): boolean {
  return latest.number >= 2 && latest.authorParty !== me;
}
