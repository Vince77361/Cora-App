import '../../offer_terms/domain/offer_terms.dart';
import '../../store_browse/domain/store_summary.dart';
import 'offer_view.dart';

/// 크리에이터가 받은 오퍼 하나. 조건은 보낸 때의 사본이라 가게의 기본 조건이 바뀌어도 그대로다.
class ReceivedOffer {
  const ReceivedOffer({
    required this.id,
    required this.store,
    required this.terms,
    required this.view,
    required this.receivedAt,
    this.storeIntro,
    this.bestShootingTime,
    this.canUndoDecline = false,
  });

  final String id;
  final StoreSummary store;
  final String? storeIntro;
  final String? bestShootingTime;
  final OfferTerms terms;
  final OfferView view;
  final DateTime receivedAt;

  /// 방금 거절해 30초 안에 되돌릴 수 있다.
  final bool canUndoDecline;

  ReceivedOffer copyWith({OfferView? view, bool? canUndoDecline}) =>
      ReceivedOffer(
        id: id,
        store: store,
        storeIntro: storeIntro,
        bestShootingTime: bestShootingTime,
        terms: terms,
        view: view ?? this.view,
        receivedAt: receivedAt,
        canUndoDecline: canUndoDecline ?? this.canUndoDecline,
      );
}
