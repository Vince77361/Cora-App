import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/auth_repository.dart';
import '../../domain/auth_repository_provider.dart';

/// 로그인 화면을 떠나면 실패 상태도 함께 버리도록 autoDispose로 둔다.
final loginViewModelProvider =
    AsyncNotifierProvider.autoDispose<LoginViewModel, void>(LoginViewModel.new);

/// E1의 카카오·네이버 로그인 상태. 진행 중이면 로딩, 실패하면 [AsyncError]로 남는다.
/// 휴대폰 번호 로그인은 E2에서 하므로 여기에 없다.
///
/// 성공하면 세션이 바뀌고 라우터가 화면을 옮기므로 여기서 이동하지 않는다.
class LoginViewModel extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> signInWithKakao() => _submit((repo) => repo.signInWithKakao());

  Future<void> signInWithNaver() => _submit((repo) => repo.signInWithNaver());

  Future<void> _submit(
    Future<void> Function(AuthRepository repo) action,
  ) async {
    // 버튼을 두 번 눌러도 요청은 하나만 간다.
    if (state.isLoading) return;
    final repo = ref.read(authRepositoryProvider);
    state = const AsyncLoading();
    try {
      await action(repo);
      // 성공하면 라우터가 이 화면을 치워 이 ViewModel이 먼저 사라질 수 있다.
      if (ref.mounted) state = const AsyncData(null);
    } catch (error, stackTrace) {
      // 실패의 종류는 저장소가 디버그 로그로 남긴다. 화면에는 정해진 문구를 보여 준다.
      if (ref.mounted) state = AsyncError(error, stackTrace);
    }
  }
}
