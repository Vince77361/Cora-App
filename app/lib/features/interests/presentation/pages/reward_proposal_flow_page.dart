import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/cora_state_view.dart';
import '../../../../core/ui/cora_step_header.dart';
import '../../../../core/ui/swipe_deck/swipe_physics.dart' show SwipeOutcome;
import '../../../discovery/domain/discovery_repository.dart';
import '../../../discovery/domain/discovery_target.dart';
import '../../../discovery/domain/reward_proposal.dart';
import '../../../offer_terms/domain/offer_terms.dart';
import '../../../offer_terms/domain/proposal_draft.dart';
import '../../../offer_terms/presentation/brand_proposal_copy.dart';
import '../../../offer_terms/presentation/pages/reward_budget_page.dart';
import '../../domain/interests_repository.dart';
import '../reward_proposal_entry.dart';
import '../viewmodels/reward_proposal_setup.dart';

/// 흐름이 어떻게 끝났는가. 보냈거나([sent]), 보내다가 서로 관심이 닿았거나([matchedCollaborationId]가 있음),
/// 옛 판본이라 보내지 못했다([stale], [latestVersion]은 서버가 알려 준 최신 판본 번호).
class RewardProposalFlowResult {
  const RewardProposalFlowResult.sent()
    : stale = false,
      latestVersion = null,
      matchedCollaborationId = null;
  const RewardProposalFlowResult.matched(String this.matchedCollaborationId)
    : stale = false,
      latestVersion = null;
  const RewardProposalFlowResult.stale(this.latestVersion)
    : stale = true,
      matchedCollaborationId = null;

  final bool stale;
  final int? latestVersion;

  /// 서로 관심 전에 보낸 제안이 곧바로 서로 관심이 됐을 때 그 협업의 id.
  final String? matchedCollaborationId;
}

/// F1(보상·예산 설정)을 여는 경로. 시작값을 읽는 동안은 불러오는 중, 읽지 못하면 다시 시도를 보이고, 읽으면 F1이
/// 된다. F2의 `이 조건으로 보내기`가 [_send]를 부르고, 보내면 F1과 그 위의 F2를 함께 닫는다.
class RewardProposalFlowPage extends ConsumerStatefulWidget {
  const RewardProposalFlowPage({super.key, required this.target});

  final RewardProposalTarget target;

  static const loadFailedTitle = '제안 화면을 불러오지 못했어요';

  @override
  ConsumerState<RewardProposalFlowPage> createState() =>
      _RewardProposalFlowPageState();
}

class _RewardProposalFlowPageState
    extends ConsumerState<RewardProposalFlowPage> {
  /// F1·F2가 `고치기`로 오가는 동안에도 같은 경로 하나다. 흐름을 닫을 때 이 경로 위의 것을 모두 닫는다.
  void _finish(RewardProposalFlowResult result) {
    final route = ModalRoute.of(context);
    if (route == null || !route.isActive) return;
    final navigator = Navigator.of(context, rootNavigator: true);
    navigator.popUntil((r) => r == route);
    navigator.pop(result);
  }

  /// 고른 조건을 보낸다. 서로 관심 전이면 관심과 함께, 뒤면 새 판본으로(`RewardProposal.fromTerms`가 두 길의 값을
  /// 한 곳에서 만든다). 실패는 F2가 문구를 보이도록 [ProposalSendFailure]로 바꿔 던진다.
  Future<void> _send(OfferTerms terms) async {
    final proposal = RewardProposal.fromTerms(terms);
    final target = widget.target;
    try {
      switch (target) {
        case BeforeMatch(:final creatorId):
          final decision = await ref
              .read(discoveryRepositoryProvider)
              .decide(
                DiscoveryTarget.creator(creatorId),
                SwipeOutcome.like,
                proposal: proposal,
              );
          // 상대가 이미 관심을 보낸 후보면 이 제안으로 곧바로 서로 관심이 닿는다.
          final collaborationId = decision.collaborationId;
          if (decision.matched && collaborationId != null) {
            _finish(RewardProposalFlowResult.matched(collaborationId));
            return;
          }
        case AfterMatch(:final collaborationId, :final baseVersion):
          await ref
              .read(interestsRepositoryProvider)
              .proposeReward(
                collaborationId,
                baseVersion: baseVersion,
                proposal: proposal,
              );
      }
    } on RewardProposalStale catch (stale) {
      _finish(RewardProposalFlowResult.stale(stale.latestVersion));
      return;
    } on RewardProposalRejected catch (rejected) {
      throw ProposalSendFailure(rejected.message);
    } on Exception {
      throw const ProposalSendFailure();
    }
    _finish(const RewardProposalFlowResult.sent());
  }

  @override
  Widget build(BuildContext context) {
    final setup = ref.watch(rewardProposalSetupProvider(widget.target));
    final value = setup.value;
    if (value != null) {
      return RewardBudgetPage(
        target: value.target,
        onSend: _send,
        recipientPhotoUrl: value.recipientPhotoUrl,
      );
    }
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CoraStepHeader(
              pageLabel: RewardBudgetPage.pageLabel,
              step: BrandProposalCopy.budgetStep,
              total: BrandProposalCopy.totalSteps,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: setup.hasError
                  ? CoraStateView.loadFailed(
                      title: RewardProposalFlowPage.loadFailedTitle,
                      onRetry: () => ref.invalidate(
                        rewardProposalSetupProvider(widget.target),
                      ),
                    )
                  : const CoraStateView.loading(),
            ),
          ],
        ),
      ),
    );
  }
}

/// 서로 관심 뒤의 새 판본을 내려는 사이 상대가 더 새 판본을 냈을 때(F8 `이전 판본이라 수락할 수 없어요`).
/// `판본 N 보기`가 그 판본을 연다.
class StaleProposalPage extends StatelessWidget {
  const StaleProposalPage({
    super.key,
    required this.latestVersion,
    required this.onOpen,
  });

  final int latestVersion;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CoraStepHeader(
              pageLabel: RewardBudgetPage.pageLabel,
              step: BrandProposalCopy.budgetStep,
              total: BrandProposalCopy.totalSteps,
              showProgress: false,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: CoraStateView.staleVersion(
                version: latestVersion,
                onOpen: () {
                  Navigator.of(context).pop();
                  onOpen();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
