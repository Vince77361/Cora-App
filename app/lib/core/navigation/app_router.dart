import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/auth_session.dart';
import '../../features/auth/presentation/pages/dev_login_page.dart';
import '../../features/auth/presentation/pages/login_unavailable_page.dart';
import '../../features/auth/presentation/viewmodels/auth_view_model.dart';
import '../../features/dev/presentation/pages/motion_gallery_page.dart';
import '../../features/onboarding/presentation/pages/role_select_placeholder_page.dart';
import '../config/app_config_provider.dart';
import 'app_routes.dart';
import 'cora_transitions.dart';

/// 운영 빌드(`CORA_ENV=prod`로 컴파일)에서는 컴파일 시점에 false다. 개발용 화면을 쓰는
/// 자리마다 이 상수로 먼저 막아 두면 컴파일러가 그 화면 코드를 앱 바이너리에서 뺀다
/// (기술 스택 설계: "운영 빌드에서는 이메일 로그인 화면을 빼고 빌드한다").
/// 실행 중의 판단은 `AppConfig.isDev`가 한다. 테스트는 이 값이 true인 채로 설정만 바꾼다.
const _devScreensCompiledIn = String.fromEnvironment('CORA_ENV') != 'prod';

/// 앱의 라우터. 앱이 떠 있는 동안 하나만 만든다.
///
/// 로그인 상태가 바뀌면 라우터를 새로 만들지 않고 리다이렉트만 다시 돌린다. 새로 만들면
/// 쌓여 있던 화면과 이동 기록이 모두 사라진다.
final appRouterProvider = Provider<GoRouter>((ref) {
  final config = ref.watch(appConfigProvider);
  final devScreens = _devScreensCompiledIn && config.isDev;

  final auth = ValueNotifier<AsyncValue<AuthSession?>>(const AsyncLoading());
  ref.listen(
    authViewModelProvider,
    (_, next) => auth.value = next,
    fireImmediately: true,
  );

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: auth,
    redirect: (context, state) =>
        _authRedirect(auth.value, state.uri.path, devScreens: devScreens),
    // 없는 경로(예: 운영 빌드의 /dev/motion)는 오류 화면 대신 첫 화면에서 다시 고른다.
    onException: (context, state, router) => router.go(AppRoutes.splash),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) =>
            NoTransitionPage(key: state.pageKey, child: const Scaffold()),
      ),
      // 로그인 전후는 제자리에서 바뀐다(fade).
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => CoraTransitions.fade(
          _devScreensCompiledIn && config.isDev
              ? const DevLoginPage()
              : const LoginUnavailablePage(),
          key: state.pageKey,
        ),
      ),
      GoRoute(
        path: AppRoutes.role,
        pageBuilder: (context, state) => CoraTransitions.fade(
          const RoleSelectPlaceholderPage(),
          key: state.pageKey,
        ),
      ),
      if (_devScreensCompiledIn && config.isDev)
        GoRoute(
          path: AppRoutes.devMotion,
          pageBuilder: (context, state) => CoraTransitions.push(
            const MotionGalleryPage(),
            key: state.pageKey,
          ),
        ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    auth.dispose();
  });
  return router;
});

/// 로그인 상태에 따른 이동 규칙.
///
/// - 첫 세션 값을 받기 전(앱을 켠 직후 한 프레임)에는 빈 첫 화면에 머문다. 여기서 로그인
///   화면을 먼저 띄우면 저장된 세션이 있는 사람에게 로그인 화면이 깜빡인다.
/// - 세션이 없으면 어디서든 `/login`.
/// - 세션이 있는데 `/login`(또는 첫 화면)이면 `/role`.
/// - 개발 환경의 `/dev/…`는 로그인과 상관없이 연다(로그인 화면의 "모션 갤러리"에서 들어간다).
String? _authRedirect(
  AsyncValue<AuthSession?> auth,
  String path, {
  required bool devScreens,
}) {
  if (devScreens && path.startsWith(AppRoutes.devPrefix)) return null;
  if (!auth.hasValue && !auth.hasError) {
    return path == AppRoutes.splash ? null : AppRoutes.splash;
  }
  final signedIn = auth.value != null;
  if (!signedIn) return path == AppRoutes.login ? null : AppRoutes.login;
  if (path == AppRoutes.login || path == AppRoutes.splash) {
    return AppRoutes.role;
  }
  return null;
}
