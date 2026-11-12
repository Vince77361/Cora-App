import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/features/notifications/domain/app_notification.dart';
import 'package:cora/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:cora/features/payment/domain/payment_repository.dart';
import 'package:cora/features/payment/presentation/viewmodels/payment_view_model.dart';
import 'package:cora/features/payment/presentation/checkout_launcher.dart';
import 'package:cora/features/notifications/presentation/notification_routes.dart';
import 'package:cora/features/notifications/presentation/pages/notifications_page.dart';
import 'package:cora/features/store_home/presentation/viewmodels/store_home_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_clock.dart';
import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../payment/fake_payment_repository.dart';
import '../payment/payment_harness.dart';
import 'fake_notification_repository.dart';
import 'notifications_harness.dart';

FakeNotificationRepository _canvasRepo(FakeClock clock) =>
    FakeNotificationRepository(items: canvasNotifications(clock.now()));

Color? _rowColor(WidgetTester tester, String id) =>
    (tester
                .widget<DecoratedBox>(
                  find.byKey(ValueKey('notification-row-$id')),
                )
                .decoration
            as BoxDecoration)
        .color;

Color? _dotColor(WidgetTester tester, String id) =>
    (tester
                .widget<DecoratedBox>(
                  find.byKey(ValueKey('notification-dot-$id')),
                )
                .decoration
            as BoxDecoration)
        .color;

Color? _tabColor(WidgetTester tester, String label) =>
    (tester
                .widget<Container>(
                  find.byKey(ValueKey('notification-tab-$label')),
                )
                .decoration
            as BoxDecoration)
        .color;

AppNotification _note(
  String id, {
  String kind = 'MATCH',
  String? targetId,
  NotificationTab tab = NotificationTab.matching,
  bool read = false,
  String actorName = '민의 옷장 기록',
  String? photo,
  NotificationGlyph? glyph,
  DateTime? at,
}) => AppNotification(
  id: id,
  tab: tab,
  text: '$id 문구',
  actorName: actorName,
  actorPhotoUrl: photo,
  glyph: glyph,
  targetKind: kind,
  targetId: targetId,
  createdAt: at ?? DateTime.utc(2026, 11, 11, 11),
  read: read,
);

