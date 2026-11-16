import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/navigation/cora_transitions.dart';
import 'pages/reward_proposal_flow_page.dart';

/// 보상 제안을 어디에 보내는가. 04의 `…에게 제안`은 서로 관심 전이라 크리에이터에게 관심과 함께 보내고,
/// 05의 `내가 먼저 제안하기`는 이미 있는 협업의 새 판본으로 보낸다.
sealed class RewardProposalTarget {
  const RewardProposalTarget();
}

/// 내가 이미 크리에이터에게 만들어 둔 제안의 값(04의 표가 아는 값). 성과 추가는 단가와 상한이 함께 있을 때만 켜져 있다.
class CurrentProposal {
  const CurrentProposal({
    required this.fee,
    required this.productProvided,
    this.perfRate,
    this.perfCap,
  });

  final int fee;
  final bool productProvided;
  final int? perfRate;
  final int? perfCap;

  @override
  bool operator ==(Object other) =>
      other is CurrentProposal &&
      other.fee == fee &&
      other.productProvided == productProvided &&
      other.perfRate == perfRate &&
      other.perfCap == perfCap;

  @override
  int get hashCode => Object.hash(fee, productProvided, perfRate, perfCap);
}

/// 서로 관심 전: [creatorId]에게 보내는 관심에 제안을 붙인다. [recipientName]과 [recipientPhotoUrl]은 F2의
/// 받는 사람이고, [current]가 있으면 F1이 그 값에서 시작한다(없으면 캠페인의 값에서).
class BeforeMatch extends RewardProposalTarget {
  const BeforeMatch(
    this.creatorId, {
    this.recipientName,
    this.recipientPhotoUrl,
    this.current,
  });

  final String creatorId;
  final String? recipientName;
  final String? recipientPhotoUrl;
  final CurrentProposal? current;

  @override
  bool operator ==(Object other) =>
      other is BeforeMatch &&
      other.creatorId == creatorId &&
      other.recipientName == recipientName &&
      other.recipientPhotoUrl == recipientPhotoUrl &&
      other.current == current;

  @override
  int get hashCode =>
      Object.hash(creatorId, recipientName, recipientPhotoUrl, current);
}

/// 서로 관심 뒤: 협업 [collaborationId]의 최신 판본 [baseVersion] 위에 새 판본을 낸다.
class AfterMatch extends RewardProposalTarget {
  const AfterMatch(this.collaborationId, this.baseVersion);

  final String collaborationId;
  final int baseVersion;

  @override
  bool operator ==(Object other) =>
      other is AfterMatch &&
      other.collaborationId == collaborationId &&
      other.baseVersion == baseVersion;

  @override
  int get hashCode => Object.hash(collaborationId, baseVersion);
}

/// [openRewardProposal]이 어떻게 끝났는가.
sealed class ProposalOutcome {
  const ProposalOutcome();
}

/// 제안을 보냈다.
class ProposalSent extends ProposalOutcome {
  const ProposalSent();
}

/// 서로 관심 전에 보낸 제안이 곧바로 서로 관심이 됐다(상대가 이미 관심을 보낸 후보).
class ProposalMatched extends ProposalOutcome {
  const ProposalMatched(this.collaborationId);

  final String collaborationId;
}

/// 그사이 더 새 판본이 나와 보내지 못했고, F8의 옛 판본 화면을 보였다.
class ProposalStale extends ProposalOutcome {
  const ProposalStale();
}

/// 보내지 않고 닫았다.
class ProposalDismissed extends ProposalOutcome {
  const ProposalDismissed();
}

/// 보상·예산 설정(F1)에서 보내기 전 검토(F2)로 이어지는 흐름을 여는 한 곳.
///
/// 흐름은 하나의 경로(F1) 위에 F2가 쌓이는 모양이고, 보내면 둘을 함께 닫는다. 서로 관심 뒤에 내는 판본이 그사이
/// 옛 판본이 됐으면(409 `STALE_VERSION`) 흐름을 닫고 F8의 `이전 판본이라 수락할 수 없어요` 화면을 연다
/// ([ProposalStale]). 부르는 쪽(04·05)은 결과로 `보냈어요` 문구와 이동을 정한다.
Future<ProposalOutcome> openRewardProposal(
  BuildContext context,
  RewardProposalTarget target,
) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final router = GoRouter.of(context);
  final result = await navigator.push<RewardProposalFlowResult>(
    CoraTransitions.push<RewardProposalFlowResult>(
      RewardProposalFlowPage(target: target),
    ).createRoute(context),
  );
  if (result == null) return const ProposalDismissed();
  if (result.stale) {
    if (context.mounted && target is AfterMatch) {
      await navigator.push<void>(
        CoraTransitions.push<void>(
          StaleProposalPage(
            latestVersion: result.latestVersion ?? target.baseVersion + 1,
            onOpen: () => router.push(
              AppRoutes.collaborationTerms(target.collaborationId),
            ),
          ),
        ).createRoute(context),
      );
    }
    return const ProposalStale();
  }
  final matched = result.matchedCollaborationId;
  return matched == null ? const ProposalSent() : ProposalMatched(matched);
}
