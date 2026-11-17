import type { Prisma } from '@prisma/client';
import { BrandUsageRights } from '@prisma/client';
import { maxCashBurden } from '../stores/reward-terms';
import { TermsVersionModel } from '../terms/dto/terms-version.model';

// 계약의 조건 사본은 동의할 때의 판본 모델(TermsVersionModel)을 그대로 JSON으로 저장한 것이다.
// 이후 판본이 바뀌어도 이 계약은 그대로이고, 결제 금액·정산·화면이 모두 이 사본만 읽는다(결제 행에 보상 칸을 더하지 않는다).
export function snapshotOf(terms: TermsVersionModel): Prisma.InputJsonObject {
  return JSON.parse(JSON.stringify(terms)) as Prisma.InputJsonObject;
}

function isWholeWon(value: unknown): value is number {
  return typeof value === 'number' && Number.isInteger(value) && value >= 0;
}

// 저장된 사본을 읽는다. 돈이 걸린 값(제작비, 성과 추가, 최대 현금 부담, 활용 권한, 판본)이 맞지 않으면 던진다:
// 잘못 읽은 금액으로 결제하거나 정산하는 것보다 멈추는 편이 낫다.
export function readSnapshot(json: unknown): TermsVersionModel {
  const s = json as Partial<TermsVersionModel> | null;
  if (
    !s ||
    typeof s !== 'object' ||
    !Number.isInteger(s.version) ||
    !isWholeWon(s.fee) ||
    !isWholeWon(s.maxCash) ||
    !Number.isInteger(s.pieces) ||
    !Object.values(BrandUsageRights).includes(s.usageRights as BrandUsageRights)
  ) {
    throw new Error('계약의 조건 사본이 올바르지 않아요.');
  }
  const performance = s.performance ?? null;
  if (
    performance !== null &&
    (!isWholeWon(performance.ratePer1000) || !isWholeWon(performance.cap))
  ) {
    throw new Error('계약의 조건 사본의 성과 추가가 올바르지 않아요.');
  }
  if (s.maxCash !== maxCashOfSnapshot(s as TermsVersionModel)) {
    throw new Error('계약의 조건 사본의 최대 현금 부담이 맞지 않아요.');
  }
  return s as TermsVersionModel;
}

// 사본의 최대 현금 부담(제작비 + 성과 추가 상한). 결제·견적·정산이 모두 이 값을 쓴다.
export function maxCashOfSnapshot(
  terms: Pick<TermsVersionModel, 'fee' | 'performance'>,
): number {
  return maxCashBurden({
    fixedCash: terms.fee,
    perViewCap: terms.performance?.cap ?? null,
  });
}
