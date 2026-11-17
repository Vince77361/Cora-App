import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/current_user_provider.dart';
import '../../domain/received_proposal.dart';
import '../../domain/received_proposals_repository.dart';

/// 내가 받은 제안 목록. 03 맨 위 묶음과 10이 같이 읽는다(03이 열려 있는 동안 살아 있어, 10은 같은 목록에서
/// 제안을 찾는다). 실패는 자동으로 다시 읽지 않고 [reload]나 [refresh]로만 읽는다.
final receivedProposalsViewModelProvider =
    AsyncNotifierProvider.autoDispose<
      ReceivedProposalsViewModel,
      List<ReceivedProposal>
    >(ReceivedProposalsViewModel.new, retry: (_, _) => null);

class ReceivedProposalsViewModel extends AsyncNotifier<List<ReceivedProposal>> {
  @override
  Future<List<ReceivedProposal>> build() {
    // 다른 계정으로 바뀌면 이전 계정의 목록을 버린다.
    ref.watch(currentUserIdProvider);
    return ref.read(receivedProposalsRepositoryProvider).fetchAll();
  }

  /// 처음부터 다시 읽는다(불러오기 실패의 `다시 시도`).
  void reload() => ref.invalidateSelf();

  /// 보이던 목록을 두고 조용히 다시 읽는다(10에서 돌아왔을 때). 실패하면 보이던 목록을 그대로 둔다.
  Future<void> refresh() async {
    try {
      final fresh = await ref
          .read(receivedProposalsRepositoryProvider)
          .fetchAll();
      if (ref.mounted) state = AsyncData(fresh);
    } catch (_) {
      // 보이던 목록을 그대로 둔다.
    }
  }
}
