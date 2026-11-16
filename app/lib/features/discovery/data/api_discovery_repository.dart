import 'package:cora_api/api.dart' as api;

import '../../../core/network/api_error.dart';
import '../../../core/ui/swipe_deck/swipe_physics.dart' show SwipeOutcome;
import '../../principles/domain/principles.dart' show FeeBand;
import '../../store_browse/data/api_store_browse_repository.dart'
    show summaryFromWire;
import '../domain/discovery_card.dart';
import '../domain/discovery_repository.dart';
import '../domain/discovery_target.dart';
import '../domain/pass_reason.dart';
import '../domain/reward_proposal.dart';

/// 생성된 API 클라이언트(`cora_api`)로 발견(추천 카드, 결정, 되돌리기)을 주고받는다. 생성된 타입은
/// 이 파일 밖으로 내보내지 않는다.
class ApiDiscoveryRepository implements DiscoveryRepository {
  ApiDiscoveryRepository(api.ApiClient client)
    : _recommendations = api.RecommendationsApi(client),
      _discovery = api.DiscoveryApi(client);

  final api.RecommendationsApi _recommendations;
  final api.DiscoveryApi _discovery;

  @override
  Future<({int total, List<CreatorCard> cards})> fetchCreatorCards() =>
      _guard(() async {
        final model = await _recommendations.listCreatorRecommendations();
        if (model == null) throw const DiscoveryFailure();
        return (
          total: model.total,
          cards: [for (final c in model.cards) _creatorCard(c)],
        );
      });

  @override
  Future<({int total, List<DiscoveryCard> cards})> fetchCampaignCards() =>
      _guard(() async {
        final model = await _recommendations.listCampaignRecommendations();
        if (model == null) throw const DiscoveryFailure();
        return (
          total: model.total,
          cards: [for (final c in model.cards) _discoveryCard(c)],
        );
      });

  @override
  Future<List<PreviewCard>> fetchPreviewCards() => _guard(() async {
    final model = await _recommendations.listPreviewCards();
    if (model == null) throw const DiscoveryFailure();
    return [
      for (final c in model.cards)
        PreviewCard(
          creatorId: c.creatorId,
          displayName: c.displayName,
          headline: c.headline,
          photoUrl: c.photoUrl,
          feeBand: _feeBand(c.feeBand),
          tags: List.unmodifiable(c.tags),
        ),
    ];
  });

  @override
  Future<DecisionResult> decide(
    DiscoveryTarget target,
    SwipeOutcome outcome, {
    String? note,
    RewardProposal? proposal,
  }) => _guard(() async {
    if (target.kind == DiscoveryTargetKind.store) {
      // 가게 쪽 결정 가운데 서버에 따로 길이 있는 것은 넘김뿐이다. 지원(관심)은 가게 흐름이 한다.
      if (outcome != SwipeOutcome.pass) {
        throw ArgumentError('가게에는 넘김만 보낸다: $outcome');
      }
      await _discovery.putStorePass(target.id);
      return const DecisionResult();
    }
    final model = await _putDecision(
      decision: switch (outcome) {
        SwipeOutcome.like => api.SwipeDecisionKind.LIKE,
        SwipeOutcome.pass => api.SwipeDecisionKind.PASS,
        SwipeOutcome.hold => api.SwipeDecisionKind.HOLD,
      },
      note: note,
      proposal: proposal,
      target: target,
    );
    if (model == null) throw const DiscoveryFailure();
    return DecisionResult(
      matched: model.matched,
      collaborationId: model.collaborationId,
    );
  });

  @override
  Future<void> setPassReason(DiscoveryTarget target, PassReason reason) =>
      _guard(
        () => _discovery.putPassReason(
          api.PassReasonDto(
            reason: switch (reason) {
              PassReason.mood => api.PassReason.MOOD,
              PassReason.region => api.PassReason.REGION,
              PassReason.fee => api.PassReason.FEE,
              PassReason.field => api.PassReason.FIELD,
            },
            targetId: target.id,
            targetKind: _swipeTargetKind(target.kind),
          ),
        ),
      );

  @override
  Future<DiscoveryTarget?> undoLast() => _guard(() async {
    // 되돌릴 것이 없으면 서버는 본문 없는 200으로 답하고, 생성된 클라이언트는 그것을 null로 읽는다.
    // 서로 관심이 된 카드는 서버가 409로 거절한다. 사용자에게는 같은 "되돌릴 수 없어요"다.
    final api.UndoneDecisionModel? model;
    try {
      model = await _discovery.undoLastDecision();
    } catch (error) {
      if (ApiError.from(error).isConflict) return null;
      rethrow;
    }
    if (model == null) return null;
    return DiscoveryTarget(switch (model.targetKind) {
      api.SwipeTargetKind.CREATOR => DiscoveryTargetKind.creator,
      api.SwipeTargetKind.CAMPAIGN => DiscoveryTargetKind.campaign,
      _ => DiscoveryTargetKind.store,
    }, model.targetId);
  });

