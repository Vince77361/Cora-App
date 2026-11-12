import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/current_user_provider.dart';
import '../../domain/collaboration.dart';
import '../../domain/collaboration_repository.dart';

/// 받은 오퍼 화면 `진행 중` 탭의 협업 목록. 탭이 열려 있는 동안만 살아 있고, 다시 열면 서버에서 새로
/// 읽는다. 제출·취소로 협업이 바뀌면 다른 화면이 이것을 무효화한다. Riverpod의 자동 재시도는 끈다.
final collaborationListViewModelProvider =
    AsyncNotifierProvider.autoDispose<
      CollaborationListViewModel,
      List<Collaboration>
    >(CollaborationListViewModel.new, retry: (_, _) => null);

class CollaborationListViewModel extends AsyncNotifier<List<Collaboration>> {
  @override
  Future<List<Collaboration>> build() {
    ref.watch(currentUserIdProvider);
    return ref.read(collaborationRepositoryProvider).fetchActive();
  }
}
