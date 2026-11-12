import 'package:cora/features/notification_settings/domain/notification_settings_repository.dart';
import 'package:cora/features/notifications/presentation/notification_routes.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_clock.dart';
import '../../support/pump_cora_app.dart';
import '../store_browse/creator_app_harness.dart' show pumpCreatorApp;
import 'fake_notification_settings_repository.dart';

/// 로그인한 크리에이터로 앱을 띄우고 알림 설정(E5)을 연다.
Future<void> pumpNotificationSettings(
  WidgetTester tester, {
  required FakeNotificationSettingsRepository repo,
  FakeClock? clock,
  bool smallPhoneLargeText = false,
  List<Override> overrides = const [],
}) async {
  await pumpCreatorApp(
    tester,
    clock: clock,
    smallPhoneLargeText: smallPhoneLargeText,
    overrides: [
      notificationSettingsRepositoryProvider.overrideWithValue(repo),
      ...overrides,
    ],
  );
  routerOf(tester).push(NotificationRoutes.settings);
  await tester.pumpAndSettle();
}
