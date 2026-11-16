import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/compare_result.dart';
import '../../domain/interests_repository.dart';

/// 04 후보 비교. 비교할 두 크리에이터 id(왼쪽 a, 오른쪽 b)마다 하나 만들고 화면을 떠나면 버린다.
/// 읽기 실패는 자동으로 다시 읽지 않고 화면의 `다시 시도`가 다시 읽는다.
final compareViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<CompareViewModel, CompareResult, ({String a, String b})>(
      CompareViewModel.new,
      retry: (_, _) => null,
    );

class CompareViewModel extends AsyncNotifier<CompareResult> {
  CompareViewModel(this.pair);

  final ({String a, String b}) pair;

  @override
  Future<CompareResult> build() =>
      ref.read(interestsRepositoryProvider).compare(pair.a, pair.b);

  /// 표를 다시 읽는다(제안을 보내고 돌아온 뒤). 읽지 못하면 지금 표를 그대로 둔다.
  Future<void> refresh() async {
    try {
      final fresh = await ref
          .read(interestsRepositoryProvider)
          .compare(pair.a, pair.b);
      if (ref.mounted) state = AsyncData(fresh);
    } catch (_) {
      // 지금 보이는 표가 틀리지는 않았다. 조용히 남긴다.
    }
  }

  void reload() => ref.invalidateSelf();
}
