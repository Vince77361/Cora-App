import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/auth_repository.dart';
import 'auth_view_model.dart';

/// 로그인 화면을 떠나면 오류 상태도 함께 버리도록 autoDispose로 둔다.
final devLoginViewModelProvider =
    AsyncNotifierProvider.autoDispose<DevLoginViewModel, void>(
      DevLoginViewModel.new,
    );

/// 개발용 이메일 로그인·가입의 제출 상태. 진행 중이면 로딩, 실패하면 [AsyncError]로 남는다.
///
/// 성공하면 세션이 바뀌고 라우터가 화면을 옮기므로 여기서 이동하지 않는다.
class DevLoginViewModel extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> signIn({required String email, required String password}) =>
      _submit((repo) => repo.signInWithEmail(email: email, password: password));

  Future<void> signUp({required String email, required String password}) =>
      _submit((repo) => repo.signUpWithEmail(email: email, password: password));

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
      // 코드만 남긴다. 화면에는 SDK 원문 대신 정해진 문구를 보여 준다.
      if (kDebugMode) {
        final code = error is AuthFailure ? error.code : error.runtimeType;
        debugPrint('[auth] 개발용 로그인 실패: $code');
      }
      if (ref.mounted) state = AsyncError(error, stackTrace);
    }
  }
}
