import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../domain/my_store.dart';
import 'my_store_view_model.dart';

/// 가게 사장님이 앱에 들어올 때 처음 보여 줄 경로. 역할별 진입(`roleEntryResolverProvider`)이 부른다.
///
/// - 가게가 없으면 링크 입력(A2).
/// - 등록 중이면 저장된 단계(`onboardingStep`)의 화면에서 이어 간다.
/// - 공개됐으면 사장님 홈.
Future<String> storeEntryPath(Ref ref) async {
  // 불러오기에 한 번 실패한 결과가 남아 있으면 다음 진입에서도 같은 오류가 나오므로 지운다.
  if (ref.read(myStoreViewModelProvider).hasError) {
    ref.invalidate(myStoreViewModelProvider);
  }
  final store = await ref.read(myStoreViewModelProvider.future);
  if (store == null) return AppRoutes.storeOnboardingLinks;
  if (store.isPublished) return AppRoutes.store;
  return switch (store.onboardingStep) {
    StoreOnboardingStep.page => AppRoutes.storeOnboardingPage,
    StoreOnboardingStep.drafts => AppRoutes.storeOnboardingDrafts,
    // 단계가 DONE이면 공개만 남은 것이다. 기본 조건 화면이 공개까지 이어 준다.
    StoreOnboardingStep.terms ||
    StoreOnboardingStep.done => AppRoutes.storeOnboardingTerms,
  };
}
