import type { TermsVersion } from '@prisma/client';
import { maxCashBurden } from '../stores/reward-terms';
import { TermsVersionModel } from './dto/terms-version.model';

// 크리에이터의 협업 원칙에서 만드는 안내 줄. 둘 다 아니면 한 줄에 함께 쓰고, 해당이 없으면 null이다.
export function termsNotice(
  principles: { faceOk: boolean; scriptOk: boolean } | null,
): string | null {
  if (!principles) return null;
  if (!principles.faceOk && !principles.scriptOk) {
    return '얼굴 출연과 제품 설명문 낭독은 진행하지 않아요.';
  }
  if (!principles.faceOk) return '얼굴 출연은 진행하지 않아요.';
  if (!principles.scriptOk) return '제품 설명문 낭독은 진행하지 않아요.';
  return null;
}

// 판본을 낸 쪽. 만든 사람이 없으면 서버(서로 관심이 닿을 때 만든 버전 1)다.
export function proposedByOf(
  proposedById: string | null,
  commissionerId: string,
): TermsVersionModel['proposedBy'] {
  if (proposedById === null) return 'SYSTEM';
  return proposedById === commissionerId ? 'BRAND' : 'CREATOR';
}

// 최대 현금 부담은 가게 흐름 개정 계획의 순수 함수(maxCashBurden)로 구한다. 화면의 어느 곳에서도 같은 숫자다.
export function toTermsVersionModel(
  row: TermsVersion,
  commissionerId: string,
): TermsVersionModel {
  const performance =
    row.perfRatePerThousand !== null && row.perfCap !== null
      ? { ratePer1000: row.perfRatePerThousand, cap: row.perfCap }
      : null;
  return {
    version: row.version,
    proposedBy: proposedByOf(row.proposedById, commissionerId),
    title: row.title,
    fee: row.fee,
    performance,
    maxCash: maxCashBurden({ fixedCash: row.fee, perViewCap: row.perfCap }),
    startDate: row.startDate.toISOString().slice(0, 10),
    format: row.format,
    pieces: row.pieces,
    productProvided: row.productProvided,
    revisionScope: row.revisionScope,
    usageRights: row.usageRights,
    payoutDays: row.payoutDays,
    brandConfirmed: row.brandConfirmedAt !== null,
    creatorConfirmed: row.creatorConfirmedAt !== null,
  };
}
