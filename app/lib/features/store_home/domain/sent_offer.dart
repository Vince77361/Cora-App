import '../../offer_terms/domain/offer_terms.dart';
import '../../offers/domain/offer_view.dart';
import 'applicant.dart';

/// 사장님이 보낸 오퍼 한 건. 상태([view])는 서버가 사장님 쪽에 맞게 풀어서 보낸다.
class SentOffer {
  const SentOffer({
    required this.id,
    required this.creator,
    required this.terms,
    required this.view,
    this.paymentDaysLeft,
  });

  final String id;
  final CreatorSummary creator;
  final OfferTerms terms;
  final OfferView view;

  /// 수락한 오퍼에서 결제까지 남은 날. 수락하지 않았으면 null.
  final int? paymentDaysLeft;

  /// 아직 되돌릴 수 있는 오퍼(답을 기다리거나, 수락됐지만 결제 전). 취소는 이때만 한다.
  bool get cancellable =>
      view == OfferView.waiting || view == OfferView.accepted;
}
