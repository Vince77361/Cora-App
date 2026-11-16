import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/swipe_deck/swipe_physics.dart' show SwipeOutcome;
import 'discovery_card.dart';
import 'discovery_target.dart';
import 'pass_reason.dart';
import 'reward_proposal.dart';

/// 결정을 보낸 결과. [matched]이면 서로 관심이 닿아 협업 [collaborationId]가 생겼다.
class DecisionResult {
  const DecisionResult({this.matched = false, this.collaborationId});

  final bool matched;
  final String? collaborationId;
}

/// 발견(01·08·9A)이 서버와 주고받는 포트.
abstract class DiscoveryRepository {
  /// 오늘 브랜드에게 보일 크리에이터 카드. [total]은 오늘 목록 전체(이미 결정한 카드 포함)이고
  /// [cards]는 아직 결정하지 않은 것이다.
  Future<({int total, List<CreatorCard> cards})> fetchCreatorCards();

  /// 오늘 크리에이터에게 보일 캠페인·가게 카드(08).
  Future<({int total, List<DiscoveryCard> cards})> fetchCampaignCards();

  /// 관심·넘김·보류를 보낸다. [note]는 관심에 붙이는 글, [proposal]은 브랜드의 보상 제안이다.
  /// 실패하면 [DiscoveryFailure].
  Future<DecisionResult> decide(
    DiscoveryTarget target,
    SwipeOutcome outcome, {
    String? note,
    RewardProposal? proposal,
  });

  /// 역할 없는 사용자의 둘러보기 카드(9A).
  Future<List<PreviewCard>> fetchPreviewCards();

  /// 방금 넘긴 [target]에 이유를 남긴다. 실패하면 [DiscoveryFailure].
  Future<void> setPassReason(DiscoveryTarget target, PassReason reason);

  /// 내가 오늘 한 마지막 결정을 되돌리고 그 대상을 돌려준다. 되돌릴 것이 없으면(다른 결정을 했거나
  /// 자정이 지났거나 서로 관심이 된 카드) null이다. 실패하면 [DiscoveryFailure].
  Future<DiscoveryTarget?> undoLast();
}

/// 서버와 주고받지 못했다. 서버 응답의 문구는 담지 않는다.
class DiscoveryFailure implements Exception {
  const DiscoveryFailure();

  @override
  String toString() => 'DiscoveryFailure';
}

/// 기본값은 일부러 던진다. main.dart가 API 구현으로, 테스트가 가짜로 바꿔 끼운다.
final discoveryRepositoryProvider = Provider<DiscoveryRepository>(
  (ref) => throw UnimplementedError(
    'discoveryRepositoryProvider must be overridden',
  ),
);
