import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/features/notifications/domain/app_notification.dart';
import 'package:cora/features/notifications/presentation/notification_routes.dart';
import 'package:cora/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_clock.dart';
import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import 'fake_notification_repository.dart';
import 'notifications_harness.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('shows the bell dot only when something is unread', (
    tester,
  ) async {
    final clock = FakeClock();
    final semantics = tester.ensureSemantics();
    final repo = FakeNotificationRepository(
      items: canvasNotifications(clock.now()),
    );
    await pumpStoreNotifications(tester, repo: repo, clock: clock, open: false);

    // 읽지 않은 것이 둘이다.
    expect(find.byKey(NotificationBell.dotKey), findsOneWidget);
    expect(find.bySemanticsLabel('알림, 새 알림 2개'), findsOneWidget);

    // 알림함에서 모두 읽으면 돌아왔을 때 점이 사라진다.
    await tester.tap(find.bySemanticsLabel('알림, 새 알림 2개'));
    await tester.pumpAndSettle();
    expect(topPath(tester), NotificationRoutes.notifications);
    await tester.tap(find.text('모두 읽음으로 표시'));
    await tester.pumpAndSettle();
    routerOf(tester).pop();
    await tester.pumpAndSettle();

    expect(find.byKey(NotificationBell.dotKey), findsNothing);
    expect(find.bySemanticsLabel('알림'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('has no dot when there are no notifications', (tester) async {
    await pumpStoreNotifications(
      tester,
      repo: FakeNotificationRepository(),
      open: false,
    );

    expect(find.byKey(NotificationBell.dotKey), findsNothing);
  });

  testWidgets('draws the dot with the accent and a background ring', (
    tester,
  ) async {
    final clock = FakeClock();
    await pumpStoreNotifications(
      tester,
      repo: FakeNotificationRepository(items: canvasNotifications(clock.now())),
      clock: clock,
      open: false,
    );

    final dot = tester.widget<Container>(find.byKey(NotificationBell.dotKey));
    final decoration = dot.decoration! as BoxDecoration;
    expect(decoration.color, const Color(0xFFC6FF3D));
    expect((decoration.border! as Border).top.width, 2);
    expect((decoration.border! as Border).top.color, const Color(0xFFFFFFFF));
    // 점 8에 고리 2씩이라 상자는 12다.
    expect(
      tester.getSize(find.byKey(NotificationBell.dotKey)),
      const Size(12, 12),
    );
    // 버튼은 44.
    expect(tester.getSize(find.byType(NotificationBell)), const Size(44, 44));
  });

  testWidgets('sits to the left of the store page button', (tester) async {
    await pumpStoreNotifications(
      tester,
      repo: FakeNotificationRepository(),
      open: false,
    );

    final bell = tester.getRect(find.byType(NotificationBell));
    final storePage = tester.getRect(find.text('가게 페이지'));
    expect(bell.size, const Size(44, 44));
    expect(bell.right, lessThanOrEqualTo(storePage.left));
  });

  testWidgets('does not overflow in the home header at 1.3x text scale', (
    tester,
  ) async {
    final clock = FakeClock();
    await pumpStoreNotifications(
      tester,
      repo: FakeNotificationRepository(items: canvasNotifications(clock.now())),
      clock: clock,
      smallPhoneLargeText: true,
      open: false,
    );

    expect(find.byKey(NotificationBell.dotKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ignores the return after the bell is gone', (tester) async {
    final repo = FakeNotificationRepository(
      items: [
        AppNotification(
          id: 'a',
          tab: NotificationTab.matching,
          text: 'a 문구',
          actorName: '누구',
          targetKind: 'MATCH',
          createdAt: DateTime.utc(2026, 11, 11, 11),
          read: false,
        ),
      ],
    );
    await pumpStoreNotifications(tester, repo: repo, open: false);
    await tester.tap(find.byType(NotificationBell));
    await tester.pumpAndSettle();
    expect(topPath(tester), NotificationRoutes.notifications);

    // 알림함이 열린 채 홈이 통째로 바뀌면 종은 사라지고, 늦게 오는 돌아옴은 무시해야 한다.
    routerOf(tester).go(AppRoutes.storeDrafts);
    await tester.pumpAndSettle();

    expect(find.byType(NotificationBell), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
