import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/current_user_provider.dart';
import '../../domain/collaboration.dart';
import '../../domain/collaboration_repository.dart';

/// 받은 오퍼 화면 `진행 중` 탭의 협업 목록. 탭이 열려 있는 동안만 살아 있고, 다시 열면 서버에서 새로
/// 읽는다. 제출·취소로 협업이 바뀌면 다른 화면이 이것을 무효화한다. Riverpod의 자동 재시도는 끈다.
///
/// 진행 중인 협업 뒤에, 정산은 끝났지만 지급이 아직 안 끝난 협업(계좌 등록 전, 지급 대기, 지급 실패)을
/// 이어 붙인다. 서버의 진행 중 목록은 정산 완료를 빼므로 이 줄들이 없으면 크리에이터가 계좌를 등록하러
/// 갈 입구가 앱 안에 없다.
final collaborationListViewModelProvider =
    AsyncNotifierProvider.autoDispose<
      CollaborationListViewModel,
      List<Collaboration>
    >(CollaborationListViewModel.new, retry: (_, _) => null);

class CollaborationListViewModel extends AsyncNotifier<List<Collaboration>> {
  @override
  Future<List<Collaboration>> build() async {
    ref.watch(currentUserIdProvider);
    final repo = ref.read(collaborationRepositoryProvider);
    final active = repo.fetchActive();
    // 끝난 목록을 못 읽어도 진행 중 목록은 보이게 한다(홈의 협업 읽기와 같은 방식).
    final done = repo.fetchDone().catchError((Object _) => <Collaboration>[]);
    return [
      ...await active,
      // 지급이 끝나면(done) 목록에서 빠진다.
      for (final c in await done)
        if (_awaitsPayout(c)) c,
    ];
  }

  static bool _awaitsPayout(Collaboration c) =>
      c.stage == CollaborationStage.settled &&
      switch (c.payoutStatus) {
        PayoutStatus.needsAccount ||
        PayoutStatus.pending ||
        PayoutStatus.failed => true,
        PayoutStatus.none || PayoutStatus.done => false,
      };
}
