import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../discovery/domain/reward_proposal.dart';
import 'compare_result.dart';
import 'interest_card.dart';
import 'match_info.dart';
import 'proposal_base.dart';

/// 관심·보류(03), 후보 비교(04), 서로 관심(05)이 서버와 주고받는 포트. 결정(관심·넘김)은
/// 발견의 `DiscoveryRepository.decide`가 맡는다.
abstract class InterestsRepository {
  /// 내가 저장한(관심 + 보류) 카드 전부. 탭은 앱이 상태로 가른다. 실패하면 [InterestsFailure].
  Future<List<InterestCard>> fetchSaved();

  /// 이 캠페인에서 내가 저장한 두 크리에이터를 견준다. 실패하면 [InterestsFailure].
  Future<CompareResult> compare(String a, String b);

  /// 협업 [collaborationId]의 05 정보. 실패하면 [InterestsFailure].
  Future<MatchInfo> fetchMatch(String collaborationId);

  /// 05의 `내가 먼저 제안하기`가 F1을 여는 데 필요한 것(받는 사람, 모집 줄, 최신 판본의 조건).
  /// 실패하면 [InterestsFailure].
  Future<ProposalBase> fetchProposalBase(String collaborationId);

  /// 협업 [collaborationId]에 돈과 혜택만 바꾼 새 판본을 낸다. [baseVersion]은 내가 보고 있던 판본이다.
  /// 최신이 아니면 [RewardProposalStale], 서버가 사용자 문구와 함께 거절하면 [RewardProposalRejected],
  /// 그 밖의 실패는 [InterestsFailure].
  Future<void> proposeReward(
    String collaborationId, {
    required int baseVersion,
    required RewardProposal proposal,
  });
}

/// 새 판본을 내려는 사이 상대가 더 새 판본을 냈다(409 `STALE_VERSION`). [latestVersion]은 서버가 알려 준
/// 최신 판본 번호이고 알 수 없으면 null이다.
class RewardProposalStale implements Exception {
  const RewardProposalStale(this.latestVersion);

  final int? latestVersion;

  @override
  String toString() => 'RewardProposalStale';
}

/// 서버가 사용자에게 보일 문구(인스타그램 연동 필요, 바꾼 조건 없음 등)와 함께 거절했다.
class RewardProposalRejected implements Exception {
  const RewardProposalRejected(this.message);

  final String? message;

  @override
  String toString() => 'RewardProposalRejected';
}

/// 서버와 주고받지 못했다. 서버 응답의 문구는 담지 않는다.
class InterestsFailure implements Exception {
  const InterestsFailure();

  @override
  String toString() => 'InterestsFailure';
}

/// 기본값은 일부러 던진다. main.dart가 API 구현으로, 테스트가 가짜로 바꿔 끼운다.
final interestsRepositoryProvider = Provider<InterestsRepository>(
  (ref) => throw UnimplementedError(
    'interestsRepositoryProvider must be overridden',
  ),
);
