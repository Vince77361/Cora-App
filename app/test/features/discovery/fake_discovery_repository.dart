import 'package:cora/core/ui/swipe_deck/swipe_physics.dart' show SwipeOutcome;
import 'package:cora/features/discovery/domain/discovery_card.dart';
import 'package:cora/features/discovery/domain/discovery_repository.dart';
import 'package:cora/features/discovery/domain/discovery_target.dart';
import 'package:cora/features/discovery/domain/pass_reason.dart';
import 'package:cora/features/discovery/domain/reward_proposal.dart';
import 'package:cora/features/principles/domain/principles.dart' show FeeBand;

/// 손으로 쓴 가짜 발견 저장소. 오늘 목록과 결정, 되돌리기를 흉내 낸다.
class FakeDiscoveryRepository implements DiscoveryRepository {
  FakeDiscoveryRepository({List<CreatorCard>? cards, int? total})
    : cards = cards ?? [],
      total = total ?? (cards?.length ?? 0);

  /// 서버가 주는 아직 결정하지 않은 카드와 오늘 전체 수.
  List<CreatorCard> cards;
  int total;

  /// 둘러보기(9A)의 카드와 실패, 읽은 횟수.
  List<PreviewCard> previewCards = [];
  bool failPreview = false;
  int previewFetchCalls = 0;

  bool failFetch = false;
  bool failDecide = false;
  bool failSetReason = false;
  bool failUndo = false;

  /// 이 대상에 관심을 보내면 서로 관심이 된다(협업 id는 `collab-<대상>`).
  final matchOn = <String>{};

  /// true이면 [undoLast]가 되돌릴 것이 없다고 답한다(null).
  bool nothingToUndo = false;

  final decisions =
      <
        ({
          DiscoveryTarget target,
          SwipeOutcome outcome,
          String? note,
          RewardProposal? proposal,
        })
      >[];
  final reasons = <({DiscoveryTarget target, PassReason reason})>[];
  int undoCalls = 0;
  int fetchCalls = 0;

  @override
  Future<({int total, List<CreatorCard> cards})> fetchCreatorCards() async {
    fetchCalls++;
    if (failFetch) throw const DiscoveryFailure();
    // 결정한 카드는 서버 목록에서 빠진다.
    final decided = {for (final d in decisions) d.target.id};
    return (
      total: total,
      cards: [
        for (final c in cards)
          if (!decided.contains(c.creatorId)) c,
      ],
    );
  }

  @override
  Future<({int total, List<DiscoveryCard> cards})> fetchCampaignCards() async =>
      (total: 0, cards: <DiscoveryCard>[]);

  @override
  Future<DecisionResult> decide(
    DiscoveryTarget target,
    SwipeOutcome outcome, {
    String? note,
    RewardProposal? proposal,
  }) async {
    if (failDecide) throw const DiscoveryFailure();
    decisions.add((
      target: target,
      outcome: outcome,
      note: note,
      proposal: proposal,
    ));
    final matched = outcome == SwipeOutcome.like && matchOn.contains(target.id);
    return DecisionResult(
      matched: matched,
      collaborationId: matched ? 'collab-${target.id}' : null,
    );
  }

  @override
  Future<List<PreviewCard>> fetchPreviewCards() async {
    previewFetchCalls++;
    if (failPreview) throw const DiscoveryFailure();
    return previewCards;
  }

  @override
  Future<void> setPassReason(DiscoveryTarget target, PassReason reason) async {
    if (failSetReason) throw const DiscoveryFailure();
    reasons.add((target: target, reason: reason));
  }

  @override
  Future<DiscoveryTarget?> undoLast() async {
    undoCalls++;
    if (failUndo) throw const DiscoveryFailure();
    if (nothingToUndo || decisions.isEmpty) return null;
    return decisions.removeLast().target;
  }
}

CreatorCard creatorCard(
  String id, {
  String name = '서윤의 작은 취향',
  String? headline = '출근 전 30초, 오늘의 손목 루틴',
  FeeBand feeBand = FeeBand.w300k,
  List<String> tags = const ['얼굴출연없음', '소품'],
  List<MatchReason> reasons = const [MatchReason.field, MatchReason.fee],
}) => CreatorCard(
  creatorId: id,
  displayName: name,
  headline: headline,
  feeBand: feeBand,
  tags: tags,
  reasons: reasons,
);

PreviewCard previewCard(
  String id, {
  String name = '서윤의 작은 취향',
  String? headline = '출근 전 30초, 오늘의 손목 루틴',
  FeeBand feeBand = FeeBand.w300k,
  List<String> tags = const ['얼굴출연없음', '소품'],
}) => PreviewCard(
  creatorId: id,
  displayName: name,
  headline: headline,
  feeBand: feeBand,
  tags: tags,
);

/// 테스트용 대상 모양을 짧게 만든다.
class DiscoveryTargetStub {
  const DiscoveryTargetStub(this.id);

  final String id;

  DiscoveryTarget get target => DiscoveryTarget.creator(id);
}
