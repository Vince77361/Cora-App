import 'package:cora/app.dart';
import 'package:cora/core/config/app_config.dart';
import 'package:cora/core/config/app_config_provider.dart';
import 'package:cora/core/navigation/app_router.dart';
import 'package:cora/features/auth/domain/auth_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/fake_auth_repository.dart';

AppConfig testConfig(CoraEnv env) => AppConfig(
  env: env,
  supabaseUrl: 'https://example.supabase.co',
  supabaseAnonKey: 'anon',
  apiBaseUrl: 'http://127.0.0.1:3000',
  authAdapter: AuthAdapter.fake,
);

/// 가짜 인증 저장소와 설정으로 실제 [CoraApp]을 띄운다.
///
/// [overrides]로 다른 provider(예: 가짜 HTTP 클라이언트)도 바꿔 끼운다.
Widget coraAppWith(
  FakeAuthRepository auth, {
  CoraEnv env = CoraEnv.dev,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      appConfigProvider.overrideWithValue(testConfig(env)),
      ...overrides,
    ],
    child: const CoraApp(),
  );
}

Future<void> pumpCoraApp(
  WidgetTester tester, {
  required FakeAuthRepository auth,
  CoraEnv env = CoraEnv.dev,
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(coraAppWith(auth, env: env, overrides: overrides));
  await tester.pumpAndSettle();
}

ProviderContainer containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(CoraApp)));

GoRouter routerOf(WidgetTester tester) =>
    containerOf(tester).read(appRouterProvider);

String currentPath(WidgetTester tester) =>
    routerOf(tester).routerDelegate.currentConfiguration.uri.path;

/// iPhone 15 Pro 크기(390 x 844)로 띄운다.
void usePhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1179, 2556);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// 기획 캔버스와 같은 390 x 844(캔버스 좌표를 그대로 비교할 때).
void useCanvasPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// 작은 휴대폰(360 x 640)에 글자 1.3배.
void useSmallPhoneWithLargeText(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = 1.3;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

/// Android의 시스템 뒤로 가기(버튼·제스처)를 엔진이 보내는 그대로 보낸다.
Future<void> systemBack(WidgetTester tester) async {
  final message = const JSONMethodCodec().encodeMethodCall(
    const MethodCall('popRoute'),
  );
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/navigation',
    message,
    (_) {},
  );
  await tester.pumpAndSettle();
}
