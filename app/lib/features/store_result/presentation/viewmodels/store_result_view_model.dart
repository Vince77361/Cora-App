import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../collaboration/domain/collaboration_repository.dart';
import '../../../offer_terms/domain/offer_terms.dart';
import '../../domain/store_result.dart';
import '../../domain/store_result_repository.dart';

/// G1 7일 결과의 상태. 협업마다 하나이고 화면을 떠나면 버린다.
final storeResultViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<StoreResultViewModel, StoreResultState, String>(
      StoreResultViewModel.new,
      retry: (_, _) => null,
    );

class StoreResultState {
  const StoreResultState({required this.result, this.pastTerms});

  final StoreResult result;

  /// 그 협업의 조건. `다시 만나기`가 지난 조건을 채워 연다. 협업을 읽지 못했으면 null이고
  /// 그때는 가게의 모집 조건에서 시작한다.
  final OfferTerms? pastTerms;
}

class StoreResultViewModel extends AsyncNotifier<StoreResultState> {
  StoreResultViewModel(this._collaborationId);

  final String _collaborationId;

  @override
  Future<StoreResultState> build() async {
    final result = await ref
        .read(storeResultRepositoryProvider)
        .fetch(_collaborationId);
    return StoreResultState(result: result, pastTerms: await _pastTerms());
  }

  /// 지난 조건은 있으면 좋은 값이라, 못 읽어도 결과는 그대로 보인다.
  Future<OfferTerms?> _pastTerms() async {
    try {
      return (await ref
              .read(collaborationRepositoryProvider)
              .fetch(_collaborationId))
          .terms;
    } on Object {
      return null;
    }
  }
}