void main() {
  setUpAll(loadAppFonts);

  testWidgets('shows the five canvas rows from a fake repository', (
    tester,
  ) async {
    final clock = FakeClock();
    final semantics = tester.ensureSemantics();
    await pumpStoreNotifications(
      tester,
      repo: _canvasRepo(clock),
      clock: clock,
    );

    expect(topPath(tester), NotificationRoutes.notifications);
    expect(find.byType(NotificationsPage), findsOneWidget);
    for (final text in [
      '서윤의 작은 취향과 서로 관심이 닿았어요.',
      '모아 스튜디오가 조건 버전 2를 확인했어요.',
      '한그릇 라멘이 릴스 1편 오퍼를 보냈어요.',
      '정산 43,200원이 다음 주 수요일에 들어와요.',
      '초안 0:12 구간에 댓글이 달렸어요.',
    ]) {
      expect(find.text(text), findsOneWidget);
    }
    for (final time in ['방금', '12분 전', '1시간 전', '어제', '11월 9일']) {
      expect(find.text(time), findsOneWidget);
    }
    // 정산은 `₩`, 초안은 `✎`.
    expect(find.text('₩'), findsOneWidget);
    expect(find.text('✎'), findsOneWidget);
    // 머리, 탭, 아래 버튼.
    expect(find.text('알림'), findsOneWidget);
    for (final tab in ['전체', '매칭', '협업', '정산']) {
      expect(find.text(tab), findsOneWidget);
    }
    expect(find.text('모두 읽음으로 표시'), findsOneWidget);
    expect(find.bySemanticsLabel('알림 설정'), findsOneWidget);
    // 읽지 않은 줄은 둘, 점도 둘.
    expect(find.byKey(const ValueKey('notification-dot-n1')), findsOneWidget);
    expect(find.byKey(const ValueKey('notification-dot-n2')), findsOneWidget);
    expect(find.byKey(const ValueKey('notification-dot-n3')), findsNothing);
    semantics.dispose();
  });

  testWidgets('filters rows by tab', (tester) async {
    final clock = FakeClock();
    final repo = _canvasRepo(clock);
    await pumpStoreNotifications(tester, repo: repo, clock: clock);

    await tester.tap(find.text('협업'));
    await tester.pumpAndSettle();
    expect(repo.fetched.last.tab, NotificationTabFilter.collaboration);
    expect(find.text('모아 스튜디오가 조건 버전 2를 확인했어요.'), findsOneWidget);
    expect(find.text('초안 0:12 구간에 댓글이 달렸어요.'), findsOneWidget);
    expect(find.text('서윤의 작은 취향과 서로 관심이 닿았어요.'), findsNothing);
    expect(find.text('정산 43,200원이 다음 주 수요일에 들어와요.'), findsNothing);

    await tester.tap(find.text('정산'));
    await tester.pumpAndSettle();
    expect(find.text('정산 43,200원이 다음 주 수요일에 들어와요.'), findsOneWidget);
    expect(find.text('초안 0:12 구간에 댓글이 달렸어요.'), findsNothing);

    await tester.tap(find.text('전체'));
    await tester.pumpAndSettle();
    expect(find.byType(ListView), findsOneWidget);
    expect(find.text('서윤의 작은 취향과 서로 관심이 닿았어요.'), findsOneWidget);
  });

  testWidgets('marks a row read and opens its screen on tap', (tester) async {
    final clock = FakeClock();
    final repo = _canvasRepo(clock);
    await pumpStoreNotifications(tester, repo: repo, clock: clock);

    await tester.tap(find.text('모아 스튜디오가 조건 버전 2를 확인했어요.'));
    await tester.pumpAndSettle();

    expect(repo.readIds, ['n2']);
    // 사장님이라 사장님 협업 화면으로 간다(그 협업을 못 읽어도 화면은 열린다).
    expect(topPath(tester), '/store/collaborations/c-77');

    // 돌아오면 그 줄만 읽음이다.
    routerOf(tester).pop();
    await tester.pumpAndSettle();
    expect(topPath(tester), NotificationRoutes.notifications);
    expect(find.byKey(const ValueKey('notification-dot-n2')), findsNothing);
    expect(find.byKey(const ValueKey('notification-dot-n1')), findsOneWidget);
  });

  testWidgets('opens the creator screens for a creator', (tester) async {
    final clock = FakeClock();
    final repo = FakeNotificationRepository(
      items: [
        _note('offer', kind: 'OFFER_INBOX'),
        _note('collab', kind: 'COLLABORATION', targetId: 'c-9'),
      ],
    );
    await pumpCreatorNotifications(tester, repo: repo, clock: clock);

    await tester.tap(find.text('collab 문구'));
    await tester.pumpAndSettle();
    expect(topPath(tester), '/creator/collaborations/c-9');

    routerOf(tester).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('offer 문구'));
    await tester.pumpAndSettle();
    expect(topPath(tester), AppRoutes.creatorOffers);
    expect(repo.readIds, ['collab', 'offer']);
  });

  testWidgets('goes back to the store home tab named by the notification', (
    tester,
  ) async {
    final repo = FakeNotificationRepository(
      items: [
        _note('sent', kind: 'STORE_SENT_OFFERS'),
        _note('apply', kind: 'STORE_APPLICANTS'),
      ],
    );
    await pumpStoreNotifications(tester, repo: repo);

    await tester.tap(find.text('sent 문구'));
    await tester.pumpAndSettle();
    expect(topPath(tester), AppRoutes.store);
    expect(
      containerOf(tester).read(storeHomeViewModelProvider).value!.tab,
      StoreHomeTab.sentOffers,
    );

    await openNotifications(tester);
    await tester.tap(find.text('apply 문구'));
    await tester.pumpAndSettle();
    expect(topPath(tester), startsWith(AppRoutes.store));
    expect(
      containerOf(tester).read(storeHomeViewModelProvider).value!.tab,
      StoreHomeTab.applicants,
    );
  });

  testWidgets('refreshes the store home and the bell after paying from a '
      'notification', (tester) async {
    final home = homeWithPayableOffer();
    final repo = FakeNotificationRepository(
      items: [_note('pay', kind: 'PAYMENT', targetId: 'col-1')],
    );
    await pumpStoreNotifications(
      tester,
      repo: repo,
      home: home,
      overrides: [
        paymentRepositoryProvider.overrideWithValue(
          FakePaymentRepository(statuses: [PaymentStatus.approved]),
        ),
        paymentPollingProvider.overrideWithValue(fastPolling),
        checkoutLauncherProvider.overrideWithValue(FakeCheckoutLauncher()),
      ],
    );
    final fetchesBefore = home.fetchCalls;

    await tester.tap(find.text('pay 문구'));
    await tester.pumpAndSettle();
    expect(topPath(tester), AppRoutes.storePay('col-1'));
    await tester.tap(find.text('결제하고 보관 맡기기'));
    await tester.pumpAndSettle();

    expect(topPath(tester), AppRoutes.store);
    expect(find.text('결제했어요. 크리에이터에게 알렸어요.'), findsOneWidget);
    expect(home.fetchCalls, greaterThan(fetchesBefore));
    // 알림함에서 읽은 줄이 종 점에도 반영된다.
    expect(find.byKey(NotificationBell.dotKey), findsNothing);
  });

  testWidgets('switches to the applicants tab again after a manual tab '
      'change', (tester) async {
    final repo = FakeNotificationRepository(
      items: [_note('apply', kind: 'STORE_APPLICANTS')],
    );
    await pumpStoreNotifications(tester, repo: repo);
    StoreHomeTab tab() =>
        containerOf(tester).read(storeHomeViewModelProvider).value!.tab;

    await tester.tap(find.text('apply 문구'));
    await tester.pumpAndSettle();
    expect(tab(), StoreHomeTab.applicants);

    // 손으로 보낸 오퍼 탭으로 바꾼 뒤 같은 알림을 다시 누른다.
    containerOf(tester)
        .read(storeHomeViewModelProvider.notifier)
        .selectTab(StoreHomeTab.sentOffers);
    await tester.pump();
    await openNotifications(tester);
    await tester.tap(find.text('apply 문구'));
    await tester.pumpAndSettle();

    expect(topPath(tester), startsWith(AppRoutes.store));
    expect(tab(), StoreHomeTab.applicants);
  });

  testWidgets('only marks a row read when its kind is unknown', (tester) async {
    final clock = FakeClock();
    final repo = _canvasRepo(clock);
    await pumpStoreNotifications(tester, repo: repo, clock: clock);

    await tester.tap(find.text('서윤의 작은 취향과 서로 관심이 닿았어요.'));
    await tester.pumpAndSettle();

    expect(repo.readIds, ['n1']);
    expect(topPath(tester), NotificationRoutes.notifications);
    expect(find.byKey(const ValueKey('notification-dot-n1')), findsNothing);
  });

  testWidgets('stays put when the wallet screen does not exist yet', (
    tester,
  ) async {
    final repo = FakeNotificationRepository(
      items: [_note('pay', kind: 'WALLET', tab: NotificationTab.settlement)],
    );
    await pumpCreatorNotifications(tester, repo: repo);

    await tester.tap(find.text('pay 문구'));
    await tester.pumpAndSettle();

    // 13D가 `/creator/wallet`을 만들기 전에는 라우터에 없어 열지 않고 읽음만 바꾼다.
    expect(repo.readIds, ['pay']);
    expect(
      topPath(tester),
      routeExists(tester, NotificationRoutes.wallet)
          ? NotificationRoutes.wallet
          : NotificationRoutes.notifications,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the row unread when the server refuses the read', (
    tester,
  ) async {
    final repo = FakeNotificationRepository(items: [_note('a')])
      ..failRead = true;
    await pumpStoreNotifications(tester, repo: repo);

    await tester.tap(find.text('a 문구'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('notification-dot-a')), findsOneWidget);
  });

  testWidgets('marks everything read from the bottom button', (tester) async {
    final clock = FakeClock();
    final repo = _canvasRepo(clock);
    await pumpStoreNotifications(tester, repo: repo, clock: clock);

    await tester.tap(find.text('협업'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('모두 읽음으로 표시'));
    await tester.pumpAndSettle();

    // 고른 탭과 상관없이 모두 읽음이 된다.
    expect(repo.readAllCalls, 1);
    expect(repo.items.every((n) => n.read), isTrue);
    expect(find.byKey(const ValueKey('notification-dot-n2')), findsNothing);
    await tester.tap(find.text('전체'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('notification-dot-n1')), findsNothing);
    expect(find.byKey(const ValueKey('notification-dot-n2')), findsNothing);
  });

  testWidgets('says so when marking everything read fails', (tester) async {
    final repo = FakeNotificationRepository(items: [_note('a')])
      ..failReadAll = true;
    await pumpStoreNotifications(tester, repo: repo);

    await tester.tap(find.text('모두 읽음으로 표시'));
    await tester.pump();
    await tester.pump();

    expect(find.text('읽음으로 바꾸지 못했어요.'), findsOneWidget);
    expect(find.byKey(const ValueKey('notification-dot-a')), findsOneWidget);
    await tester.pump(NotificationsPage.noticeFor);
    await tester.pumpAndSettle();
    expect(find.text('읽음으로 바꾸지 못했어요.'), findsNothing);
  });

  testWidgets('draws unread rows with surface and a dot, light and dark', (
    tester,
  ) async {
    final clock = FakeClock();
    await pumpStoreNotifications(
      tester,
      repo: _canvasRepo(clock),
      clock: clock,
    );

    expect(_rowColor(tester, 'n1'), CoraColors.light.surface);
    expect(_rowColor(tester, 'n3'), Colors.transparent);
    expect(_dotColor(tester, 'n1'), const Color(0xFF17181C));
    // 읽음 표시된 줄의 `₩` 원도 `surface`다.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('notification-row-n4')),
        matching: find.byWidgetPredicate(
          (w) => w is ColoredBox && w.color == CoraColors.light.surface,
        ),
      ),
      findsOneWidget,
    );

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpAndSettle();

    expect(_rowColor(tester, 'n1'), const Color(0xFF1C1E22));
    expect(_rowColor(tester, 'n3'), Colors.transparent);
    // 다크는 점이 #0F1012(캔버스 그대로)다.
    expect(_dotColor(tester, 'n1'), const Color(0xFF0F1012));
    // 아래 버튼.
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).color == const Color(0xFF2A2D33),
      ),
      findsOneWidget,
    );
  });

  testWidgets('uses #33363D for the selected tab in dark', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await pumpStoreNotifications(tester, repo: FakeNotificationRepository());

    expect(_tabColor(tester, '전체'), const Color(0xFF33363D));
    expect(_tabColor(tester, '매칭'), const Color(0xFF1C1E22));

    await tester.tap(find.text('정산'));
    await tester.pumpAndSettle();
    expect(_tabColor(tester, '정산'), const Color(0xFF33363D));
    expect(_tabColor(tester, '전체'), const Color(0xFF1C1E22));
  });

  testWidgets('uses #E3E5E9 for the selected tab in light', (tester) async {
    await pumpStoreNotifications(tester, repo: FakeNotificationRepository());

    expect(_tabColor(tester, '전체'), const Color(0xFFE3E5E9));
    expect(_tabColor(tester, '협업'), const Color(0xFFF8F9FA));
  });

  testWidgets('draws a photo, a glyph or the first letter of the name', (
    tester,
  ) async {
    final repo = FakeNotificationRepository(
      items: [
        _note('letter', actorName: '민의 옷장 기록'),
        _note('won', glyph: NotificationGlyph.won, photo: 'https://x.test/a'),
        _note('pen', glyph: NotificationGlyph.pen),
        _note('photo', photo: 'https://x.test/p.jpg'),
      ],
    );
    await pumpStoreNotifications(tester, repo: repo);

    expect(find.text('민'), findsOneWidget);
    // 글자 그림이 있으면 사진이 있어도 글자가 먼저다.
    expect(find.text('₩'), findsOneWidget);
    expect(find.text('✎'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('notification-row-photo')),
        matching: find.byType(Image),
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows the empty state', (tester) async {
    await pumpStoreNotifications(tester, repo: FakeNotificationRepository());

    expect(find.text('아직 알림이 없어요.'), findsOneWidget);
    expect(find.text('모두 읽음으로 표시'), findsOneWidget);
  });

  testWidgets('shows a failure with a retry', (tester) async {
    final repo = FakeNotificationRepository(items: [_note('a')])
      ..failFetch = true;
    await pumpStoreNotifications(tester, repo: repo);

    expect(find.text('알림을 불러오지 못했어요.'), findsOneWidget);
    // 탭은 그대로 보인다.
    expect(find.text('매칭'), findsOneWidget);

    repo.failFetch = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('a 문구'), findsOneWidget);
  });

  testWidgets('loads the next page when scrolled to the end', (tester) async {
    final repo = FakeNotificationRepository(
      items: [
        for (var i = 0; i < 45; i++)
          _note('p${i.toString().padLeft(2, '0')}', read: true),
      ],
      pageSize: 30,
    );
    await pumpStoreNotifications(tester, repo: repo);
    expect(repo.fetched.length, 1);
    expect(find.text('p44 문구'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('p44 문구'),
      400,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    expect(find.text('p44 문구'), findsOneWidget);
    expect(repo.fetched.map((f) => f.cursor), [null, '30']);
  });

  testWidgets('goes back to the screen it came from', (tester) async {
    await pumpStoreNotifications(tester, repo: FakeNotificationRepository());

    await tester.tap(find.bySemanticsLabel('뒤로'));
    await tester.pumpAndSettle();

    expect(topPath(tester), AppRoutes.store);
  });

  testWidgets('opens notification settings only when that screen exists', (
    tester,
  ) async {
    await pumpStoreNotifications(tester, repo: FakeNotificationRepository());

    await tester.tap(find.bySemanticsLabel('알림 설정'));
    await tester.pumpAndSettle();

    // 13D가 `/settings/notifications`를 만들기 전에는 아무 일도 일어나지 않는다.
    expect(
      topPath(tester),
      routeExists(tester, NotificationRoutes.settings)
          ? NotificationRoutes.settings
          : NotificationRoutes.notifications,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not overflow at 1.3x text scale', (tester) async {
    final clock = FakeClock();
    await pumpStoreNotifications(
      tester,
      repo: _canvasRepo(clock),
      clock: clock,
      smallPhoneLargeText: true,
    );
    expect(tester.takeException(), isNull);

    for (final tab in ['매칭', '협업', '정산']) {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
