/// 오퍼(그리고 가게의 모집 조건)에 담기는 콘텐츠 형식. 서버의 `ContentFormat`과 같은 네 가지다.
enum ContentFormat { shorts, reels, cardNews, blog }

/// 콘텐츠 사용권. 서버의 `UsageRights`와 같은 세 가지다.
enum UsageRights { storeRepost3m, storeRepost6m, none }

/// 제공 혜택(식사권). 현금과 더하지 않고 방문 때 가게에서 준다. 인원은 모를 수 있다(옛 조건).
class Voucher {
  const Voucher({required this.name, required this.value, this.people});

  final String name;

  /// 금액(원). 보여 주는 값일 뿐 현금 부담에 들어가지 않는다.
  final int value;
  final int? people;

  Voucher copyWith({String? name, int? value, int? people}) => Voucher(
    name: name ?? this.name,
    value: value ?? this.value,
    people: people ?? this.people,
  );

  @override
  bool operator ==(Object other) =>
      other is Voucher &&
      other.name == name &&
      other.value == value &&
      other.people == people;

  @override
  int get hashCode => Object.hash(name, value, people);
}

/// 조회수 수당. 단가는 1,000회당 원이고, 상한은 크리에이터 한 명에게 줄 수 있는 최대(원)다.
class ViewPay {
  const ViewPay({required this.ratePerThousand, required this.cap});

  final int ratePerThousand;
  final int cap;

  ViewPay copyWith({int? ratePerThousand, int? cap}) => ViewPay(
    ratePerThousand: ratePerThousand ?? this.ratePerThousand,
    cap: cap ?? this.cap,
  );

  @override
  bool operator ==(Object other) =>
      other is ViewPay &&
      other.ratePerThousand == ratePerThousand &&
      other.cap == cap;

  @override
  int get hashCode => Object.hash(ratePerThousand, cap);
}

/// 보상 세 요소: 제공 혜택, 고정 현금, 조회수 수당. 없는 요소는 null(고정 현금은 0)이다.
class Reward {
  const Reward({this.voucher, this.fixedCash = 0, this.viewPay});

  final Voucher? voucher;

  /// 고정 현금(원). 없으면 0.
  final int fixedCash;
  final ViewPay? viewPay;

  /// 최대 현금 부담 = 고정 현금 + 조회수 수당 상한. 제공 혜택은 현금이 아니라 더하지 않는다.
  ///
  /// 서버의 `reward-terms.ts`와 같은 식이다. F1이 입력할 때마다 바로 보여 주려고 앱에도 두고,
  /// 같은 숫자로 고정하는 테스트가 있다. 결제 금액은 서버 견적만 쓴다.
  int get maxCashBurden => fixedCash + (viewPay?.cap ?? 0);

  /// 세 요소가 모두 없다. 이런 보상은 보낼 수 없다.
  bool get isEmpty => voucher == null && fixedCash == 0 && viewPay == null;

  Reward withVoucher(Voucher? voucher) =>
      Reward(voucher: voucher, fixedCash: fixedCash, viewPay: viewPay);

  Reward withFixedCash(int fixedCash) =>
      Reward(voucher: voucher, fixedCash: fixedCash, viewPay: viewPay);

  Reward withViewPay(ViewPay? viewPay) =>
      Reward(voucher: voucher, fixedCash: fixedCash, viewPay: viewPay);

  @override
  bool operator ==(Object other) =>
      other is Reward &&
      other.voucher == voucher &&
      other.fixedCash == fixedCash &&
      other.viewPay == viewPay;

  @override
  int get hashCode => Object.hash(voucher, fixedCash, viewPay);
}

/// 오퍼 보내기(A5)가 보여 주는 빠른 보상 조합 셋. F1에서 요소를 따로 고른 보상은 어느 쪽에도 맞지 않을 수 있다.
enum RewardPreset { benefitOnly, fixedCash, benefitAndViewPay }

/// [reward]가 맞는 빠른 조합. 요소가 정확히 그 조합일 때만 맞고(금액은 따지지 않는다),
/// 섞인 보상이거나 비어 있으면 null이다.
RewardPreset? presetOf(Reward reward) {
  final hasVoucher = reward.voucher != null;
  final hasViewPay = reward.viewPay != null;
  final hasCash = reward.fixedCash > 0;
  if (hasCash) {
    return !hasVoucher && !hasViewPay ? RewardPreset.fixedCash : null;
  }
  if (hasVoucher && hasViewPay) return RewardPreset.benefitAndViewPay;
  if (hasVoucher) return RewardPreset.benefitOnly;
  return null;
}

/// [preset]의 요소만 [base]에서 가져와 보상을 만든다. [base]는 세 요소의 값을 모두 든 보상이고
/// (없던 요소의 기본값을 채운 것), 조합에 없는 요소는 버린다.
Reward applyPreset(Reward base, RewardPreset preset) => switch (preset) {
  RewardPreset.benefitOnly => Reward(voucher: base.voucher),
  RewardPreset.fixedCash => Reward(fixedCash: base.fixedCash),
  RewardPreset.benefitAndViewPay => Reward(
    voucher: base.voucher,
    viewPay: base.viewPay,
  ),
};

/// 이용료(원) = 최대 현금 부담 × 수수료율(%)의 내림. 서버의 `Math.floor(최대 현금 부담 × 수수료율 / 100)`과
/// 같다. 미리보기용이고 결제할 금액은 서버 견적이 정한다.
int feeAmount(int maxCashBurden, int feeRate) => maxCashBurden * feeRate ~/ 100;

/// 확정됐거나 고르는 중인 조건. 보낼 때도 이것을 쓴다.
class OfferTerms {
  const OfferTerms({
    required this.format,
    this.pieces = 1,
    required this.reward,
    this.usageRights = UsageRights.storeRepost3m,
  });

  final ContentFormat format;

  /// 콘텐츠 편 수. 오퍼는 지금 한 편이다.
  final int pieces;
  final Reward reward;
  final UsageRights usageRights;

  /// 블로그 글은 조회수를 셀 수 없어 조회수 수당을 쓸 수 없다(공통 모델).
  bool get viewPayAllowed => format != ContentFormat.blog;

  OfferTerms copyWith({
    ContentFormat? format,
    int? pieces,
    Reward? reward,
    UsageRights? usageRights,
  }) => OfferTerms(
    format: format ?? this.format,
    pieces: pieces ?? this.pieces,
    reward: reward ?? this.reward,
    usageRights: usageRights ?? this.usageRights,
  );

  @override
  bool operator ==(Object other) =>
      other is OfferTerms &&
      other.format == format &&
      other.pieces == pieces &&
      other.reward == reward &&
      other.usageRights == usageRights;

  @override
  int get hashCode => Object.hash(format, pieces, reward, usageRights);
}
