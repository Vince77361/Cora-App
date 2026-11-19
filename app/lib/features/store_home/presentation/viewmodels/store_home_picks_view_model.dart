import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../applicant_picks/domain/applicant_pick.dart';
import '../../../applicant_picks/domain/applicant_picks_repository.dart';
import '../../../auth/domain/current_user_provider.dart';

/// 홈의 `추천 3명`. 지원자가 있으면 그 가게의 지원자 중에서, 없으면 Cora 크리에이터 전체에서 서버가 뽑는다.
/// 칸 하나 때문에 홈이 오류나 로딩에 묶이지 않게 홈 본문과 따로 읽는다. 읽지 못하면 오류 상태이고 홈은 이
/// 칸만 그리지 않는다. 아래로 당겨 새로 읽는 것은 홈이 [refresh]로 한다.
final storeHomePicksViewModelProvider =
    AsyncNotifierProvider.autoDispose<StoreHomePicksViewModel, ApplicantPicks>(
      StoreHomePicksViewModel.new,
      retry: (_, _) => null,
    );

class StoreHomePicksViewModel extends AsyncNotifier<ApplicantPicks> {
  @override
  Future<ApplicantPicks> build() {
    ref.watch(currentUserIdProvider);
    return ref.read(applicantPicksRepositoryProvider).fetchPicks();
  }

  /// 서버에서 다시 읽는다. 실패하면 보던 추천을 그대로 둔다.
  Future<void> refresh() async {
    try {
      final fresh = await ref
          .read(applicantPicksRepositoryProvider)
          .fetchPicks();
      if (ref.mounted) state = AsyncData(fresh);
    } on ApplicantPicksFailure {
      // 보던 값 유지.
    }
  }
}
