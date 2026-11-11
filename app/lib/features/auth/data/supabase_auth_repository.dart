import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, GoTrueClient, Session;

import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';

/// Supabase Auth로 로그인한다. 앱에서 `supabase_flutter`를 아는 기능 코드는 이 파일뿐이다
/// (앱 시작점 main.dart는 SDK 초기화만 한다).
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._auth);

  final GoTrueClient _auth;

  @override
  AuthSession? get currentSession => _toDomain(_auth.currentSession);

  @override
  Stream<AuthSession?> watchSession() {
    return Stream<AuthSession?>.multi((controller) {
      // 첫 값은 지금 세션이다. Supabase.initialize가 저장된 세션을 이미 올려 두었으므로
      // 다시 켠 앱이 로그인 화면을 거치지 않는다.
      controller.add(currentSession);
      // onAuthStateChange는 지난 사건을 처음부터 다시 흘려보낸다(ReplaySubject). 사건에
      // 실린 옛 세션을 그대로 쓰면 지금 세션을 보낸 뒤 옛 값으로 되돌아갈 수 있으므로,
      // 사건은 "바뀌었다"는 신호로만 쓰고 그 순간의 현재 세션을 읽는다.
      final subscription = _auth.onAuthStateChange.listen(
        (_) => controller.add(currentSession),
        // 토큰 갱신의 네트워크 오류도 여기로 온다. 세션이 끝난 것은 아니므로(끝나면 SDK가
        // signedOut을 따로 보낸다) 흘려보내지 않고 디버그 로그만 남긴다.
        onError: (Object error, StackTrace _) => _debugLog('세션 갱신 오류', error),
      );
      controller.onCancel = subscription.cancel;
    }).distinct();
  }

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) => _guard(() async {
    await _auth.signInWithPassword(email: email, password: password);
  });

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) => _guard(() async {
    final response = await _auth.signUp(email: email, password: password);
    // 이메일 인증이 켜진 프로젝트면 세션 없이 돌아와 로그인 화면에 그대로 남는다.
    // 아무 반응이 없는 것보다 실패로 알리는 편이 낫다.
    if (response.session == null) {
      throw const AuthFailure('session_missing_after_sign_up');
    }
  });

  @override
  Future<void> signOut() async {
    if (_auth.currentSession == null) return;
    try {
      // SDK는 서버에 알리기 전에 기기의 세션부터 지운다. 서버 쪽 무효화가 실패해도(오프라인 등)
      // 기기에서는 이미 로그아웃이므로 호출한 쪽에 던지지 않는다.
      await _auth.signOut();
    } catch (error) {
      _debugLog('로그아웃 서버 요청 실패', error);
    }
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on AuthFailure {
      rethrow;
    } on AuthException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        AuthFailure(error.code ?? error.statusCode ?? 'auth_error'),
        stackTrace,
      );
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        AuthFailure('unexpected_${error.runtimeType}'),
        stackTrace,
      );
    }
  }

  static AuthSession? _toDomain(Session? session) => session == null
      ? null
      : AuthSession(userId: session.user.id, accessToken: session.accessToken);

  // 오류의 종류(코드)만 남긴다. 메시지에는 이메일 같은 개인정보가 섞일 수 있다.
  static void _debugLog(String what, Object error) {
    if (!kDebugMode) return;
    final code = error is AuthException
        ? (error.code ?? error.statusCode)
        : error.runtimeType;
    debugPrint('[auth] $what: $code');
  }
}
