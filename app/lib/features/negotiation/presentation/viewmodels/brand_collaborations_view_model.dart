import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/current_user_provider.dart';
import '../../../collaboration/domain/collaboration.dart';
import '../../../collaboration/domain/collaboration_repository.dart';

/// 브랜드의 협업 탭: 진행 중인 브랜드 협업의 목록. 탭이 열려 있는 동안만 살아 있고, 다시 열면 서버에서 새로
/// 읽는다. 서버는 가게 오퍼도 같은 목록에 내려 주므로 브랜드 계약만 담는다. Riverpod의 자동 재시도는 끈다.
final brandCollaborationsViewModelProvider =
    AsyncNotifierProvider.autoDispose<
      BrandCollaborationsViewModel,
      List<Collaboration>
    >(BrandCollaborationsViewModel.new, retry: (_, _) => null);

class BrandCollaborationsViewModel extends AsyncNotifier<List<Collaboration>> {
  @override
  Future<List<Collaboration>> build() async {
    ref.watch(currentUserIdProvider);
    final active = await ref
        .read(collaborationRepositoryProvider)
        .fetchActive();
    return [
      for (final c in active)
        if (!c.isStoreOffer) c,
    ];
  }
}
