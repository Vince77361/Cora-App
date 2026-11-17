import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/time/clock.dart';
import 'package:cora/features/chat/domain/chat_repository.dart';
import 'package:cora/features/chat/domain/realtime_connection.dart';
import 'package:cora/features/collaboration/domain/collaboration_repository.dart';
import 'package:cora/features/discovery/domain/discovery_repository.dart';
import 'package:cora/features/onboarding/domain/user_role.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_clock.dart';
import '../../support/pump_cora_app.dart';
import '../collaboration/fake_collaboration_repository.dart';
import '../discovery/fake_discovery_repository.dart';
import '../auth/fake_auth_repository.dart';
import '../onboarding/fake_me_repository.dart';
import '../store_browse/creator_app_harness.dart' show pumpCreatorApp;
import '../store_home/store_home_harness.dart' show pumpStoreHome;
import 'chat_fixtures.dart';

/// [role]로 로그인한 실제 [CoraApp]을 띄운다(첫 화면은 그 역할의 홈). 시계는 한국 시간 2026-11-11 21:00이다.
Future<void> pumpChatApp(
  WidgetTester tester, {
  UserRole role = UserRole.brand,
  FakeChatRepository? chat,
  FakeRealtimeConnection? realtime,
  FakeClock? clock,
  FakeDiscoveryRepository? discovery,
  FakeCollaborationRepository? collaborations,
  bool smallPhoneLargeText = false,
  List<Override> overrides = const [],
}) async {
  final all = [
    chatRepositoryProvider.overrideWithValue(chat ?? FakeChatRepository()),
    realtimeConnectionProvider.overrideWithValue(
      realtime ?? FakeRealtimeConnection(),
    ),
    if (role != UserRole.creator) ...[
      if (discovery != null)
        discoveryRepositoryProvider.overrideWithValue(discovery),
      if (collaborations != null)
        collaborationRepositoryProvider.overrideWithValue(collaborations),
    ],
    ...overrides,
  ];
  final fakeClock = clock ?? FakeClock();
  switch (role) {
    case UserRole.store:
      await pumpStoreHome(
        tester,
        clock: fakeClock,
        smallPhoneLargeText: smallPhoneLargeText,
        overrides: all,
      );
    case UserRole.creator:
      await pumpCreatorApp(
        tester,
        discovery: discovery,
        collaborations: collaborations,
        clock: fakeClock,
        smallPhoneLargeText: smallPhoneLargeText,
        overrides: all,
      );
    case UserRole.brand:
      if (smallPhoneLargeText) {
        useSmallPhoneWithLargeText(tester);
      } else {
        usePhone(tester);
      }
      await pumpCoraApp(
        tester,
        auth: FakeAuthRepository(session: FakeAuthRepository.signedInSession),
        me: FakeMeRepository(role: UserRole.brand),
        overrides: [clockProvider.overrideWithValue(fakeClock), ...all],
      );
  }
}

/// 하단 메뉴의 `대화`를 눌러 대화 목록을 연다.
Future<void> openChatTab(WidgetTester tester) async {
  await tester.tap(find.text('대화').last);
  await tester.pumpAndSettle();
}

/// [path]를 앱 안에서 연다(알림이나 목록의 줄이 하는 것처럼 위에 쌓는다).
Future<void> pushRoute(WidgetTester tester, String path) async {
  routerOf(tester).push(path);
  await tester.pumpAndSettle();
}

Future<void> openRequest(WidgetTester tester, String id) =>
    pushRoute(tester, AppRoutes.chatRequest(id));
