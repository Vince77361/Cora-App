import type { IndustryCategory, TermsVersion } from '@prisma/client';
import { INDUSTRY_LABELS } from '../common/industry';
import { maxCashBurden } from '../stores/reward-terms';
import { TermsHistoryModel } from './dto/terms-history.model';
import { TermsVersionModel } from './dto/terms-version.model';
import { diffTerms } from './terms-diff';

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

// 06 `추천된 이유`의 `주요 분야`: 크리에이터가 협업 원칙에서 고른 분야의 이름표를 고른 순서대로. 원칙이 없으면 빈 배열이다.
export function principleFieldLabels(
  principles: { fields: IndustryCategory[] } | null,
): string[] {
  return principles ? principles.fields.map((f) => INDUSTRY_LABELS[f]) : [];
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
// 판본 응답의 maxCash와 협업 조회의 확보액이 이 함수 하나를 쓴다(같은 판본이면 같은 숫자).
export function termsMaxCash(
  row: Pick<TermsVersion, 'fee' | 'perfCap'>,
): number {
  return maxCashBurden({ fixedCash: row.fee, perViewCap: row.perfCap });
}

// 내 쪽이 이 판본을 아직 확인하지 않았다(내가 답할 차례다). 조건 조회와 협업 조회의 "지금 할 일"이 같은 정의를 쓴다.
export function isMyTurn(
  row: Pick<TermsVersion, 'brandConfirmedAt' | 'creatorConfirmedAt'>,
  isCreator: boolean,
): boolean {
  return (isCreator ? row.creatorConfirmedAt : row.brandConfirmedAt) === null;
}

// 최신 판본의 확인 상태(12 화면의 "누구를 기다리는가"). 이전 판본의 확인은 보지 않는다.
export function agreementOf(
  row: Pick<TermsVersion, 'brandConfirmedAt' | 'creatorConfirmedAt'>,
): TermsHistoryModel['agreement'] {
  const brand = row.brandConfirmedAt !== null;
  const creator = row.creatorConfirmedAt !== null;
  if (brand && creator) return 'AGREED';
  if (creator) return 'WAITING_BRAND';
  if (brand) return 'WAITING_CREATOR';
  return 'NONE';
}

// previous는 바로 앞 판본(버전 1은 null)이다: 바뀐 항목(changedFields)과 이전 최대 현금 부담이 그것에서 나온다.
export function toTermsVersionModel(
  row: TermsVersion,
  commissionerId: string,
  previous: TermsVersion | null,
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
    maxCash: termsMaxCash(row),
    previousMaxCash: previous ? termsMaxCash(previous) : null,
    startDate: row.startDate.toISOString().slice(0, 10),
    format: row.format,
    pieces: row.pieces,
    productProvided: row.productProvided,
    revisionScope: row.revisionScope,
    usageRights: row.usageRights,
    payoutDays: row.payoutDays,
    brandConfirmed: row.brandConfirmedAt !== null,
    creatorConfirmed: row.creatorConfirmedAt !== null,
    changedFields: diffTerms(previous, row),
    createdAt: row.createdAt.toISOString(),
  };
}
