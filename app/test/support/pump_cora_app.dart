import 'package:cora/app.dart';
import 'package:cora/core/config/app_config.dart';
import 'package:cora/core/config/app_config_provider.dart';
import 'package:cora/core/navigation/app_router.dart';
import 'package:cora/features/auth/domain/auth_repository_provider.dart';
import 'package:cora/features/brand_onboarding/domain/brand_repository.dart';
import 'package:cora/features/brand_onboarding/domain/campaign_repository.dart';
import 'package:cora/features/chat/domain/chat_repository.dart';
import 'package:cora/features/chat/domain/realtime_connection.dart';
import 'package:cora/features/collaboration/domain/collaboration_repository.dart';
import 'package:cora/features/discovery/domain/discovery_repository.dart';
import 'package:cora/features/interests/domain/interests_repository.dart';
import 'package:cora/features/negotiation/domain/negotiation_repository.dart';
import 'package:cora/features/notification_settings/domain/notification_settings_repository.dart';
import 'package:cora/features/notifications/domain/notification_repository.dart';
import 'package:cora/features/principles/domain/principles_repository.dart';
import 'package:cora/features/onboarding/domain/me_repository_provider.dart';
import 'package:cora/features/proposals/domain/proposal_repository.dart';
import 'package:cora/features/received_proposals/domain/received_proposals_repository.dart';
import 'package:cora/features/server_config/domain/server_config_repository.dart';
import 'package:cora/features/store_home/domain/store_home_repository.dart';
import 'package:cora/features/wallet/domain/wallet_repository.dart';
import 'package:cora/features/store_onboarding/domain/content_draft_repository_provider.dart';
import 'package:cora/features/store_onboarding/domain/store_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/fake_auth_repository.dart';
import '../features/brand_onboarding/fake_brand_repository.dart';
import '../features/brand_onboarding/fake_campaign_repository.dart';
import '../features/chat/chat_fixtures.dart';
import '../features/collaboration/fake_collaboration_repository.dart';
import '../features/discovery/fake_discovery_repository.dart';
import '../features/interests/fake_interests_repository.dart';
import '../features/negotiation/fake_negotiation_repository.dart';
import '../features/notification_settings/fake_notification_settings_repository.dart';
import '../features/notifications/fake_notification_repository.dart';
import '../features/onboarding/fake_me_repository.dart';
import '../features/principles/fake_principles_repository.dart';
import '../features/proposals/fake_proposal_repository.dart';
import '../features/received_proposals/fake_received_proposals_repository.dart';
import '../features/server_config/fake_server_config_repository.dart';
import '../features/store_home/fake_store_home_repository.dart';
import '../features/store_onboarding/fake_content_draft_repository.dart';
import '../features/store_onboarding/fake_store_repository.dart';
import '../features/wallet/fake_wallet_repository.dart';

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
      // 홈의 종 아이콘이 읽지 않은 알림 수를 읽는다. 기본은 알림이 없는 계정이다.
      if (!_overrides(overrides, notificationRepositoryProvider))
        notificationRepositoryProvider.overrideWithValue(
          FakeNotificationRepository(),
        ),
      // 알림함의 설정 아이콘이 알림 설정(E5)을 연다.
      if (!_overrides(overrides, notificationSettingsRepositoryProvider))
        notificationSettingsRepositoryProvider.overrideWithValue(
          FakeNotificationSettingsRepository(),
        ),
      // 알림함의 정산 줄이 정산(E7)을 연다.
      if (!_overrides(overrides, walletRepositoryProvider))
        walletRepositoryProvider.overrideWithValue(FakeWalletRepository()),
      // 보상·예산 설정(F1)과 오퍼 보내기가 서버 설정(범위, 수수료율)을 읽는다.
      if (!_overrides(overrides, serverConfigRepositoryProvider))
        serverConfigRepositoryProvider.overrideWithValue(
          FakeServerConfigRepository(),
        ),
      // 제안함(F3)과 받은 오퍼의 `제안함` 줄이 읽는다. 기본은 제안이 없는 계정이다.
      if (!_overrides(overrides, proposalRepositoryProvider))
        proposalRepositoryProvider.overrideWithValue(FakeProposalRepository()),
      // 브랜드 진입이 프로필과 진행 중인 캠페인을 읽는다. 기본은 둘 다 있어 발견(01)이 열리는 브랜드다.
      if (!_overrides(overrides, brandRepositoryProvider))
        brandRepositoryProvider.overrideWithValue(
          FakeBrandRepository(profile: defaultBrandProfile),
        ),
      if (!_overrides(overrides, campaignRepositoryProvider))
        campaignRepositoryProvider.overrideWithValue(
          FakeCampaignRepository(active: defaultCampaign),
        ),
      if (!_overrides(overrides, discoveryRepositoryProvider))
        discoveryRepositoryProvider.overrideWithValue(
          FakeDiscoveryRepository(),
        ),
      // 08 크리에이터의 발견이 협업 원칙이 있는지 읽는다. 기본은 원칙을 정한 크리에이터다.
      if (!_overrides(overrides, principlesRepositoryProvider))
        principlesRepositoryProvider.overrideWithValue(
          FakePrinciplesRepository(principles: defaultPrinciples),
        ),
      // 03 관심·보류가 저장한 후보를 읽는다. 기본은 저장한 후보가 없는 계정이다.
      if (!_overrides(overrides, interestsRepositoryProvider))
        interestsRepositoryProvider.overrideWithValue(
          FakeInterestsRepository(),
        ),
      // 06 조건 협의가 협업의 최신 조건 판본을 읽는다. 기본은 아무도 확인하지 않은 판본 1이다.
      if (!_overrides(overrides, negotiationRepositoryProvider))
        negotiationRepositoryProvider.overrideWithValue(
          FakeNegotiationRepository(),
        ),
      // 대화 목록과 실시간 연결. 기본은 대화가 없는 계정이고 연결은 아무 일도 밀어 주지 않는다.
      if (!_overrides(overrides, chatRepositoryProvider))
        chatRepositoryProvider.overrideWithValue(FakeChatRepository()),
      if (!_overrides(overrides, realtimeConnectionProvider))
        realtimeConnectionProvider.overrideWithValue(FakeRealtimeConnection()),
      // 03 맨 위 `받은 제안` 묶음과 10이 읽는다. 기본은 받은 제안이 없는 계정이다.
      if (!_overrides(overrides, receivedProposalsRepositoryProvider))
        receivedProposalsRepositoryProvider.overrideWithValue(
          FakeReceivedProposalsRepository(),
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
/// 브랜드 발견(01) 아래 메뉴의 `프로필`을 눌러 자리 화면(역할 다시 고르기, 로그아웃)을 연다.
Future<void> openBrandProfile(WidgetTester tester) async {
  await tester.tap(find.text('프로필'));
  await tester.pumpAndSettle();
}

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
