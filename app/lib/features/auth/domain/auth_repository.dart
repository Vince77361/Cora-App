import 'auth_session.dart';

/// 로그인과 세션을 다루는 포트. 실제 구현은 `data`의 Supabase 구현이고, 테스트는 가짜를 쓴다.
///
/// 로그인·가입이 실패하면 [AuthFailure]를 던진다. 외부 SDK의 오류 타입은 이 경계 밖으로
/// 나가지 않는다.
abstract class AuthRepository {
  /// 세션이 바뀔 때마다 알린다(로그인, 로그아웃, 토큰 갱신).
  ///
  /// 구독하면 지금 세션부터 먼저 보낸다. 저장된 세션으로 앱을 다시 켰을 때 로그인 화면이
  /// 잠깐 보이지 않게 하려는 것이다.
  Stream<AuthSession?> watchSession();

  /// 지금 세션. 화면 분기처럼 기다릴 수 없는 곳에서 쓴다. API 요청에 붙일 토큰은
  /// [validAccessToken]으로 받는다.
  AuthSession? get currentSession;

  /// 요청에 붙일 유효한 액세스 토큰. 세션이 없으면 null.
  ///
  /// 저장된 세션으로 앱을 켜거나 백그라운드에서 돌아온 직후에는 액세스 토큰이 이미 만료된
  /// 채로 [currentSession]에 있고, 갱신은 뒤에서 늦게 끝난다. 그 토큰으로 요청하면 서버가
  /// 401을 주고, 멀쩡한 세션이 로그아웃으로 끝난다. 그래서 만료됐으면 갱신이 끝날 때까지
  /// 기다린 뒤 새 토큰을 돌려준다. 갱신이 실패해도 던지지 않는다(리프레시 토큰이 무효면
  /// 세션 종료는 [watchSession]으로 알린다).
  Future<String?> validAccessToken();

  Future<void> signInWithEmail({
    required String email,
    required String password,
  });

  /// 개발용 이메일 가입. 성공하면 바로 로그인된다(개발용 프로젝트는 이메일 인증을 꺼 둔다).
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  });

  /// 로그아웃. 이미 로그아웃 상태여도 던지지 않는다.
  Future<void> signOut();
}

/// 인증 작업이 실패했다. [code]는 디버그 로그와 분기에만 쓰고 화면에 그대로 보여 주지 않는다.
class AuthFailure implements Exception {
  const AuthFailure(this.code);

  /// 예: `invalid_credentials`, `user_already_exists`, `weak_password`.
  final String code;

  @override
  String toString() => 'AuthFailure($code)';
}
