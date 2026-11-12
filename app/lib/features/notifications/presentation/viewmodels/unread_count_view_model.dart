import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/current_user_provider.dart';
import '../../../onboarding/presentation/viewmodels/me_view_model.dart';
import '../../domain/notification_repository.dart';

/// 읽지 않은 알림 수. 종 아이콘의 점과 읽을 이름이 쓴다.
///
/// 종은 홈 머리에 늘 떠 있는 작은 표시라서 못 읽으면 오류를 보이지 않고 0(점 없음)으로 둔다. 사용자나
/// 역할이 바뀌면 다시 읽는다. 알림함에서 읽음으로 바꾸거나 홈을 당겨 새로 읽을 때 `invalidate`한다.
final unreadCountViewModelProvider =
    AsyncNotifierProvider<UnreadCountViewModel, int>(
      UnreadCountViewModel.new,
      retry: (_, _) => null,
    );

class UnreadCountViewModel extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    final userId = ref.watch(currentUserIdProvider);
    ref.watch(meViewModelProvider.select((me) => me.value?.role));
    if (userId == null) return 0;
    try {
      return await ref.read(notificationRepositoryProvider).unreadCount();
    } on NotificationFailure {
      return 0;
    }
  }
}
