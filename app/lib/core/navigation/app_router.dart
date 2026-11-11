import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/auth_session.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/phone_verify_page.dart';
import '../../features/auth/presentation/viewmodels/auth_view_model.dart';
import '../../features/dev/presentation/pages/motion_gallery_page.dart';
import '../../features/onboarding/domain/me.dart';
import '../../features/onboarding/domain/user_role.dart';
import '../../features/onboarding/presentation/pages/role_home_placeholder_page.dart';
import '../../features/onboarding/presentation/pages/role_select_page.dart';
import '../../features/onboarding/presentation/viewmodels/me_view_model.dart';
import '../config/app_config.dart';
import '../config/app_config_provider.dart';
import 'app_routes.dart';
import 'cora_transitions.dart';

/// 앱의 라우터. 앱이 떠 있는 동안 하나만 만든다.
///
/// 로그인 상태나 내 정보(역할)가 바뀌면 라우터를 새로 만들지 않고 리다이렉트만 다시 돌린다.
/// 새로 만들면 쌓여 있던 화면과 이동 기록이 모두 사라진다.
final appRouterProvider = Provider<GoRouter>((ref) {
  final config = ref.watch(appConfigProvider);
  // 개발 화면(`/dev/…`)은 운영으로 컴파일하면 상수 false로 막혀 앱 바이너리에서 빠진다.
  final devScreens = kDevScreensCompiledIn && config.isDev;

  // 두 상태 중 무엇이 바뀌어도 리다이렉트를 다시 돌린다. 값은 리다이렉트가 돌 때 그 순간의
  // 것을 읽는다. 로그인 상태가 바뀐 직후에는 내 정보가 아직 옛 사용자의 것일 수 있어서,
  // 알림으로 받은 값을 들고 있으면 한 박자 어긋난다.
  final refresh = _RouterRefresh();
  ref.listen(authViewModelProvider, (_, _) => refresh.notify());
  ref.listen(meViewModelProvider, (_, _) => refresh.notify());

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => _redirect(
      ref.read(authViewModelProvider),
      ref.read(meViewModelProvider),
      state.uri.path,
      devScreens: devScreens,
    ),
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
        pageBuilder: (context, state) =>
            CoraTransitions.fade(const RoleSelectPage(), key: state.pageKey),
      ),
      // 역할 선택에서 고른 직후에는 홈이 밀려 들어오고(push), 로그인 직후나 앱을 다시 켰을 때는
      // 제자리에서 나타난다(fade).
      for (final role in UserRole.values)
        GoRoute(
          path: AppRoutes.homeFor(role),
          pageBuilder: (context, state) {
            final page = RoleHomePlaceholderPage(role: role);
            return state.extra == AppRoutes.fromRoleSelect
                ? CoraTransitions.push(page, key: state.pageKey)
                : CoraTransitions.fade(page, key: state.pageKey);
          },
        ),
      if (kDevScreensCompiledIn && config.isDev)
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
    refresh.dispose();
  });
  return router;
});

/// 리다이렉트를 다시 돌리라고 알리기만 하는 신호.
class _RouterRefresh extends ChangeNotifier {
  void notify() => notifyListeners();
}

/// 로그인 상태와 내 정보(역할)에 따른 이동 규칙.
///
/// - 첫 세션 값을 받기 전(앱을 켠 직후 한 프레임)에는 빈 첫 화면에 머문다. 여기서 로그인
///   화면을 먼저 띄우면 저장된 세션이 있는 사람에게 로그인 화면이 깜빡인다.
/// - 세션이 없으면 로그인(`/login`, `/login/verify`) 말고는 어디서든 `/login`.
/// - 세션이 있고 내 정보를 불러오는 중이면 빈 첫 화면에서 기다린다. 역할을 알기 전에
///   역할 선택이나 홈을 먼저 띄우면 잘못된 화면이 깜빡인다.
/// - 내 정보를 불러오지 못하면 `/role`로 보낸다. 거기서 오류와 "다시 시도"를 보여 준다.
/// - 역할이 없으면 `/role`, 있으면 그 역할의 홈. `/role`은 역할이 있어도 열린다(홈의
///   "역할 다시 고르기"). 다른 역할의 홈은 내 역할의 홈으로 돌려보낸다.
/// - 개발 환경의 `/dev/…`는 로그인과 상관없이 연다(E1의 로고를 길게 눌러 모션 갤러리로 들어간다).
String? _redirect(
  AsyncValue<AuthSession?> auth,
  AsyncValue<Me?> me,
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

  // 불러오는 중에는 이전 값(옛 사용자나 이전 오류)이 남아 있을 수 있어서 isLoading을 먼저 본다.
  if (me.isLoading) return path == AppRoutes.splash ? null : AppRoutes.splash;
  if (me.hasError) return path == AppRoutes.role ? null : AppRoutes.role;
  final profile = me.value;
  // 로그인한 직후 내 정보가 아직 로그아웃 때의 null이면 불러오기가 시작되기 전이다.
  if (profile == null) {
    return path == AppRoutes.splash ? null : AppRoutes.splash;
  }

  final role = profile.role;
  if (role == null) return path == AppRoutes.role ? null : AppRoutes.role;
  final home = AppRoutes.homeFor(role);
  if (onLoginScreen || path == AppRoutes.splash) return home;
  final isHome = UserRole.values.any((r) => AppRoutes.homeFor(r) == path);
  if (isHome && path != home) return home;
  return null;
}
