import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/store_browse_repository.dart';
import '../../domain/store_summary.dart';
import 'my_region.dart';

/// 크리에이터 홈의 공개된 가게 목록. Riverpod의 자동 재시도는 끈다(실패하면 오류 화면의
/// `다시 시도`로 다시 받는다. 재시도가 끝날 때까지 로딩으로 남지 않게).
final storeListViewModelProvider =
    AsyncNotifierProvider.autoDispose<StoreListViewModel, StoreListState>(
      StoreListViewModel.new,
      retry: (_, _) => null,
    );

class StoreListState {
  const StoreListState({required this.stores, this.mySido});

  final List<StoreSummary> stores;

  /// 내 활동 지역의 시·도. 모르면 null.
  final String? mySido;

  /// 이 가게가 내 지역과 다른 시·도에 있는지.
  bool inOtherProvince(StoreSummary store) =>
      mySido != null && store.regionSido != null && store.regionSido != mySido;
}

class StoreListViewModel extends AsyncNotifier<StoreListState> {
  @override
  Future<StoreListState> build() => _load();

  Future<StoreListState> _load() async {
    final results = await Future.wait([
      ref.read(storeBrowseRepositoryProvider).fetchPublished(),
      fetchMySido(ref),
    ]);
    return StoreListState(
      stores: results[0]! as List<StoreSummary>,
      mySido: results[1] as String?,
    );
  }

  /// 아래로 당기거나 "다시 시도"를 눌렀을 때. 이미 보이는 목록은 새로 받는 동안 그대로 둔다.
  Future<void> refresh() async {
    final next = await AsyncValue.guard(_load);
    if (!ref.mounted) return;
    // 새로 받기에 실패해도 이미 보이는 목록은 지우지 않는다.
    if (next.hasError && state.hasValue) return;
    state = next;
  }
}
