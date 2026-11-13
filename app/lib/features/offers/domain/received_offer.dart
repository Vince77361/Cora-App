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
    required this.version,
    this.storeIntro,
    this.bestShootingTime,
    this.canUndoDecline = false,
    this.needsInstagram = false,
  });

  final String id;
  final StoreSummary store;
  final String? storeIntro;
  final String? bestShootingTime;
  final OfferTerms terms;
  final OfferView view;
  final DateTime receivedAt;

  /// 지금 보고 있는 판본의 번호. 수락은 이 번호와 함께 보내, 그사이 새 판본이 나왔으면 서버가 거절한다.
  final int version;

  /// 방금 거절해 30초 안에 되돌릴 수 있다.
  final bool canUndoDecline;

  /// 조회수 보상을 받으려면 인스타그램 연동이 필요한데 아직 연동하지 않았다. 이 오퍼는 수락할 수 없다.
  /// 서버는 답을 기다리는 오퍼에서만 true로 보낸다.
  final bool needsInstagram;

  ReceivedOffer copyWith({OfferView? view, bool? canUndoDecline}) =>
      ReceivedOffer(
        id: id,
        store: store,
        storeIntro: storeIntro,
        bestShootingTime: bestShootingTime,
        terms: terms,
        view: view ?? this.view,
        receivedAt: receivedAt,
        version: version,
        canUndoDecline: canUndoDecline ?? this.canUndoDecline,
        needsInstagram: needsInstagram,
      );
}
