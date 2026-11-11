import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/auth_repository_provider.dart';
import '../../domain/auth_session.dart';

final authViewModelProvider =
    StreamNotifierProvider<AuthViewModel, AuthSession?>(AuthViewModel.new);

/// 앱 전체의 로그인 상태. 라우터가 이 값을 보고 로그인 화면과 로그인 뒤 화면을 고른다.
/// 값이 null이면 로그아웃 상태다.
class AuthViewModel extends StreamNotifier<AuthSession?> {
  @override
  Stream<AuthSession?> build() =>
      ref.watch(authRepositoryProvider).watchSession();

  /// 로그아웃. 세션이 끝나면 라우터가 로그인 화면으로 보낸다.
  Future<void> signOut() => ref.read(authRepositoryProvider).signOut();
}
