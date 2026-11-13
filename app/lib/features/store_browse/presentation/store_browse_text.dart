import '../../offer_terms/domain/offer_terms.dart';
import '../../offer_terms/presentation/offer_terms_text.dart';

/// D2 보상 칸의 두 줄. 값은 `식사권 40,000원 · 2인 + 조회수 수당`, 둘째 줄은 조회수 수당이 있을 때만
/// `1,000회당 2,000원 · 1인 최대 60,000원`이다.
({String title, String? note}) detailReward(OfferTerms terms) {
  final viewPay = terms.reward.viewPay;
  return (
    title: rewardHeadline(terms.reward),
    note: viewPay == null ? null : viewPayLine(viewPay),
  );
}
