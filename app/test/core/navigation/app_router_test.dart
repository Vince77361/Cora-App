import 'package:cora/core/config/app_config.dart';
import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/features/auth/presentation/pages/dev_login_page.dart';
import 'package:cora/features/auth/presentation/pages/login_unavailable_page.dart';
import 'package:cora/features/dev/presentation/pages/motion_gallery_page.dart';
import 'package:cora/features/onboarding/presentation/pages/role_select_placeholder_page.dart';
import 'package:cora/core/network/api_client_provider.dart';
import 'package:cora_api/api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/fake_auth_repository.dart';
import '../../support/fake_http_client.dart';
import '../../support/pump_cora_app.dart';

List<String> _paths(List<RouteBase> routes) => [
  for (final route in routes) ...[
    if (route is GoRoute) route.path,
    ..._paths(route.routes),
  ],
];

Future<void> _openGallery(WidgetTester tester) async {
  await tester.tap(find.text('모션 갤러리'));
  await tester.pumpAndSettle();
  expect(find.byType(MotionGalleryPage), findsOneWidget);
}

Future<void> _openDemo(WidgetTester tester, String label) async {
  final row = find.text(label);
  await tester.ensureVisible(row);
  await tester.pumpAndSettle();
  await tester.tap(row);
  await tester.pumpAndSettle();
  expect(find.text('닫기'), findsOneWidget, reason: label);
}

