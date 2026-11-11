import '../../offer_terms/domain/offer_terms.dart';
import '../../offer_terms/presentation/offer_terms_text.dart';

/// 조회수당이 들어간 조건의 한 줄. `조회 1회당 10원, 최대 10만 원`. 조회수당이 없으면 null.
String? perViewLine(OfferTerms terms) {
  if (terms.rewardType == RewardType.voucher) return null;
  return '조회 1회당 ${won(terms.perViewAmount ?? perViewAmountWon)}, '
      '최대 ${won(terms.perViewCap ?? perViewCapWon)}';
}

/// D2 보상 칸의 두 줄(캔버스 `2인 식사권 + 조회 1회당 10원` / `조회수당은 최대 10만 원`).
/// 둘째 줄이 없으면 null.
({String title, String? note}) detailReward(OfferTerms terms) {
  final name = terms.voucherName ?? defaultVoucherName;
  final amount = won(terms.perViewAmount ?? perViewAmountWon);
  final cap = won(terms.perViewCap ?? perViewCapWon);
  return switch (terms.rewardType) {
    RewardType.voucher => (
      title: name,
      note: '약 ${won(terms.voucherValue ?? defaultVoucherValue)} 상당',
    ),
    RewardType.perView => (title: '조회 1회당 $amount', note: '조회수당은 최대 $cap'),
    RewardType.both => (title: '$name + 조회 1회당 $amount', note: '조회수당은 최대 $cap'),
  };
}
