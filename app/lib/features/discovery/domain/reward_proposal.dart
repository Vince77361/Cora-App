import '../../offer_terms/domain/offer_terms.dart';

/// 브랜드가 관심에 붙이는 보상 제안(F2의 `이 조건으로 보내기`가 만든다). 서버의 `BrandProposalDto`와
/// 같은 모양이다. F1의 `OfferTerms`에서 이 값으로 바꾸는 곳은 [RewardProposal.fromTerms] 한 곳이고,
/// 서로 관심 전(`decide`)과 뒤(`proposeReward`)가 같은 값을 쓴다.
class RewardProposal {
  const RewardProposal({
    required this.fee,
    required this.productProvided,
    this.performance,
  });

  /// F1에서 고른 조건을 보낼 모양으로 바꾼다. 현금 고정비는 고정 현금, 제품 제공은 `혜택`이 켜졌는지,
  /// 성과 추가는 조회수 수당이다(브랜드의 제안은 제품 제공을 이름만 있는 혜택으로 든다).
  factory RewardProposal.fromTerms(OfferTerms terms) {
    final viewPay = terms.reward.viewPay;
    return RewardProposal(
      fee: terms.reward.fixedCash,
      productProvided: terms.reward.voucher != null,
      performance: viewPay == null
          ? null
          : (ratePer1000: viewPay.ratePerThousand, cap: viewPay.cap),
    );
  }

  /// 현금 고정비(원).
  final int fee;
  final bool productProvided;

  /// 성과 추가(조회수 1,000회당 단가와 상한). 없으면 null.
  final ({int ratePer1000, int cap})? performance;

  @override
  bool operator ==(Object other) =>
      other is RewardProposal &&
      other.fee == fee &&
      other.productProvided == productProvided &&
      other.performance == performance;

  @override
  int get hashCode => Object.hash(fee, productProvided, performance);
}
