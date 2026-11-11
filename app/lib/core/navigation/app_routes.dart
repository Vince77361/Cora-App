/// 앱의 경로. 화면 이동은 문자열 대신 이 상수로 한다.
abstract final class AppRoutes {
  /// 앱을 켠 직후 첫 세션 값을 기다리는 빈 화면. 값을 받으면 바로 다른 경로로 보낸다.
  static const splash = '/';

  /// 로그인(E1).
  static const login = '/login';

  /// 휴대폰 인증(E2). E1 위에 쌓이므로 뒤로 가면 E1이다.
  static const loginVerify = '/login/verify';

  /// 역할 선택(A1). 지금은 임시 화면이고 Task 10이 채운다.
  static const role = '/role';

  /// 개발 환경 전용 모션 갤러리. 운영 빌드에는 없다.
  static const devMotion = '/dev/motion';

  /// 이 경로 아래는 개발 도구다. 로그인 없이 열 수 있다.
  static const devPrefix = '/dev/';
}
