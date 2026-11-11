import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/store_browse_repository.dart';
import '../../domain/store_detail.dart';
import 'my_region.dart';

/// D2 가게 상세. 가게마다 하나씩 만들고, 화면을 떠나면 버린다.
final storeDetailViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<StoreDetailViewModel, StoreDetailState, String>(
      StoreDetailViewModel.new,
      retry: (_, _) => null,
    );

class StoreDetailState {
  const StoreDetailState({
    required this.detail,
    this.mySido,
    this.busy = false,
    this.failed = false,
  });

  final StoreDetail detail;
  final String? mySido;

  /// 지원이나 취소를 서버에 보내는 중. 그동안은 버튼을 다시 누르지 못한다.
  final bool busy;

  /// 방금 지원이나 취소가 실패했다(409가 아닌 실패).
  final bool failed;

  bool get inOtherProvince =>
      mySido != null &&
      detail.summary.regionSido != null &&
      detail.summary.regionSido != mySido;

  StoreDetailState copyWith({StoreDetail? detail, bool? busy, bool? failed}) =>
      StoreDetailState(
        detail: detail ?? this.detail,
        mySido: mySido,
        busy: busy ?? this.busy,
        failed: failed ?? this.failed,
      );
}

class StoreDetailViewModel extends AsyncNotifier<StoreDetailState> {
  StoreDetailViewModel(this.storeId);

  final String storeId;

  @override
  Future<StoreDetailState> build() async {
    final results = await Future.wait([
      ref.read(storeBrowseRepositoryProvider).fetchDetail(storeId),
      fetchMySido(ref),
    ]);
    return StoreDetailState(
      detail: results[0]! as StoreDetail,
      mySido: results[1] as String?,
    );
  }

  Future<void> apply() => _change(
    () => ref.read(storeBrowseRepositoryProvider).apply(storeId),
    MyApplicationStatus.applied,
  );

  Future<void> cancelApplication() => _change(
    () => ref.read(storeBrowseRepositoryProvider).cancelApplication(storeId),
    MyApplicationStatus.none,
  );

  Future<void> _change(
    Future<void> Function() call,
    MyApplicationStatus next,
  ) async {
    final current = state.value;
    if (current == null || current.busy) return;
    state = AsyncData(current.copyWith(busy: true, failed: false));
    try {
      await call();
      if (!ref.mounted) return;
      state = AsyncData(
        current.copyWith(detail: current.detail.withStatus(next), busy: false),
      );
    } on StoreBrowseFailure catch (error) {
      if (!ref.mounted) return;
      if (error.conflict) {
        // 그사이 지원 상태가 바뀌었다(예: 사장님이 오퍼를 보냈다). 서버의 지금 상태로 맞춘다.
        await _reload(current);
        return;
      }
      state = AsyncData(current.copyWith(busy: false, failed: true));
    } catch (_) {
      if (!ref.mounted) return;
      state = AsyncData(current.copyWith(busy: false, failed: true));
    }
  }

  Future<void> _reload(StoreDetailState current) async {
    try {
      final detail = await ref
          .read(storeBrowseRepositoryProvider)
          .fetchDetail(storeId);
      if (!ref.mounted) return;
      state = AsyncData(current.copyWith(detail: detail, busy: false));
    } catch (_) {
      if (!ref.mounted) return;
      state = AsyncData(current.copyWith(busy: false, failed: true));
    }
  }
}
