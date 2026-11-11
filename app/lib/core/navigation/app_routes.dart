import '../../features/onboarding/domain/user_role.dart';

/// 앱의 경로. 화면 이동은 문자열 대신 이 상수로 한다.
abstract final class AppRoutes {
  /// 앱을 켠 직후 첫 세션 값을 기다리는 빈 화면. 값을 받으면 바로 다른 경로로 보낸다.
  static const splash = '/';

  /// 로그인(E1).
  static const login = '/login';

  /// 휴대폰 인증(E2). E1 위에 쌓이므로 뒤로 가면 E1이다.
  static const loginVerify = '/login/verify';

  /// 역할 선택(A1). 역할이 있어도 홈의 "역할 다시 고르기"로 다시 열 수 있다.
  static const role = '/role';

  /// 역할별 홈. 지금은 빈 화면이고 이후 계획이 실제 홈으로 바꾼다.
  static const store = '/store';
  static const brand = '/brand';
  static const creator = '/creator';

  /// [role]의 홈 경로.
  static String homeFor(UserRole role) => switch (role) {
    UserRole.store => store,
    UserRole.brand => brand,
    UserRole.creator => creator,
  };

  /// 역할 선택 화면에서 홈으로 갈 때 `extra`로 넘긴다. 이때만 홈이 밀려 들어오고, 로그인
  /// 직후나 앱을 다시 켰을 때는 제자리에서 나타난다.
  static const fromRoleSelect = 'fromRoleSelect';

  /// 개발 환경 전용 모션 갤러리. 운영 빌드에는 없다.
  static const devMotion = '/dev/motion';

  /// 이 경로 아래는 개발 도구다. 로그인 없이 열 수 있다.
  static const devPrefix = '/dev/';
}
