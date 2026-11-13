import '../../offer_terms/domain/offer_terms.dart';

/// 고를 수 있는 값의 범위(최소, 최대, 눈금, 기본). 서버의 `REWARD_POLICY`를 `GET /config`로 받은 것이다.
class StepRange {
  const StepRange({
    required this.min,
    required this.max,
    required this.step,
    required this.defaultValue,
  });

  final int min;
  final int max;
  final int step;
  final int defaultValue;

  /// 고를 수 있는 값을 작은 것부터. 눈금마다 하나씩이다.
  List<int> get values => [for (var v = min; v <= max; v += step) v];

  bool contains(int value) =>
      value >= min && value <= max && (value - min) % step == 0;
}

/// 고정 현금의 범위. 최대는 맡기는 쪽(가게, 브랜드)에 따라 다르다.
class FixedCashLimits {
  const FixedCashLimits({
    required this.storeMax,
    required this.brandMax,
    required this.step,
    required this.presets,
  });

  final int storeMax;
  final int brandMax;
  final int step;

  /// 빠른 선택 알약(`없음`, `3만 원`…). 0이 `없음`이다.
  final List<int> presets;
}

/// 제공 혜택(식사권)의 기본값.
class VoucherDefaults {
  const VoucherDefaults({
    required this.name,
    required this.value,
    required this.people,
    required this.maxPeople,
  });

  final String name;
  final int value;
  final int people;
  final int maxPeople;
}

/// 보상을 고를 때 쓰는 범위와 기본값.
class RewardLimits {
  const RewardLimits({
    required this.viewRate,
    required this.perViewCap,
    required this.fixedCash,
    required this.voucher,
    required this.usageRightsDefault,
    required this.countingDays,
  });

  /// 조회수 수당 단가(1,000회당 원).
  final StepRange viewRate;

  /// 조회수 수당 상한(원).
  final StepRange perViewCap;
  final FixedCashLimits fixedCash;
  final VoucherDefaults voucher;
  final UsageRights usageRightsDefault;

  /// 게시 뒤 조회수를 재는 기간(일).
  final int countingDays;
}

/// 수수료율(%). 최대 현금 부담에 곱해 이용료를 미리 보여 줄 때 쓴다.
class FeeRates {
  const FeeRates({
    required this.storeOffer,
    required this.brandContract,
    required this.bid,
  });

  final int storeOffer;
  final int brandContract;
  final int bid;
}

/// 서버가 내려 주는 범위와 수수료율. 앱에 숫자를 따로 적지 않고 여기서 읽는다.
class ServerConfig {
  const ServerConfig({required this.reward, required this.feeRates});

  final RewardLimits reward;
  final FeeRates feeRates;

  /// 가게가 모집 조건을 아직 정하지 않았을 때 F1이 시작하는 값: 릴스, 기본 식사권, 고정 현금 없음,
  /// 기본 단가와 상한의 조회수 수당, 기본 사용권.
  OfferTerms get defaultTerms => OfferTerms(
    format: ContentFormat.reels,
    reward: Reward(
      voucher: Voucher(
        name: reward.voucher.name,
        value: reward.voucher.value,
        people: reward.voucher.people,
      ),
      viewPay: ViewPay(
        ratePerThousand: reward.viewRate.defaultValue,
        cap: reward.perViewCap.defaultValue,
      ),
    ),
    usageRights: reward.usageRightsDefault,
  );
}
