import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/features/collaboration/domain/collaboration.dart';
import 'package:cora/features/collaboration/domain/collaboration_repository.dart';
import 'package:cora/features/notifications/domain/app_notification.dart';
import 'package:cora/features/notifications/domain/notification_repository.dart';
import 'package:cora/features/notifications/presentation/notification_routes.dart';
import 'package:cora/features/onboarding/domain/user_role.dart';
import 'package:cora/features/view_report/domain/view_report.dart';
import 'package:cora/features/view_report/domain/view_report_repository.dart';
import 'package:cora/features/view_report/presentation/pages/view_report_page.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../auth/fake_auth_repository.dart';
import '../collaboration/fake_collaboration_repository.dart';
import '../notifications/fake_notification_repository.dart';
import '../onboarding/fake_me_repository.dart';
import '../store_browse/creator_app_harness.dart';
import '../view_report/fake_view_report_repository.dart';
import 'brand_collaboration_harness.dart';

/// 브랜드 계약의 F4(NMetrics 데이터): 제작비 300,000원 + 조회수 수당(1,000회당 2,000원, 상한 60,000원), 측정
/// 14일. 한국 시간으로 11월 4일 정오부터 14일이다.
ViewReport _brandReport({
  bool canConfirm = true,
  ViewReportStatus status = ViewReportStatus.unconfirmed,
}) => ViewReport(
  status: status,
  views: 12500,
  postUrl: 'https://www.instagram.com/reel/abc/',
  periodStart: DateTime.utc(2026, 11, 4, 3),
  periodEnd: DateTime.utc(2026, 11, 18, 3),
  source: ViewReportSource.connectedAccount,
  calc: const ViewReportCalc(
    ratePerThousand: 2000,
    cap: 60000,
    capApplied: false,
    fixedCash: 300000,
    viewPay: 25000,
    refund: 35000,
    payout: 325000,
  ),
  confirmDueAt: DateTime.utc(2026, 11, 20, 3),
  canConfirm: canConfirm,
  canDispute: true,
);

Future<void> _pumpBrand(
  WidgetTester tester, {
  required FakeViewReportRepository reports,
  FakeNotificationRepository? notifications,
}) async {
  usePhone(tester);
  await pumpCoraApp(
    tester,
    auth: FakeAuthRepository(session: FakeAuthRepository.signedInSession),
    me: FakeMeRepository(role: UserRole.brand),
    overrides: [
      viewReportRepositoryProvider.overrideWithValue(reports),
      collaborationRepositoryProvider.overrideWithValue(
        FakeCollaborationRepository(active: [brandCollab()]),
      ),
      if (notifications != null)
        notificationRepositoryProvider.overrideWithValue(notifications),
    ],
  );
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('shows the brand wording for the refund and the fixed fee rows', (
    tester,
  ) async {
    await _pumpBrand(
      tester,
      reports: FakeViewReportRepository(report: _brandReport()),
    );
    routerOf(tester).push(AppRoutes.brandViewReport(brandCollabId));
    await tester.pumpAndSettle();

    expect(find.byType(ViewReportPage), findsOneWidget);
    expect(find.text('브랜드에 환불'), findsOneWidget);
    expect(find.text('제작비'), findsOneWidget);
    expect(find.text('300,000원'), findsOneWidget);
    expect(find.text('사장님께 환불'), findsNothing);
    expect(find.text('고정 현금'), findsNothing);
    // 측정 기간은 14일까지 이어진다.
    expect(find.text('11월 4일 – 11월 17일 (14일)'), findsOneWidget);
    expect(find.text('크리에이터 지급 예정'), findsOneWidget);
    expect(find.text('325,000원'), findsOneWidget);
  });

  testWidgets('shows the seven day period for a seven day brand contract', (
    tester,
  ) async {
    final seven = ViewReport(
      status: ViewReportStatus.unconfirmed,
      views: 12500,
      postUrl: 'https://www.instagram.com/reel/abc/',
      periodStart: DateTime.utc(2026, 11, 4, 3),
      periodEnd: DateTime.utc(2026, 11, 11, 3),
      source: ViewReportSource.connectedAccount,
      calc: _brandReport().calc,
      canConfirm: true,
      canDispute: true,
    );
    await _pumpBrand(tester, reports: FakeViewReportRepository(report: seven));
    routerOf(tester).push(AppRoutes.brandViewReport(brandCollabId));
    await tester.pumpAndSettle();

    expect(find.text('11월 4일 – 11월 10일 (7일)'), findsOneWidget);
  });

  testWidgets('only the brand sees the confirm button', (tester) async {
    // 브랜드: 확인과 이의 제기.
    final brandReports = FakeViewReportRepository(report: _brandReport());
    await _pumpBrand(tester, reports: brandReports);
    routerOf(tester).push(AppRoutes.brandViewReport(brandCollabId));
    await tester.pumpAndSettle();
    expect(find.text('자료 확인했어요'), findsOneWidget);
    expect(find.text('이의 제기'), findsOneWidget);

    await tester.tap(find.text('자료 확인했어요'));
    await tester.pumpAndSettle();
    expect(brandReports.confirmed, [brandCollabId]);
    expect(find.text('확인 완료'), findsOneWidget);
  });

  testWidgets(
    'the creator of a brand contract sees the brand wording and can only dispute',
    (tester) async {
      // 서버는 크리에이터에게 canConfirm을 주지 않지만, 참으로 와도 버튼을 두지 않는다.
      await pumpCreatorApp(
        tester,
        collaborations: FakeCollaborationRepository(
          active: [brandCollab(role: CollaborationRole.creator)],
        ),
        overrides: [
          viewReportRepositoryProvider.overrideWithValue(
            FakeViewReportRepository(report: _brandReport()),
          ),
        ],
      );
      routerOf(tester).push(AppRoutes.creatorViewReport(brandCollabId));
      await tester.pumpAndSettle();

      expect(find.byType(ViewReportPage), findsOneWidget);
      expect(find.text('브랜드에 환불'), findsOneWidget);
      expect(find.text('제작비'), findsOneWidget);
      expect(find.text('자료 확인했어요'), findsNothing);
      expect(find.text('이의 제기'), findsOneWidget);
    },
  );

  testWidgets('the settlement notification opens the metrics screen of that '
      'collaboration', (tester) async {
    final notifications = FakeNotificationRepository(
      items: [
        AppNotification(
          id: 'n1',
          tab: NotificationTab.collaboration,
          text: '조회수 집계가 끝났어요.',
          actorName: '서윤의 작은 취향',
          targetKind: 'VIEW_REPORT',
          targetId: brandCollabId,
          createdAt: DateTime.utc(2026, 11, 18, 3),
          read: false,
        ),
      ],
    );
    await _pumpBrand(
      tester,
      reports: FakeViewReportRepository(report: _brandReport()),
      notifications: notifications,
    );
    routerOf(tester).push(NotificationRoutes.notifications);
    await tester.pumpAndSettle();

    await tester.tap(find.text('조회수 집계가 끝났어요.'));
    await tester.pumpAndSettle();

    expect(find.byType(ViewReportPage), findsOneWidget);
    expect(
      routerOf(
        tester,
      ).routerDelegate.currentConfiguration.last.matchedLocation,
      AppRoutes.brandViewReport(brandCollabId),
    );
    expect(find.text('브랜드에 환불'), findsOneWidget);
  });
}
