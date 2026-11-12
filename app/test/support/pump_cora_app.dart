import 'package:cora/app.dart';
import 'package:cora/core/config/app_config.dart';
import 'package:cora/core/config/app_config_provider.dart';
import 'package:cora/core/navigation/app_router.dart';
import 'package:cora/features/auth/domain/auth_repository_provider.dart';
import 'package:cora/features/collaboration/domain/collaboration_repository.dart';
import 'package:cora/features/onboarding/domain/me_repository_provider.dart';
import 'package:cora/features/store_home/domain/store_home_repository.dart';
import 'package:cora/features/store_onboarding/domain/content_draft_repository_provider.dart';
import 'package:cora/features/store_onboarding/domain/store_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/fake_auth_repository.dart';
import '../features/collaboration/fake_collaboration_repository.dart';
import '../features/onboarding/fake_me_repository.dart';
import '../features/store_home/fake_store_home_repository.dart';
import '../features/store_onboarding/fake_content_draft_repository.dart';
import '../features/store_onboarding/fake_store_repository.dart';

AppConfig testConfig(CoraEnv env) => AppConfig(
  env: env,
  supabaseUrl: 'https://example.supabase.co',
  supabaseAnonKey: 'anon',
  apiBaseUrl: 'http://127.0.0.1:3000',
  authAdapter: AuthAdapter.fake,
);

bool _overrides(List<Override> overrides, Object provider) =>
    overrides.any((o) => o.origin == provider);

/// 가짜 인증 저장소와 설정으로 실제 [CoraApp]을 띄운다.
///
/// [me]는 서버가 가진 내 정보 흉내다(주지 않으면 역할을 아직 안 고른 사용자).
/// [overrides]로 다른 provider(예: 가짜 HTTP 클라이언트)도 바꿔 끼운다.
/// [meRepositoryOverride]를 주면 가짜 내 정보 저장소 대신 이것을 쓴다(실제 `ApiMeRepository`를
/// 가짜 HTTP 위에 올릴 때).
Widget coraAppWith(
  FakeAuthRepository auth, {
  FakeMeRepository? me,
  CoraEnv env = CoraEnv.dev,
  List<Override> overrides = const [],
  Override? meRepositoryOverride,
}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      meRepositoryOverride ??
          meRepositoryProvider.overrideWithValue(me ?? FakeMeRepository()),
      appConfigProvider.overrideWithValue(testConfig(env)),
      // 가게 역할의 진입이 내 가게를 읽으므로 기본은 가게가 없는 사장님이다. 테스트가 같은
      // provider를 직접 바꿔 끼우면 그쪽을 쓴다(같은 provider를 두 번 바꿀 수 없다).
      if (!_overrides(overrides, storeRepositoryProvider))
        storeRepositoryProvider.overrideWithValue(FakeStoreRepository()),
      if (!_overrides(overrides, storeHomeRepositoryProvider))
        storeHomeRepositoryProvider.overrideWithValue(
          FakeStoreHomeRepository(),
        ),
      // 사장님 홈이 보낸 오퍼 줄의 협업 단계를 읽는다.
      if (!_overrides(overrides, collaborationRepositoryProvider))
        collaborationRepositoryProvider.overrideWithValue(
          FakeCollaborationRepository(),
        ),
      if (!_overrides(overrides, contentDraftRepositoryProvider))
        contentDraftRepositoryProvider.overrideWithValue(
          FakeContentDraftRepository(),
        ),
      ...overrides,
    ],
    child: const CoraApp(),
  );
}

Future<void> pumpCoraApp(
  WidgetTester tester, {
  required FakeAuthRepository auth,
  FakeMeRepository? me,
  CoraEnv env = CoraEnv.dev,
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    coraAppWith(auth, me: me, env: env, overrides: overrides),
  );
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
