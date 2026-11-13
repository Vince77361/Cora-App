import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/offers/domain/offer_view.dart';
import 'package:cora/features/offers/domain/received_offer.dart';
import 'package:cora/features/offers/domain/received_offers_repository.dart';

import '../store_browse/fake_store_browse_repository.dart';

/// 받은 오퍼 한 건. 기본은 `한그릇 라멘`이 어제 보낸 릴스 오퍼다.
ReceivedOffer receivedOffer({
  String id = 'o1',
  String storeName = '한그릇 라멘',
  OfferView view = OfferView.waiting,
  DateTime? receivedAt,
  String? storeIntro = '김이 오르는 첫 숟가락 장면을 원해요.',
  String? bestShootingTime = '오후 3시',
  bool canUndoDecline = false,
  bool needsInstagram = false,
  int version = 1,
  bool myTurn = true,
  OfferTerms? terms,
}) => ReceivedOffer(
  id: id,
  store: ramenStore(id: 's-$id', name: storeName),
  storeIntro: storeIntro,
  bestShootingTime: bestShootingTime,
  terms: terms ?? _defaultTerms,
  view: view,
  receivedAt: receivedAt ?? DateTime.utc(2026, 11, 11, 3),
  version: version,
  canUndoDecline: canUndoDecline,
  needsInstagram: needsInstagram,
  myTurn: myTurn,
);

/// 캔버스 A6의 조건: 릴스, 식사권 2인, 조회수 수당(1,000회당 2,000원, 1인 최대 60,000원).
const _defaultTerms = OfferTerms(
  format: ContentFormat.reels,
  reward: Reward(
    voucher: Voucher(name: '식사권', value: 40000, people: 2),
    viewPay: ViewPay(ratePerThousand: 2000, cap: 60000),
  ),
);

/// 손으로 쓴 가짜 받은 오퍼 저장소. 서버의 새 오퍼·거절 되돌리기를 흉내 낸다.
class FakeReceivedOffersRepository implements ReceivedOffersRepository {
  FakeReceivedOffersRepository({List<ReceivedOffer>? newOffers})
    : newOffers = newOffers ?? [];

  List<ReceivedOffer> newOffers;

  bool failFetch = false;

  /// true이면 수락·거절·되돌리기가 서버에서 409를 받는다(그사이 [newOffers]는 그대로 둔다).
  bool conflictOnAnswer = false;
  bool failAnswer = false;

  /// 설정하면 수락이 `STALE_VERSION`(이 번호가 최신 판본)으로 막히고, 그 뒤 [fetchNew]는 [afterStale]를 준다.
  int? staleOnAccept;
  List<ReceivedOffer>? afterStale;

  int fetchNewCalls = 0;
  final List<String> accepted = [];

  /// [accepted]와 같은 순서로, 수락에 실려 온 판본 번호.
  final List<int> acceptedVersions = [];
  final List<String> declined = [];
  final List<String> undone = [];

  @override
  Future<List<ReceivedOffer>> fetchNew() async {
    fetchNewCalls++;
    if (failFetch) throw const ReceivedOffersFailure();
    return List.of(newOffers);
  }

  void _check() {
    if (conflictOnAnswer) throw const ReceivedOffersFailure(conflict: true);
    if (failAnswer) throw const ReceivedOffersFailure();
  }

  ReceivedOffer _find(String id) => newOffers.firstWhere((o) => o.id == id);

  void _replace(String id, ReceivedOffer next) =>
      newOffers = [for (final o in newOffers) o.id == id ? next : o];

  @override
  Future<void> accept(String id, int version) async {
    final stale = staleOnAccept;
    if (stale != null) {
      if (afterStale != null) newOffers = afterStale!;
      throw ReceivedOffersFailure(staleVersion: stale);
    }
    _check();
    accepted.add(id);
    acceptedVersions.add(version);
    newOffers = newOffers.where((o) => o.id != id).toList();
  }

  @override
  Future<void> decline(String id) async {
    _check();
    declined.add(id);
    _replace(
      id,
      _find(id).copyWith(view: OfferView.declined, canUndoDecline: true),
    );
  }

  @override
  Future<void> undoDecline(String id) async {
    _check();
    undone.add(id);
    _replace(
      id,
      _find(id).copyWith(view: OfferView.waiting, canUndoDecline: false),
    );
  }
}
