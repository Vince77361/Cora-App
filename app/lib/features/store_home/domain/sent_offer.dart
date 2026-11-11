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
    this.collaborationId,
  });

  final String id;
  final CreatorSummary creator;
  final OfferTerms terms;
  final OfferView view;

  /// 수락한 오퍼에서 결제까지 남은 날. 수락하지 않았으면 null.
  final int? paymentDaysLeft;

  /// 수락해서 만들어진 협업. 결제 화면(A8)이 이것으로 견적을 읽는다. 수락하기 전에는 null.
  final String? collaborationId;

  /// 아직 되돌릴 수 있는 오퍼(답을 기다리거나, 수락됐지만 결제 전). 취소는 이때만 한다.
  bool get cancellable =>
      view == OfferView.waiting || view == OfferView.accepted;
}
