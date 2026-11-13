import { OfferParty, OfferVersion } from '@prisma/client';
import { OfferTermsModel } from '../stores/dto/offer-terms.model';
import { termsModelOf } from '../stores/reward-terms';
import { OfferVersionModel } from './dto/offer-version.model';

// 판본을 주고받는 규칙은 모두 순수 함수다. 시각과 DB를 모른다.

// 응답할 차례는 최신 판본을 쓰지 않은 쪽이다.
export function turnAfter(author: OfferParty): OfferParty {
  return author === 'STORE' ? 'CREATOR' : 'STORE';
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
