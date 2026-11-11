import 'package:cora_api/api.dart' as api;

import '../../../core/network/api_error.dart';
import '../../offer_terms/data/offer_terms_from_wire.dart';
import '../../store_browse/data/api_store_browse_repository.dart'
    show summaryFromWire;
import '../domain/offer_view.dart';
import '../domain/received_offer.dart';
import '../domain/received_offers_repository.dart';

/// 생성된 API 클라이언트(`cora_api`)로 받은 오퍼를 읽고 답한다. 생성된 타입은 이 파일 밖으로
/// 내보내지 않는다.
class ApiReceivedOffersRepository implements ReceivedOffersRepository {
  ApiReceivedOffersRepository(api.ApiClient client)
    : _offers = api.OffersApi(client);

  final api.OffersApi _offers;

  @override
  Future<List<ReceivedOffer>> fetchNew() => _list(api.ReceivedOfferTab.new_);

  @override
  Future<List<ReceivedOffer>> fetchActive() =>
      _list(api.ReceivedOfferTab.active);

  Future<List<ReceivedOffer>> _list(api.ReceivedOfferTab tab) =>
      _guard(() async {
        final rows = await _offers.listReceivedOffers(tab);
        if (rows == null) throw const ReceivedOffersFailure();
        return [for (final m in rows) _fromModel(m)];
      });

  @override
  Future<void> accept(String id) => _guard(() => _offers.acceptOffer(id));

  @override
  Future<void> decline(String id) => _guard(() => _offers.declineOffer(id));

  @override
  Future<void> undoDecline(String id) =>
      _guard(() => _offers.undoDeclineOffer(id));

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on ReceivedOffersFailure {
      rethrow;
    } catch (error) {
      throw ReceivedOffersFailure(conflict: ApiError.from(error).isConflict);
    }
  }

  static ReceivedOffer _fromModel(api.ReceivedOfferModel m) => ReceivedOffer(
    id: m.id,
    store: summaryFromWire(m.store),
    storeIntro: m.storeIntro,
    bestShootingTime: m.bestShootingTime,
    terms: offerTermsFromWire(m.terms),
    view: switch (m.view) {
      api.OfferView.ACCEPTED => OfferView.accepted,
      api.OfferView.DECLINED => OfferView.declined,
      api.OfferView.EXPIRED => OfferView.expired,
      api.OfferView.CANCELLED => OfferView.cancelled,
      _ => OfferView.waiting,
    },
    receivedAt: m.receivedAt,
    canUndoDecline: m.canUndoDecline,
  );
}
