import { ContentFormat, RewardType } from '@prisma/client';
import { REWARD_POLICY } from '../common/collaboration-policy';
import { AppError } from '../common/errors/app-error';

// 보상의 세 요소(식사권, 고정 현금, 조회수 수당)를 한 모양으로 다루는 순수 함수 모음.
// 최대 현금 부담·지급 방식 같은 파생 값은 여기서만 만든다. 옛 buildTerms는 그대로 두고 호출부는 Task 3이 옮긴다.

export type RewardInput = {
  voucher?: {
    name?: string | null;
    value?: number | null;
    people?: number | null;
  } | null;
  fixedCash?: number;
  perView?: { ratePerThousand?: number; cap?: number } | null;
};

export type RewardTerms = {
  voucherName: string | null;
  voucherValue: number | null;
  voucherPeople: number | null;
  fixedCash: number;
  viewRatePerThousand: number | null;
  perViewCap: number | null;
};

export type RewardSettlementMethod =
  'NONE' | 'FIXED' | 'PER_VIEW' | 'FIXED_AND_PER_VIEW';

// 범위와 단위를 함께 본다. 소수나 음수는 단위 검사에서 같이 걸린다.
function assertRange(
  label: string,
  value: number,
  range: { min: number; max: number; step: number },
): void {
  if (
    !Number.isInteger(value) ||
    value < range.min ||
    value > range.max ||
    value % range.step !== 0
  ) {
    throw new AppError(
      'VALIDATION_FAILED',
      `${label}은(는) ${range.min.toLocaleString('ko-KR')}원부터 ${range.max.toLocaleString('ko-KR')}원까지 ${range.step.toLocaleString('ko-KR')}원 단위로 정해 주세요.`,
    );
  }
}

export function buildReward(
  input: RewardInput,
  opts: {
    format: ContentFormat;
    commissioner?: 'STORE' | 'BRAND';
    defaults?: Partial<RewardTerms>;
  },
): RewardTerms {
  const commissioner = opts.commissioner ?? 'STORE';
  const defaults = opts.defaults ?? {};
  const fixedCash = input.fixedCash ?? 0;
  const hasVoucher = !!input.voucher;
  const hasPerView = !!input.perView;

  // 블로그 글은 조회수를 셀 수 없어 조회수 수당과 함께 쓸 수 없다.
  if (opts.format === 'BLOG' && hasPerView) {
    throw new AppError(
      'VALIDATION_FAILED',
      '블로그 글은 조회수를 셀 수 없어요.',
    );
  }
  if (!hasVoucher && fixedCash === 0 && !hasPerView) {
    throw new AppError('VALIDATION_FAILED', '보상을 하나 이상 정해 주세요.');
  }

  // 0은 "없음"이라 범위(최솟값 0)로 본다.
  assertRange('고정 현금', fixedCash, {
    min: 0,
    max: REWARD_POLICY.fixedCash.maxByCommissioner[commissioner],
    step: REWARD_POLICY.fixedCash.step,
  });

  let voucherName: string | null = null;
  let voucherValue: number | null = null;
  let voucherPeople: number | null = null;
  if (input.voucher) {
    const v = input.voucher;
    const policy = REWARD_POLICY.voucher;
    voucherName = v.name?.trim() || defaults.voucherName || policy.defaultName;
    voucherValue = v.value ?? defaults.voucherValue ?? policy.defaultValue;
    voucherPeople = v.people ?? defaults.voucherPeople ?? policy.defaultPeople;
    if (
      !Number.isInteger(voucherValue) ||
      voucherValue < policy.minValue ||
      voucherValue > policy.maxValue
    ) {
      throw new AppError(
        'VALIDATION_FAILED',
        `식사권 금액은 ${policy.minValue.toLocaleString('ko-KR')}원부터 ${policy.maxValue.toLocaleString('ko-KR')}원까지 정해 주세요.`,
      );
    }
    if (
      !Number.isInteger(voucherPeople) ||
      voucherPeople < 1 ||
      voucherPeople > policy.maxPeople
    ) {
      throw new AppError(
        'VALIDATION_FAILED',
        `식사권 인원은 1명부터 ${policy.maxPeople}명까지 정해 주세요.`,
      );
    }
  }

  let viewRatePerThousand: number | null = null;
  let perViewCap: number | null = null;
  if (input.perView) {
    // 빈 값은 가게의 모집 조건 → 정책 기본값 순으로 채운다.
    viewRatePerThousand =
      input.perView.ratePerThousand ??
      defaults.viewRatePerThousand ??
      REWARD_POLICY.viewRate.default;
    perViewCap =
      input.perView.cap ??
      defaults.perViewCap ??
      REWARD_POLICY.perViewCap.default;
    assertRange('조회수 단가', viewRatePerThousand, REWARD_POLICY.viewRate);
    assertRange('조회수 수당 상한', perViewCap, REWARD_POLICY.perViewCap);
  }

  return {
    voucherName,
    voucherValue,
    voucherPeople,
    fixedCash,
    viewRatePerThousand,
    perViewCap,
  };
}

// 최대 현금 부담 = 고정 현금 + 조회수 수당 상한. 결제 금액과 에스크로는 이 값에서 나온다.
export function maxCashBurden(
  r: Pick<RewardTerms, 'fixedCash' | 'perViewCap'>,
): number {
  return r.fixedCash + (r.perViewCap ?? 0);
}

export function hasViewPay(r: Pick<RewardTerms, 'perViewCap'>): boolean {
  return r.perViewCap !== null;
}

export function settlementMethodOfReward(
  r: Pick<RewardTerms, 'fixedCash' | 'perViewCap'>,
): RewardSettlementMethod {
  const fixed = r.fixedCash > 0;
  const view = hasViewPay(r);
  if (fixed && view) return 'FIXED_AND_PER_VIEW';
  if (fixed) return 'FIXED';
  if (view) return 'PER_VIEW';
  return 'NONE';
}

// 이미 결제된 옛 협업의 금액은 바뀌지 않는다: 단가만 1,000회당으로 옮기고(10 → 10000)
// 범위 검사는 하지 않는다. 옛 단가 10000은 새 범위(1000~5000)를 벗어난다.
export function fromLegacyTerms(t: {
  rewardType: RewardType;
  voucherName: string | null;
  voucherValue: number | null;
  perViewAmount: number | null;
  perViewCap: number | null;
}): RewardTerms {
  const hasVoucher = t.rewardType === 'VOUCHER' || t.rewardType === 'BOTH';
  const hasPerView = t.rewardType === 'PER_VIEW' || t.rewardType === 'BOTH';
  const legacyDefaultName = '2인 식사권';
  const isDefaultName = t.voucherName === legacyDefaultName;
  return {
    voucherName: hasVoucher
      ? isDefaultName
        ? REWARD_POLICY.voucher.defaultName
        : t.voucherName
      : null,
    voucherValue: hasVoucher ? t.voucherValue : null,
    // 옛 이름에서 인원을 알 수 있는 것은 기본 이름뿐이다.
    voucherPeople: hasVoucher && isDefaultName ? 2 : null,
    fixedCash: 0,
    viewRatePerThousand:
      hasPerView && t.perViewAmount !== null ? t.perViewAmount * 1000 : null,
    perViewCap: hasPerView ? t.perViewCap : null,
  };
}
