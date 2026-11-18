import 'package:cora/core/ui/swipe_deck/swipe_physics.dart' show SwipeOutcome;
import 'package:cora/features/discovery/domain/featured_post_ref.dart';
import 'package:cora/features/discovery/domain/pass_reason.dart';
import 'package:cora/features/store_discover/domain/store_creator_card.dart';
import 'package:cora/features/store_discover/domain/store_discover_repository.dart';

/// 손으로 쓴 가짜 사장님 전체 둘러보기 저장소. 오늘 목록과 결정, 되돌리기를 흉내 낸다.
class FakeStoreDiscoverRepository implements StoreDiscoverRepository {
  FakeStoreDiscoverRepository({List<StoreCreatorCard>? cards, int? total})
    : cards = cards ?? [],
      total = total ?? (cards?.length ?? 0);

  /// 서버가 주는 아직 결정하지 않은 카드와 오늘 전체 수.
  List<StoreCreatorCard> cards;
  int total;

  bool failFetch = false;
  bool failDecide = false;
  bool failSetReason = false;
  bool failUndo = false;

  /// true이면 [undoLast]가 되돌릴 것이 없다고(또는 서로 관심이라 못 한다고) 답한다(null).
  bool nothingToUndo = false;

  final decisions = <({String creatorId, SwipeOutcome outcome})>[];
  final reasons = <({String creatorId, PassReason reason})>[];
  int fetchCalls = 0;
  int undoCalls = 0;

  @override
  Future<({int total, List<StoreCreatorCard> cards})> fetchCards() async {
    fetchCalls++;
    if (failFetch) throw const StoreDiscoverFailure();
    final decided = {for (final d in decisions) d.creatorId};
    return (
      total: total,
      cards: [
        for (final c in cards)
          if (!decided.contains(c.creatorId)) c,
      ],
    );
  }

  @override
  Future<void> decide(String creatorId, SwipeOutcome outcome) async {
    if (failDecide) throw const StoreDiscoverFailure();
    decisions.add((creatorId: creatorId, outcome: outcome));
  }

  @override
  Future<void> setPassReason(String creatorId, PassReason reason) async {
    if (failSetReason) throw const StoreDiscoverFailure();
    reasons.add((creatorId: creatorId, reason: reason));
  }

  @override
  Future<String?> undoLast() async {
    undoCalls++;
    if (failUndo) throw const StoreDiscoverFailure();
    if (nothingToUndo || decisions.isEmpty) return null;
    return decisions.removeLast().creatorId;
  }
}

/// 대표 게시물 [postCount]개를 가진 카드. 게시물 i의 한 줄은 `{name} 게시물 i`다.
StoreCreatorCard storeCard(
  String id, {
  String name = '하루 한 컵',
  int postCount = 4,
  String? contentFocus = '리빙 릴스',
  int? followers = 640,
  List<String> tags = const ['리빙', '아침루틴'],
}) {
  final posts = [
    for (var i = 1; i <= postCount; i++)
      FeaturedPostRef(photoUrl: null, caption: '$name 게시물 $i'),
  ];
  return StoreCreatorCard(
    creatorId: id,
    displayName: name,
    contentFocus: contentFocus,
    followers: followers,
    headline: posts.isEmpty ? null : posts.first.caption,
    photoUrl: null,
    posts: posts,
    tags: tags,
  );
}