void main() {
  testWidgets('redirects to /login when there is no session', (tester) async {
    await pumpCoraApp(tester, auth: FakeAuthRepository());

    expect(find.byType(DevLoginPage), findsOneWidget);
    expect(currentPath(tester), AppRoutes.login);
  });

  testWidgets('redirects any location to /login without a session', (
    tester,
  ) async {
    await pumpCoraApp(tester, auth: FakeAuthRepository());

    routerOf(tester).go(AppRoutes.role);
    await tester.pumpAndSettle();

    expect(find.byType(RoleSelectPlaceholderPage), findsNothing);
    expect(find.byType(DevLoginPage), findsOneWidget);
  });

  testWidgets('redirects from /login to /role once signed in', (tester) async {
    final auth = FakeAuthRepository();
    await pumpCoraApp(tester, auth: auth);

    await tester.enterText(
      find.widgetWithText(TextField, '이메일'),
      ' dev@example.com ',
    );
    await tester.enterText(find.widgetWithText(TextField, '비밀번호'), 'secret1');
    await tester.tap(find.text('로그인'));
    await tester.pumpAndSettle();

    expect(auth.signInCalls, 1);
    expect(auth.lastEmail, 'dev@example.com');
    expect(find.byType(DevLoginPage), findsNothing);
    expect(find.byType(RoleSelectPlaceholderPage), findsOneWidget);
    expect(currentPath(tester), AppRoutes.role);
  });

  testWidgets('sends a signed-in user away from /login', (tester) async {
    await pumpCoraApp(
      tester,
      auth: FakeAuthRepository(session: FakeAuthRepository.signedInSession),
    );

    routerOf(tester).go(AppRoutes.login);
    await tester.pumpAndSettle();

    expect(find.byType(DevLoginPage), findsNothing);
    expect(currentPath(tester), AppRoutes.role);
  });

  testWidgets('returns to /login when the API answers 401', (tester) async {
    final fakeHttp = FakeHttpClient()
      ..statusCode = 401
      ..body = unauthenticatedBody;
    final fake = FakeAuthRepository(
      session: FakeAuthRepository.signedInSession,
    );
    await pumpCoraApp(
      tester,
      auth: fake,
      overrides: [httpClientProvider.overrideWithValue(fakeHttp)],
    );
    expect(find.byType(RoleSelectPlaceholderPage), findsOneWidget);

    // 서버가 지금 세션의 토큰을 거부한다. 요청한 쪽은 오류를 받고, 앱은 로그인 화면으로 간다.
    await expectLater(
      UsersApi(containerOf(tester).read(apiClientProvider)).getMe(),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 401)),
    );
    await tester.pumpAndSettle();

    expect(fake.signOutCalls, 1);
    expect(find.byType(DevLoginPage), findsOneWidget);
    expect(find.byType(RoleSelectPlaceholderPage), findsNothing);
  });

  testWidgets('returns to /login when the session ends', (tester) async {
    final fake = FakeAuthRepository(
      session: FakeAuthRepository.signedInSession,
    );
    await pumpCoraApp(tester, auth: fake);
    expect(find.byType(RoleSelectPlaceholderPage), findsOneWidget);

    fake.endSession();
    await tester.pumpAndSettle();

    expect(find.byType(DevLoginPage), findsOneWidget);
    expect(find.byType(RoleSelectPlaceholderPage), findsNothing);
  });

  testWidgets('logging out from the placeholder returns to /login', (
    tester,
  ) async {
    final fake = FakeAuthRepository(
      session: FakeAuthRepository.signedInSession,
    );
    await pumpCoraApp(tester, auth: fake);

    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();

    expect(fake.signOutCalls, 1);
    expect(find.byType(DevLoginPage), findsOneWidget);
  });

  testWidgets('a cold start with a stored session never shows /login', (
    tester,
  ) async {
    await tester.pumpWidget(
      coraAppWith(
        FakeAuthRepository(session: FakeAuthRepository.signedInSession),
      ),
    );
    for (var frame = 0; frame < 30; frame++) {
      expect(find.byType(DevLoginPage), findsNothing, reason: 'frame $frame');
      expect(find.byType(LoginUnavailablePage), findsNothing);
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pumpAndSettle();

    expect(find.byType(RoleSelectPlaceholderPage), findsOneWidget);
  });

  testWidgets('keeps one router across auth changes', (tester) async {
    final fake = FakeAuthRepository();
    await pumpCoraApp(tester, auth: fake);
    final before = routerOf(tester);

    fake.setSession(FakeAuthRepository.signedInSession);
    await tester.pumpAndSettle();
    fake.endSession();
    await tester.pumpAndSettle();

    expect(identical(routerOf(tester), before), isTrue);
  });

  testWidgets('prod build has no email login form', (tester) async {
    await pumpCoraApp(tester, auth: FakeAuthRepository(), env: CoraEnv.prod);

    expect(find.byType(DevLoginPage), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('로그인 준비 중이에요.'), findsOneWidget);
    expect(find.text('모션 갤러리'), findsNothing);
  });

  testWidgets('prod build does not register /dev/motion', (tester) async {
    await pumpCoraApp(
      tester,
      auth: FakeAuthRepository(session: FakeAuthRepository.signedInSession),
      env: CoraEnv.prod,
    );
    final router = routerOf(tester);
    expect(_paths(router.configuration.routes), isNot(contains('/dev/motion')));

    router.go(AppRoutes.devMotion);
    await tester.pumpAndSettle();

    expect(find.byType(MotionGalleryPage), findsNothing);
    expect(find.byType(RoleSelectPlaceholderPage), findsOneWidget);
  });

  testWidgets('dev build registers /dev/motion', (tester) async {
    await pumpCoraApp(tester, auth: FakeAuthRepository());

    expect(
      _paths(routerOf(tester).configuration.routes),
      contains('/dev/motion'),
    );
  });

  testWidgets('dev login page opens the motion gallery without a session', (
    tester,
  ) async {
    usePhone(tester);
    await pumpCoraApp(tester, auth: FakeAuthRepository());

    await _openGallery(tester);
  });

  // iOS 가장자리 밀기는 테마의 플랫폼을 바꿔야 해서 motion_gallery_page_test.dart에서 본다.
  testWidgets('system back closes a gallery demo before leaving the gallery', (
    tester,
  ) async {
    usePhone(tester);
    await pumpCoraApp(tester, auth: FakeAuthRepository());
    await _openGallery(tester);
    await _openDemo(tester, 'push 전환');

    await systemBack(tester);

    expect(find.text('닫기'), findsNothing);
    expect(find.byType(MotionGalleryPage), findsOneWidget);

    await systemBack(tester);

    expect(find.byType(MotionGalleryPage), findsNothing);
    expect(find.byType(DevLoginPage), findsOneWidget);
  });
}