  /// 결정을 보낸다. 생성된 `PutDecisionDto`는 값이 없는 `note`·`proposal`을 `null`로 실어 보내는데,
  /// 서버는 `null`을 "보내지 않음"으로 읽지 못해 500을 낸다(`cleanNote`가 `null.trim()`). 서버 규칙은
  /// "빠뜨리면 저장된 값을 그대로 둔다"이므로 값이 없는 칸은 본문에서 뺀다. 서버가 `null`도 받게 고치면
  /// 이 우회는 `putDecision(PutDecisionDto(...))`로 되돌릴 수 있다.
  Future<api.DecisionResultModel?> _putDecision({
    required api.SwipeDecisionKind decision,
    required DiscoveryTarget target,
    String? note,
    RewardProposal? proposal,
  }) async {
    final body = <String, Object?>{
      'decision': decision.toJson(),
      'targetId': target.id,
      'targetKind':
          (target.kind == DiscoveryTargetKind.creator
                  ? api.DecisionTargetKind.CREATOR
                  : api.DecisionTargetKind.CAMPAIGN)
              .toJson(),
      'note': ?note,
      'proposal': ?(proposal == null ? null : _proposalJson(proposal)),
    };
    final client = _discovery.apiClient;
    final response = await client.invokeAPI(
      '/discovery/decisions',
      'PUT',
      <api.QueryParam>[],
      body,
      <String, String>{},
      <String, String>{},
      'application/json',
    );
    if (response.statusCode >= 400) {
      throw api.ApiException(response.statusCode, response.body);
    }
    if (response.body.isEmpty || response.statusCode == 204) return null;
    return await client.deserializeAsync(response.body, 'DecisionResultModel')
        as api.DecisionResultModel;
  }

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DiscoveryFailure {
      rethrow;
    } on ArgumentError {
      rethrow;
    } catch (_) {
      throw const DiscoveryFailure();
    }
  }

  static api.SwipeTargetKind _swipeTargetKind(DiscoveryTargetKind kind) =>
      switch (kind) {
        DiscoveryTargetKind.creator => api.SwipeTargetKind.CREATOR,
        DiscoveryTargetKind.campaign => api.SwipeTargetKind.CAMPAIGN,
        DiscoveryTargetKind.store => api.SwipeTargetKind.STORE,
      };

  static Map<String, Object?> _proposalJson(RewardProposal p) => {
    'fee': p.fee,
    'productProvided': p.productProvided,
    'performance': ?(p.performance == null
        ? null
        : {
            'ratePer1000': p.performance!.ratePer1000,
            'cap': p.performance!.cap,
          }),
  };

  static CreatorCard _creatorCard(api.CreatorCardModel m) => CreatorCard(
    creatorId: m.creatorId,
    displayName: m.displayName,
    headline: m.headline,
    photoUrl: m.photoUrl,
    feeBand: _feeBand(m.feeBand),
    tags: List.unmodifiable(m.tags),
    reasons: [for (final r in m.reasons) _reason(r)],
    theyLikedMe: m.theyLikedMe,
  );

  static DiscoveryCard _discoveryCard(api.CampaignListCardModel m) {
    if (m.kind == api.CampaignListCardKind.STORE && m.store != null) {
      return StoreCard(
        store: summaryFromWire(m.store!),
        headline: m.headline,
        rewardLine: m.rewardLine,
        otherSido: m.otherSido,
        photoUrl: m.photoUrl,
        tags: List.unmodifiable(m.tags),
        reasons: [for (final r in m.reasons) _reason(r)],
      );
    }
    return CampaignCard(
      campaignId: m.campaignId ?? '',
      brandName: m.brandName ?? '',
      brandTagline: m.brandTagline,
      headline: m.headline,
      fee: m.fee ?? 0,
      productProvided: m.productProvided ?? false,
      photoUrl: m.photoUrl,
      tags: List.unmodifiable(m.tags),
      reasons: [for (final r in m.reasons) _reason(r)],
    );
  }

  static MatchReason _reason(api.MatchReason r) => switch (r) {
    api.MatchReason.FIELD => MatchReason.field,
    api.MatchReason.FACE => MatchReason.face,
    api.MatchReason.SCRIPT => MatchReason.script,
    api.MatchReason.FEE => MatchReason.fee,
    _ => MatchReason.trial,
  };

  static FeeBand _feeBand(api.FeeBand b) => switch (b) {
    api.FeeBand.W200K => FeeBand.w200k,
    api.FeeBand.W300K => FeeBand.w300k,
    api.FeeBand.W400K => FeeBand.w400k,
    _ => FeeBand.w500kPlus,
  };
}
