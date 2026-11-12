import 'package:cora/features/notifications/domain/notification_repository.dart';
import 'package:cora/features/notifications/presentation/notification_routes.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_clock.dart';
import '../../support/pump_cora_app.dart';
import '../store_browse/creator_app_harness.dart' show pumpCreatorApp;
import '../store_home/fake_store_home_repository.dart';
import '../store_home/store_home_harness.dart' show pumpStoreHome;
import 'fake_notification_repository.dart';

export '../store_home/store_home_harness.dart' show topPath;

/// 로그인한 사장님으로 앱을 띄운다. 첫 화면은 사장님 홈이고 종이 머리에 있다. [open]이면 알림함까지 연다.
Future<void> pumpStoreNotifications(
  WidgetTester tester, {
  required FakeNotificationRepository repo,
  FakeClock? clock,
  FakeStoreHomeRepository? home,
  bool smallPhoneLargeText = false,
  bool open = true,
  List<Override> overrides = const [],
}) async {
  await pumpStoreHome(
    tester,
    home: home,
    clock: clock,
    smallPhoneLargeText: smallPhoneLargeText,
    overrides: [notificationRepositoryProvider.overrideWithValue(repo)],
  );
  if (!open) return;
  routerOf(tester).push(NotificationRoutes.notifications);
  await tester.pumpAndSettle();
}

/// 로그인한 크리에이터로 앱을 띄우고 알림함을 연다.
Future<void> pumpCreatorNotifications(
  WidgetTester tester, {
  required FakeNotificationRepository repo,
  FakeClock? clock,
  bool smallPhoneLargeText = false,
}) async {
  await pumpCreatorApp(
    tester,
    clock: clock,
    smallPhoneLargeText: smallPhoneLargeText,
    overrides: [notificationRepositoryProvider.overrideWithValue(repo)],
  );
  routerOf(tester).push(NotificationRoutes.notifications);
  await tester.pumpAndSettle();
}

/// 라우터가 이 경로를 아는지(아직 없는 13D 화면이면 false).
bool routeExists(WidgetTester tester, String path) =>
    !routerOf(tester).configuration.findMatch(Uri.parse(path)).isError;
