import '../../offer_terms/domain/offer_terms.dart';
import '../../offer_terms/presentation/offer_terms_text.dart';

/// 조회수 수당이 들어간 조건의 한 줄. `1,000회당 2,000원, 최대 60,000원`. 조회수 수당이 없으면 null.
/// 문구는 가게 둘러보기 화면 작업이 바꾼다.
String? perViewLine(OfferTerms terms) {
  final viewPay = terms.reward.viewPay;
  return viewPay == null ? null : viewPayLineComma(viewPay);
}

/// D2 보상 칸의 두 줄. 둘째 줄이 없으면 null. 문구는 가게 둘러보기 화면 작업이 바꾼다.
({String title, String? note}) detailReward(OfferTerms terms) {
  final reward = terms.reward;
  final voucher = reward.voucher;
  final viewPay = reward.viewPay;
  final title = rewardHeadline(reward);
  if (viewPay != null) {
    return (title: title, note: '조회수 수당은 ${capLabel(viewPay.cap)}');
  }
  return (
    title: title,
    note: voucher == null ? null : '약 ${won(voucher.value)} 상당',
  );
}
