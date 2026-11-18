import 'package:cora_api/api.dart' as api;

import '../../../core/network/api_error.dart';
import '../../../core/ui/swipe_deck/swipe_physics.dart' show SwipeOutcome;
import '../../discovery/domain/featured_post_ref.dart';
import '../../discovery/domain/pass_reason.dart';
import '../domain/store_creator_card.dart';
import '../domain/store_discover_repository.dart';

/// 생성된 API 클라이언트(`cora_api`)로 사장님의 전체 둘러보기를 주고받는다. 생성된 타입은 이 파일 밖으로
/// 내보내지 않는다.
class ApiStoreDiscoverRepository implements StoreDiscoverRepository {
  ApiStoreDiscoverRepository(api.ApiClient client)
    : _recommendations = api.RecommendationsApi(client),
      _discovery = api.DiscoveryApi(client);

  final api.RecommendationsApi _recommendations;
  final api.DiscoveryApi _discovery;

  @override
  Future<({int total, List<StoreCreatorCard> cards})> fetchCards() =>
      _guard(() async {
        final model = await _recommendations.listStoreCreatorRecommendations();
        if (model == null) throw const StoreDiscoverFailure();
        return (
          total: model.total,
          cards: [for (final c in model.cards) _card(c)],
        );
      });

  @override
  Future<void> decide(String creatorId, SwipeOutcome outcome) =>
      _guard(() async {
        // 사장님 하트에 글(note)이나 조건 제안을 붙이면 서버가 400으로 거절하므로 보내지 않는다.
        await _discovery.putDecision(
          api.PutDecisionDto(
            decision: switch (outcome) {
              SwipeOutcome.like => api.SwipeDecisionKind.LIKE,
              SwipeOutcome.pass => api.SwipeDecisionKind.PASS,
              SwipeOutcome.hold => api.SwipeDecisionKind.HOLD,
            },
            targetId: creatorId,
            targetKind: api.DecisionTargetKind.CREATOR,
          ),
        );
      });

  @override
  Future<void> setPassReason(String creatorId, PassReason reason) => _guard(
    () => _discovery.putPassReason(
      api.PassReasonDto(
        reason: switch (reason) {
          PassReason.mood => api.PassReason.MOOD,
          PassReason.region => api.PassReason.REGION,
          PassReason.fee => api.PassReason.FEE,
          PassReason.field => api.PassReason.FIELD,
        },
        targetId: creatorId,
        targetKind: api.SwipeTargetKind.CREATOR,
      ),
    ),
  );

  @override
  Future<String?> undoLast() => _guard(() async {
    // 되돌릴 것이 없으면 서버는 본문 없는 200으로 답하고, 생성된 클라이언트는 그것을 null로 읽는다.
    // 서로 관심이 된 카드는 서버가 409로 거절한다. 사용자에게는 같은 "되돌릴 수 없어요"다.
    final api.UndoneDecisionModel? model;
    try {
      model = await _discovery.undoLastDecision();
    } catch (error) {
      if (ApiError.from(error).isConflict) return null;
      rethrow;
    }
    return model?.targetId;
  });

  static StoreCreatorCard _card(api.StoreCreatorCardModel m) =>
      StoreCreatorCard(
        creatorId: m.creatorId,
        displayName: m.displayName,
        contentFocus: m.contentFocus,
        followers: m.followers,
        headline: m.headline,
        photoUrl: m.photoUrl,
        posts: [
          for (final p in m.posts)
            FeaturedPostRef(photoUrl: p.photoUrl, caption: p.caption),
        ],
        tags: List.unmodifiable(m.tags),
      );

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on StoreDiscoverFailure {
      rethrow;
    } catch (_) {
      throw const StoreDiscoverFailure();
    }
  }
}
