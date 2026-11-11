import { ContentFormat, RewardType } from '@prisma/client';
import { AppError } from '../common/errors/app-error';
import { OfferTermsModel } from './dto/offer-terms.model';

export { OfferTermsModel };

// 식사권 기본값과 조회 단가는 정책 값이라 한 곳에 둔다(기본 조건, 오퍼가 같이 쓴다).
export const DEFAULT_VOUCHER_NAME = '2인 식사권';
export const DEFAULT_VOUCHER_VALUE = 40000;
export const PER_VIEW_AMOUNT = 10;
export const PER_VIEW_CAP = 100000;

// 입력을 저장·표시용 조건으로 정리하는 순수 함수. 가게 기본 조건과 오퍼가 같은 규칙을 쓴다.
export function buildTerms(input: {
  format: ContentFormat;
  rewardType: RewardType;
  voucherName?: string | null;
  voucherValue?: number | null;
}): OfferTermsModel {
  const { format, rewardType } = input;
  const hasVoucher = rewardType === 'VOUCHER' || rewardType === 'BOTH';
  const hasPerView = rewardType === 'PER_VIEW' || rewardType === 'BOTH';
  // 블로그 글은 조회수를 셀 수 없어 조회수 보상과 함께 쓸 수 없다.
  if (format === 'BLOG' && hasPerView) {
    throw new AppError(
      'VALIDATION_FAILED',
      '블로그 글은 조회수를 셀 수 없어요.',
    );
  }
  return {
    format,
    rewardType,
    voucherName: hasVoucher
      ? input.voucherName?.trim() || DEFAULT_VOUCHER_NAME
      : null,
    voucherValue: hasVoucher
      ? (input.voucherValue ?? DEFAULT_VOUCHER_VALUE)
      : null,
    perViewAmount: hasPerView ? PER_VIEW_AMOUNT : null,
    perViewCap: hasPerView ? PER_VIEW_CAP : null,
  };
}
