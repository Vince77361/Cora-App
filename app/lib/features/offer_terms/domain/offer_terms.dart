/// 오퍼(그리고 가게의 기본 조건)에 담기는 콘텐츠 형식. 서버의 `ContentFormat`과 같은 네 가지다.
enum ContentFormat { shorts, reels, cardNews, blog }

/// 보상 방식. 식사권만, 조회수당만, 둘 다.
enum RewardType { voucher, perView, both }

/// 서버가 돌려주는 확정된 조건. 보상에 들어가지 않는 항목은 null이다.
class OfferTerms {
  const OfferTerms({
    required this.format,
    required this.rewardType,
    this.voucherName,
    this.voucherValue,
    this.perViewAmount,
    this.perViewCap,
  });

  final ContentFormat format;
  final RewardType rewardType;
  final String? voucherName;
  final int? voucherValue;

  /// 조회 1회당 금액(원). 서버가 정한 값이라 앱은 보내지 않는다.
  final int? perViewAmount;

  /// 조회수당 지급의 상한(원). 서버가 정한 값이다.
  final int? perViewCap;

  @override
  bool operator ==(Object other) =>
      other is OfferTerms &&
      other.format == format &&
      other.rewardType == rewardType &&
      other.voucherName == voucherName &&
      other.voucherValue == voucherValue &&
      other.perViewAmount == perViewAmount &&
      other.perViewCap == perViewCap;

  @override
  int get hashCode => Object.hash(
    format,
    rewardType,
    voucherName,
    voucherValue,
    perViewAmount,
    perViewCap,
  );
}

/// 사장님이 고른 조건. 조회수당 단가와 상한은 서버가 정하므로 담지 않는다.
class OfferTermsInput {
  const OfferTermsInput({
    required this.format,
    required this.rewardType,
    this.voucherName,
    this.voucherValue,
  });

  final ContentFormat format;
  final RewardType rewardType;
  final String? voucherName;
  final int? voucherValue;

  @override
  bool operator ==(Object other) =>
      other is OfferTermsInput &&
      other.format == format &&
      other.rewardType == rewardType &&
      other.voucherName == voucherName &&
      other.voucherValue == voucherValue;

  @override
  int get hashCode =>
      Object.hash(format, rewardType, voucherName, voucherValue);
}
