import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/swipe_deck/swipe_physics.dart' show SwipeOutcome;
import '../../../discovery/domain/discovery_repository.dart';
import '../../../discovery/domain/discovery_target.dart';
import '../../domain/received_proposal.dart';
import '../../domain/received_proposals_repository.dart';
import 'received_proposals_view_model.dart';

/// 받은 제안 목록에 이 캠페인의 제안이 없다(이미 답했거나 브랜드가 거두었다).
class ReceivedProposalGone implements Exception {
  const ReceivedProposalGone();

  @override
  String toString() => 'ReceivedProposalGone';
}

class ReceivedProposalState {
  const ReceivedProposalState({required this.proposal, this.busy = false});

  final ReceivedProposal proposal;

  /// 관심이나 질문을 보내는 중. 그동안은 다시 누르지 못한다.
  final bool busy;

  ReceivedProposalState copyWith({bool? busy}) =>
      ReceivedProposalState(proposal: proposal, busy: busy ?? this.busy);
}

/// `관심 보내기`의 결과. 서로 관심이 닿으면 [matched]에 협업 id가 있다.
sealed class InterestOutcome {
  const InterestOutcome();
}

class InterestMatched extends InterestOutcome {
  const InterestMatched(this.collaborationId);

  final String collaborationId;
}

class InterestSent extends InterestOutcome {
  const InterestSent();
}

class InterestFailed extends InterestOutcome {
  const InterestFailed();
}

/// `조건부터 질문하기`의 결과.
enum InquiryOutcome { sent, conflict, failed }

/// 받은 제안 하나(10). 목록에서 이 캠페인의 제안을 찾아 보이고, 관심 보내기와 조건부터 질문하기를 보낸다.
final receivedProposalViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<ReceivedProposalViewModel, ReceivedProposalState, String>(
      ReceivedProposalViewModel.new,
      retry: (_, _) => null,
    );

class ReceivedProposalViewModel extends AsyncNotifier<ReceivedProposalState> {
  ReceivedProposalViewModel(this._campaignId);

  final String _campaignId;

  @override
  Future<ReceivedProposalState> build() async {
    // 한 번 읽은 목록에서 찾는다. 관심을 보낸 뒤 03이 목록을 새로 읽어도 이 화면이 갑자기 바뀌지 않게
    // watch가 아니라 read다.
    final list = await ref.read(receivedProposalsViewModelProvider.future);
    for (final p in list) {
      if (p.campaignId == _campaignId) {
        return ReceivedProposalState(proposal: p);
      }
    }
    throw const ReceivedProposalGone();
  }

  /// 입력한 한 줄([note], 비었으면 보내지 않는다)을 붙여 관심을 보낸다. 이미 보내는 중이면 null.
  Future<InterestOutcome?> sendInterest(String note) async {
    final current = state.value;
    if (current == null || current.busy) return null;
    state = AsyncData(current.copyWith(busy: true));
    try {
      final trimmed = note.trim();
      final result = await ref
          .read(discoveryRepositoryProvider)
          .decide(
            DiscoveryTarget.campaign(_campaignId),
            SwipeOutcome.like,
            note: trimmed.isEmpty ? null : trimmed,
          );
      final id = result.collaborationId;
      return result.matched && id != null
          ? InterestMatched(id)
          : const InterestSent();
    } catch (_) {
      return const InterestFailed();
    } finally {
      if (ref.mounted) {
        final latest = state.value;
        if (latest != null) state = AsyncData(latest.copyWith(busy: false));
      }
    }
  }

  /// 브랜드에게 조건부터 질문한다. [contentLine]은 10의 한 줄 입력(비었으면 보내지 않는다).
  Future<InquiryOutcome> inquire(String message, String contentLine) async {
    final line = contentLine.trim();
    try {
      await ref
          .read(receivedProposalsRepositoryProvider)
          .inquire(
            _campaignId,
            message: message.trim(),
            contentLine: line.isEmpty ? null : line,
          );
      return InquiryOutcome.sent;
    } on ReceivedProposalsFailure catch (e) {
      return e.isConflict ? InquiryOutcome.conflict : InquiryOutcome.failed;
    } catch (_) {
      return InquiryOutcome.failed;
    }
  }
}
