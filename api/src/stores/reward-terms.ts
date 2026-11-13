import { ContentFormat, Prisma, UsageRights } from '@prisma/client';
import { REWARD_POLICY } from '../common/collaboration-policy';
import { AppError } from '../common/errors/app-error';
import { josa } from '../common/josa';
import { OfferTermsModel } from './dto/offer-terms.model';

// 보상의 세 요소(식사권, 고정 현금, 조회수 수당)를 한 모양으로 다루는 순수 함수 모음.
// 최대 현금 부담·지급 방식 같은 파생 값은 여기서만 만든다.
// 협업의 조건 사본을 읽는 곳도 readTerms 하나다(옛 모양의 사본은 fromLegacyTerms로 읽는다).

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
      `${josa(label, '은/는')} ${range.min.toLocaleString('ko-KR')}원부터 ${range.max.toLocaleString('ko-KR')}원까지 ${range.step.toLocaleString('ko-KR')}원 단위로 정해 주세요.`,
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
// 옛 보상 종류. Prisma enum(RewardType)은 지워졌고, 이미 저장된 옛 사본을 읽을 때만 쓴다.
export type LegacyRewardType = 'VOUCHER' | 'PER_VIEW' | 'BOTH';

// 옛 2번 계획의 식사권 기본 이름. 이름에서 인원(2명)을 알 수 있는 것은 이것뿐이다.
const LEGACY_DEFAULT_VOUCHER_NAME = '2인 식사권';

export function fromLegacyTerms(t: {
  rewardType: LegacyRewardType;
  voucherName: string | null;
  voucherValue: number | null;
  perViewAmount: number | null;
  perViewCap: number | null;
}): RewardTerms {
  const hasVoucher = t.rewardType === 'VOUCHER' || t.rewardType === 'BOTH';
  const hasPerView = t.rewardType === 'PER_VIEW' || t.rewardType === 'BOTH';
  const isDefaultName = t.voucherName === LEGACY_DEFAULT_VOUCHER_NAME;
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

// 오퍼와 가게 기본 조건이 같이 쓰는 조건 모양: 보상 세 요소에 형식, 편 수, 사용권, 계산 값 둘을 붙인다.
export function termsModelOf(
  format: ContentFormat,
  reward: RewardTerms,
  usageRights: UsageRights,
): OfferTermsModel {
  return {
    format,
    // 오퍼는 지금 한 편짜리다(편 수를 고르는 화면이 없다).
    pieces: 1,
    ...reward,
    usageRights,
    maxCashBurden: maxCashBurden(reward),
    settlementMethod: settlementMethodOfReward(reward),
  };
}

// 가게의 기본 조건(저장된 열). 오퍼의 빈 값을 채울 때 정책 기본값보다 먼저 쓴다.
export type RewardDefaults = Partial<RewardTerms> & {
  usageRights?: UsageRights;
};

export function defaultsOfStore(store: {
  defaultVoucherName: string | null;
  defaultVoucherValue: number | null;
  defaultVoucherPeople: number | null;
  defaultViewRatePerThousand: number | null;
  defaultPerViewCap: number | null;
  defaultUsageRights: UsageRights;
}): RewardDefaults {
  return {
    voucherName: store.defaultVoucherName,
    voucherValue: store.defaultVoucherValue,
    voucherPeople: store.defaultVoucherPeople,
    viewRatePerThousand: store.defaultViewRatePerThousand,
    perViewCap: store.defaultPerViewCap,
    usageRights: store.defaultUsageRights,
  };
}

// 입력을 저장·표시용 조건으로 정리한다. 가게 기본 조건과 오퍼가 같은 규칙을 쓴다.
export function buildTerms(
  input: {
    format: ContentFormat;
    reward: RewardInput;
    usageRights?: UsageRights;
  },
  defaults: RewardDefaults = {},
): OfferTermsModel {
  const reward = buildReward(input.reward, {
    format: input.format,
    defaults,
  });
  return termsModelOf(
    input.format,
    reward,
    input.usageRights ??
      defaults.usageRights ??
      REWARD_POLICY.usageRightsDefault,
  );
}

// 협업에 저장하는 조건 사본. 계산 값(최대 현금 부담, 정산 방식)은 넣지 않고 읽을 때 계산한다.
export function copyOfTerms(terms: OfferTermsModel): Prisma.InputJsonObject {
  return {
    format: terms.format,
    pieces: terms.pieces,
    voucherName: terms.voucherName,
    voucherValue: terms.voucherValue,
    voucherPeople: terms.voucherPeople,
    fixedCash: terms.fixedCash,
    viewRatePerThousand: terms.viewRatePerThousand,
    perViewCap: terms.perViewCap,
    usageRights: terms.usageRights,
  };
}

const LEGACY_REWARD_TYPES: readonly string[] = ['VOUCHER', 'PER_VIEW', 'BOTH'];

// 협업의 조건 사본을 읽는 한 곳이다. 형식이 없으면 데이터가 어긋난 것이라 던진다.
// 이미 결제된 옛 협업의 금액은 바뀌지 않아야 하므로 범위는 검사하지 않는다.
// 옛 모양(rewardType, perViewAmount가 있는 사본)은 이전이 빠뜨린 줄이 있어도 금액이 맞게 fromLegacyTerms로 읽는다.
export function readTerms(json: unknown): OfferTermsModel {
  const t = (typeof json === 'object' && json !== null ? json : {}) as Record<
    string,
    unknown
  >;
  const format = (Object.values(ContentFormat) as unknown[]).includes(t.format)
    ? (t.format as ContentFormat)
    : null;
  if (!format) throw new Error('협업의 조건에 콘텐츠 형식이 없어요.');
  const text = (v: unknown) => (typeof v === 'string' ? v : null);
  const int = (v: unknown) =>
    typeof v === 'number' && Number.isInteger(v) ? v : null;

  if ('rewardType' in t || 'perViewAmount' in t) {
    const perViewAmount = int(t.perViewAmount);
    const rewardType: LegacyRewardType =
      typeof t.rewardType === 'string' &&
      LEGACY_REWARD_TYPES.includes(t.rewardType)
        ? (t.rewardType as LegacyRewardType)
        : // 종류 키가 없으면 남은 값으로 짐작한다.
          perViewAmount !== null
          ? text(t.voucherName) !== null
            ? 'BOTH'
            : 'PER_VIEW'
          : 'VOUCHER';
    return termsModelOf(
      format,
      fromLegacyTerms({
        rewardType,
        voucherName: text(t.voucherName),
        voucherValue: int(t.voucherValue),
        perViewAmount,
        perViewCap: int(t.perViewCap),
      }),
      'NONE',
    );
  }
  const usageRights = (Object.values(UsageRights) as unknown[]).includes(
    t.usageRights,
  )
    ? (t.usageRights as UsageRights)
    : 'NONE';
  return termsModelOf(
    format,
    {
      voucherName: text(t.voucherName),
      voucherValue: int(t.voucherValue),
      voucherPeople: int(t.voucherPeople),
      fixedCash: int(t.fixedCash) ?? 0,
      viewRatePerThousand: int(t.viewRatePerThousand),
      perViewCap: int(t.perViewCap),
    },
    usageRights,
  );
}
