import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/current_user_provider.dart';
import '../../../offer_terms/domain/offer_terms.dart';
import '../../domain/my_store.dart';
import '../../domain/source_link.dart';
import '../../domain/store_repository.dart';
import '../../domain/store_repository_provider.dart';

/// 내 가게. 등록 화면들, 사장님 홈, 오퍼 화면이 함께 읽는다(다른 기능도 이것으로 내 가게를 읽는다).
///
/// 로그인한 사용자가 바뀌면 다시 불러온다. 가게를 아직 만들지 않았으면 값이 null이다. 바꾸는
/// 동작은 성공하면 서버가 돌려준 가게로 상태를 바꾸고, 실패하면 [StoreFailure]를 던진다(상태는
/// 그대로 둔다. 화면이 입력을 지우지 않고 오류를 보여 줄 수 있게).
///
/// Riverpod의 자동 재시도는 끈다. 실패하면 재시도가 끝날 때까지 로딩으로 남아 진입 화면이
/// 오래 비어 있다.
final myStoreViewModelProvider =
    AsyncNotifierProvider<MyStoreViewModel, MyStore?>(
      MyStoreViewModel.new,
      retry: (_, _) => null,
    );

class MyStoreViewModel extends AsyncNotifier<MyStore?> {
  @override
  Future<MyStore?> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return null;
    return ref.watch(storeRepositoryProvider).fetchMine();
  }

  StoreRepository get _repo => ref.read(storeRepositoryProvider);

  /// 링크를 분석해 가게를 만든다. 읽지 못했으면 true를 돌려준다(빈 가게로 이어 간다).
  Future<bool> analyze(List<SourceLink> links) async {
    final result = await _repo.analyze(links);
    if (ref.mounted) state = AsyncData(result.store);
    return result.analysisFailed;
  }

  Future<void> saveEdit(StoreEdit edit) => _apply(_repo.update(edit));

  Future<void> advance(StoreOnboardingStep step) => _apply(_repo.advance(step));

  Future<void> setDefaultTerms(OfferTermsInput input) =>
      _apply(_repo.setDefaultTerms(input));

  Future<void> publish() => _apply(_repo.publish());

  Future<void> _apply(Future<MyStore> call) async {
    final store = await call;
    if (ref.mounted) state = AsyncData(store);
  }
}
