import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/auth_session.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/phone_verify_page.dart';
import '../../features/auth/presentation/viewmodels/auth_view_model.dart';
import '../../features/dev/presentation/pages/motion_gallery_page.dart';
import '../../features/onboarding/presentation/pages/role_select_placeholder_page.dart';
import '../config/app_config_provider.dart';
import 'app_routes.dart';
import 'cora_transitions.dart';

/// 앱의 라우터. 앱이 떠 있는 동안 하나만 만든다.
///
/// 로그인 상태가 바뀌면 라우터를 새로 만들지 않고 리다이렉트만 다시 돌린다. 새로 만들면
/// 쌓여 있던 화면과 이동 기록이 모두 사라진다.
final appRouterProvider = Provider<GoRouter>((ref) {
  final config = ref.watch(appConfigProvider);
  // 운영으로 컴파일하면 컴파일 시점에 false라 개발 화면 코드가 앱 바이너리에서 빠진다.
  final devScreens = config.devScreensEnabled;

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
      // 로그인 전후는 제자리에서 바뀐다(fade). E2는 E1 위로 밀려 들어오고 뒤로 가면 E1이다.
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) =>
            CoraTransitions.fade(const LoginPage(), key: state.pageKey),
        routes: [
          GoRoute(
            path: 'verify',
            pageBuilder: (context, state) => CoraTransitions.push(
              const PhoneVerifyPage(),
              key: state.pageKey,
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.role,
        pageBuilder: (context, state) => CoraTransitions.fade(
          const RoleSelectPlaceholderPage(),
          key: state.pageKey,
        ),
      ),
      if (devScreens)
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
/// - 세션이 없으면 로그인(`/login`, `/login/verify`) 말고는 어디서든 `/login`.
/// - 세션이 있는데 로그인 화면(또는 첫 화면)이면 `/role`.
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
  final onLoginScreen =
      path == AppRoutes.login || path == AppRoutes.loginVerify;
  if (!signedIn) return onLoginScreen ? null : AppRoutes.login;
  if (onLoginScreen || path == AppRoutes.splash) return AppRoutes.role;
  return null;
}
