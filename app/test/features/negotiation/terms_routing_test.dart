import 'package:cora/features/collaboration/domain/collaboration.dart';
import 'package:cora/features/notifications/domain/app_notification.dart';
import 'package:cora/features/notifications/domain/notification_repository.dart';
import 'package:cora/features/notifications/presentation/notification_routes.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../collaboration/fake_collaboration_repository.dart';
import '../notifications/fake_notification_repository.dart';
import '../store_browse/creator_app_harness.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('a terms notification opens the terms screen of that '
      'collaboration', (tester) async {
    final note = AppNotification(
      id: 'terms',
      tab: NotificationTab.collaboration,
      text: '새 조건 판본이 도착했어요.',
      actorName: '모아 스튜디오',
      targetKind: 'TERMS',
      targetId: 'collab-t1',
      createdAt: DateTime.utc(2026, 11, 11, 11),
      read: false,
    );
    await pumpCreatorApp(
      tester,
      collaborations: FakeCollaborationRepository(
        active: [
          collaboration(
            id: 'collab-t1',
            kind: CollaborationKind.brandContract,
            storeName: '모아 스튜디오',
          ),
        ],
      ),
      overrides: [
        notificationRepositoryProvider.overrideWithValue(
          FakeNotificationRepository(items: [note]),
        ),
      ],
    );
    routerOf(tester).push(NotificationRoutes.notifications);
    await tester.pumpAndSettle();

    await tester.tap(find.text('새 조건 판본이 도착했어요.'));
    await tester.pumpAndSettle();

    expect(topPath(tester), '/collaborations/collab-t1/terms');
    expect(find.text('받은 제안 · 판본 1'), findsOneWidget);
    expect(find.text('모아 스튜디오'), findsOneWidget);
  });
}
