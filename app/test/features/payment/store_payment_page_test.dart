import 'dart:async';

import 'package:cora/core/config/app_config.dart';
import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/features/notifications/domain/app_notification.dart';
import 'package:cora/features/payment/domain/payment_repository.dart';
import 'package:cora/features/payment/presentation/checkout_launcher.dart';
import 'package:cora/features/payment/presentation/viewmodels/payment_view_model.dart';
import 'package:cora/features/payment/presentation/pages/store_payment_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../notifications/fake_notification_repository.dart';
import '../notifications/notifications_harness.dart'
    show pumpStoreNotifications;
import '../store_home/store_home_harness.dart';
import 'fake_payment_repository.dart';
import 'payment_harness.dart';

const _submit = '결제하고 보관 맡기기';
const _incomplete = '결제가 완료되지 않았어요. 다시 시도해 주세요.';
const _approvedNotice = '결제했어요. 크리에이터에게 알렸어요.';

List<String> _paths(List<RouteBase> routes) => [
  for (final route in routes)
    if (route is GoRoute) route.path,
  for (final route in routes) ..._paths(route.routes),
];

void main() {
  setUpAll(loadAppFonts);

  testWidgets('shows the quote with fee and total', (tester) async {
    await pumpPayment(tester);

    expect(topPath(tester), AppRoutes.storePay('col-1'));
    expect(find.byType(StorePaymentPage), findsOneWidget);
    expect(find.text('결제'), findsOneWidget);
    expect(find.text('하루 한 컵이\n오퍼를 수락했어요'), findsOneWidget);
    expect(find.text('콘텐츠'), findsOneWidget);
    expect(find.text('릴스 1편'), findsOneWidget);
    expect(find.text('식사권 40,000원 · 2인'), findsOneWidget);
    expect(find.text('방문 때 가게에서 제공'), findsOneWidget);
    expect(find.text('고정 현금'), findsNothing);
    expect(find.text('조회수 수당 (최대)'), findsOneWidget);
    expect(find.text('60,000원'), findsOneWidget);
    expect(find.text('서비스 수수료'), findsOneWidget);
    expect(find.text('6,000원'), findsOneWidget);
    expect(find.text('지금 결제할 금액'), findsOneWidget);
    expect(find.text('66,000원'), findsOneWidget);
    expect(
      find.text('최대 60,000원, 실제는 조회수만큼, 남으면 7일 집계 후 환불해요.'),
      findsOneWidget,
    );
    // 옛 문구는 없다.
    expect(find.text('조회수당 (최대)'), findsNothing);
    expect(find.textContaining('조회수가 적어 다 쓰지 않은'), findsNothing);
    for (final label in ['카드', '계좌이체', '간편결제']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(
      find.text('결제 금액은 Cora가 보관하다가, 콘텐츠가 올라오고 조회수가 집계되면 크리에이터에게 지급해요.'),
      findsOneWidget,
    );
    expect(find.text(_submit), findsOneWidget);
  });

  testWidgets('uses the right particle for a name ending in a vowel', (
    tester,
  ) async {
    final payments = FakePaymentRepository(
      quote: sampleQuote(creatorName: '모아 스튜디오'),
    );
    await pumpPayment(tester, payments: payments);

    expect(find.text('모아 스튜디오가\n오퍼를 수락했어요'), findsOneWidget);
  });

  testWidgets('hides the voucher row for a per-view only offer', (
    tester,
  ) async {
    await pumpPayment(
      tester,
      payments: FakePaymentRepository(quote: sampleQuote(voucher: null)),
    );

    expect(find.text('방문 때 가게에서 제공'), findsNothing);
    expect(find.textContaining('식사권'), findsNothing);
    expect(find.text('릴스 1편'), findsOneWidget);
    expect(find.text('66,000원'), findsOneWidget);
  });

  testWidgets('A8 adds a fixed cash row and the combined notice', (
    tester,
  ) async {
    await pumpPayment(
      tester,
      payments: FakePaymentRepository(quote: sampleQuote(fixedCash: 30000)),
    );

    expect(find.text('고정 현금'), findsOneWidget);
    expect(find.text('30,000원'), findsOneWidget);
    expect(find.text('조회수 수당 (최대)'), findsOneWidget);
    expect(find.text('60,000원'), findsOneWidget);
    // 최대 현금 부담 90,000원 + 수수료 9,000원.
    expect(find.text('9,000원'), findsOneWidget);
    expect(find.text('99,000원'), findsOneWidget);
    expect(
      find.text('최대 90,000원, 조회수 수당은 조회수만큼, 남으면 7일 집계 후 환불해요.'),
      findsOneWidget,
    );
  });

  testWidgets('A8 drops the notice when there is no view pay', (tester) async {
    await pumpPayment(
      tester,
      payments: FakePaymentRepository(
        quote: sampleQuote(fixedCash: 30000, viewPayCap: null),
      ),
    );

    expect(find.text('고정 현금'), findsOneWidget);
    expect(find.text('조회수 수당 (최대)'), findsNothing);
    expect(find.textContaining('환불해요'), findsNothing);
    expect(find.text('3,000원'), findsOneWidget);
    expect(find.text('33,000원'), findsOneWidget);
  });

  testWidgets('pays with the chosen method', (tester) async {
    final payments = FakePaymentRepository();
    final launcher = FakeCheckoutLauncher();
    await pumpPayment(tester, payments: payments, launcher: launcher);

    await tester.tap(find.text('계좌이체'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_submit));
    await tester.pump();

    expect(payments.created, [
      (collaborationId: 'col-1', method: PaymentMethod.transfer),
    ]);
    expect(launcher.opened.single.url, 'cora-dev://fake-pay?paymentId=pay-1');
    expect(launcher.opened.single.amount, 66000);
    await tester.pumpAndSettle();
  });

  testWidgets('starts with the card selected', (tester) async {
    final payments = FakePaymentRepository();
    await pumpPayment(
      tester,
      payments: payments,
      launcher: FakeCheckoutLauncher(),
    );

    await tester.tap(find.text(_submit));
    await tester.pumpAndSettle();

    expect(payments.created.single.method, PaymentMethod.card);
  });

  testWidgets('returns home with a confirmation when the payment is approved', (
    tester,
  ) async {
    final payments = FakePaymentRepository(statuses: [PaymentStatus.approved]);
    final home = homeWithPayableOffer();
    await pumpPayment(
      tester,
      payments: payments,
      home: home,
      launcher: FakeCheckoutLauncher(),
    );
    final fetchesBefore = home.fetchCalls;

    await tester.tap(find.text(_submit));
    await tester.pumpAndSettle();

    expect(find.byType(StorePaymentPage), findsNothing);
    expect(currentPath(tester), AppRoutes.store);
    expect(find.text(_approvedNotice), findsOneWidget);
    // 홈이 서버에서 다시 읽는다(진행 중 숫자와 오퍼 줄이 바뀐다).
    expect(home.fetchCalls, greaterThan(fetchesBefore));
  });

  testWidgets('goes to the store home with the confirmation when approved from '
      'the notification list', (tester) async {
    final home = homeWithPayableOffer();
    await pumpStoreNotifications(
      tester,
      repo: FakeNotificationRepository(
        items: [
          AppNotification(
            id: 'pay',
            tab: NotificationTab.settlement,
            text: '결제해 주세요',
            actorName: '하루 한 컵',
            targetKind: 'PAYMENT',
            targetId: 'col-1',
            createdAt: DateTime.utc(2026, 11, 11, 11),
            read: false,
          ),
        ],
      ),
      home: home,
      overrides: [
        paymentRepositoryProvider.overrideWithValue(
          FakePaymentRepository(statuses: [PaymentStatus.approved]),
        ),
        paymentPollingProvider.overrideWithValue(fastPolling),
        checkoutLauncherProvider.overrideWithValue(FakeCheckoutLauncher()),
      ],
    );
    await tester.tap(find.text('결제해 주세요'));
    await tester.pumpAndSettle();
    expect(find.byType(StorePaymentPage), findsOneWidget);
    final fetchesBefore = home.fetchCalls;

    await tester.tap(find.text(_submit));
    await tester.pumpAndSettle();

    expect(find.byType(StorePaymentPage), findsNothing);
    expect(currentPath(tester), AppRoutes.store);
    expect(find.text(_approvedNotice), findsOneWidget);
    expect(home.fetchCalls, greaterThan(fetchesBefore));
  });

  testWidgets('stays and shows a retry message when the payment fails', (
    tester,
  ) async {
    final payments = FakePaymentRepository(statuses: [PaymentStatus.failed]);
    await pumpPayment(
      tester,
      payments: payments,
      launcher: FakeCheckoutLauncher(),
    );

    await tester.tap(find.text(_submit));
    await tester.pumpAndSettle();

    expect(find.byType(StorePaymentPage), findsOneWidget);
    expect(find.text(_incomplete), findsOneWidget);
    expect(find.text(_approvedNotice), findsNothing);
    // 한 번 끝났으면 더 묻지 않는다.
    expect(payments.statusCalls, 1);
    // 같은 화면에서 다시 시도할 수 있다.
    expect(find.text(_submit), findsOneWidget);
  });

  testWidgets('shows a retry message when the status stays pending', (
    tester,
  ) async {
    final payments = FakePaymentRepository(statuses: [PaymentStatus.pending]);
    await pumpPayment(
      tester,
      payments: payments,
      launcher: FakeCheckoutLauncher(),
    );

    await tester.tap(find.text(_submit));
    await tester.pumpAndSettle();

    // 주입한 횟수(3번)를 다 쓰면 멈춘다.
    expect(payments.statusCalls, fastPolling.attempts);
    expect(find.byType(StorePaymentPage), findsOneWidget);
    expect(find.text(_incomplete), findsOneWidget);
  });

  testWidgets('keeps polling after the checkout is closed without a result', (
    tester,
  ) async {
    final payments = FakePaymentRepository(
      statuses: [
        PaymentStatus.pending,
        PaymentStatus.pending,
        PaymentStatus.approved,
      ],
    );
    await pumpPayment(
      tester,
      payments: payments,
      launcher: FakeCheckoutLauncher(),
    );

    await tester.tap(find.text(_submit));
    await tester.pumpAndSettle();

    expect(payments.statusCalls, 3);
    expect(currentPath(tester), AppRoutes.store);
    expect(find.text(_approvedNotice), findsOneWidget);
    expect(find.text(_incomplete), findsNothing);
  });

  testWidgets('says it is checking while it waits for the status', (
    tester,
  ) async {
    final payments = FakePaymentRepository(statuses: [PaymentStatus.approved])
      ..holdStatus = Completer<void>();
    await pumpPayment(
      tester,
      payments: payments,
      launcher: FakeCheckoutLauncher(),
    );

    await tester.tap(find.text(_submit));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('결제를 확인하고 있어요'), findsOneWidget);
    expect(find.text(_submit), findsNothing);

    payments.holdStatus!.complete();
    await tester.pumpAndSettle();
    expect(currentPath(tester), AppRoutes.store);
  });

  testWidgets('does not start a second payment while one is in progress', (
    tester,
  ) async {
    final payments = FakePaymentRepository(statuses: [PaymentStatus.approved])
      ..holdStatus = Completer<void>();
    final launcher = FakeCheckoutLauncher();
    await pumpPayment(tester, payments: payments, launcher: launcher);

    await tester.tap(find.text(_submit));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('결제를 확인하고 있어요'), warnIfMissed: false);
    await tester.pump();

    expect(payments.created.length, 1);
    payments.holdStatus!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('shows an error without freezing when the offer cannot be paid', (
    tester,
  ) async {
    final payments = FakePaymentRepository()..conflictOnCreate = true;
    final launcher = FakeCheckoutLauncher();
    await pumpPayment(tester, payments: payments, launcher: launcher);

    await tester.tap(find.text(_submit));
    await tester.pumpAndSettle();

    expect(find.text(StorePaymentPage.unavailable), findsOneWidget);
    expect(launcher.opened, isEmpty);
    expect(find.text(_submit), findsOneWidget);

    // 사장님이 다른 수단으로 다시 눌러도 화면이 살아 있다.
    payments.conflictOnCreate = false;
    payments.failCreate = true;
    await tester.tap(find.text(_submit));
    await tester.pumpAndSettle();
    expect(find.text(StorePaymentPage.createFailed), findsOneWidget);
    expect(find.text(StorePaymentPage.unavailable), findsNothing);
  });

  testWidgets('shows an error with retry when the quote cannot be loaded', (
    tester,
  ) async {
    final payments = FakePaymentRepository()..failQuote = true;
    await pumpPayment(tester, payments: payments);

    expect(find.text(StorePaymentPage.loadFailed), findsOneWidget);
    payments.failQuote = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('66,000원'), findsOneWidget);
  });

  testWidgets('says so when the quote is for an offer that cannot be paid', (
    tester,
  ) async {
    final payments = FakePaymentRepository()..conflictOnQuote = true;
    await pumpPayment(tester, payments: payments);

    expect(find.text(StorePaymentPage.unavailable), findsOneWidget);
  });

  testWidgets('the back button returns to the home', (tester) async {
    await pumpPayment(tester, launcher: FakeCheckoutLauncher());

    await tester.tap(find.bySemanticsLabel('뒤로'));
    await tester.pumpAndSettle();

    expect(find.byType(StorePaymentPage), findsNothing);
    expect(currentPath(tester), AppRoutes.store);
  });

  testWidgets('prod build has no fake checkout route', (tester) async {
    await pumpPayment(tester, env: CoraEnv.prod, open: false);

    expect(
      _paths(routerOf(tester).configuration.routes),
      isNot(contains(AppRoutes.devFakeCheckout)),
    );
    // 가게 결제 화면은 운영에도 있다.
    expect(
      _paths(routerOf(tester).configuration.routes),
      contains(AppRoutes.storePayPattern),
    );
  });

  testWidgets('dev build registers the fake checkout route', (tester) async {
    await pumpPayment(tester, open: false);

    expect(
      _paths(routerOf(tester).configuration.routes),
      contains(AppRoutes.devFakeCheckout),
    );
  });

  testWidgets('uses the dark tokens in dark mode', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await pumpPayment(tester);

    Finder box(Color color) => find.byWidgetPredicate(
      (w) =>
          w is DecoratedBox &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).color == color,
    );
    // 내역 카드와 카드가 아닌 두 수단 칸은 다크의 `surface`, 고른 수단은 #33363D(캔버스 DarkNPay).
    expect(box(CoraColors.dark.surface), findsAtLeastNWidgets(3));
    expect(box(CoraColors.light.surface), findsNothing);
    expect(box(CoraColors.dark.notifyTabSelected), findsOneWidget);
    expect(box(CoraColors.dark.accent), findsOneWidget);
  });

  testWidgets('does not overflow at 1.3x text scale', (tester) async {
    await pumpStoreHome(
      tester,
      home: homeWithPayableOffer(),
      smallPhoneLargeText: true,
      overrides: [
        paymentRepositoryProvider.overrideWithValue(FakePaymentRepository()),
      ],
    );
    await tester.tap(find.text('보낸 오퍼 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('결제하기'));
    await tester.pumpAndSettle();

    expect(find.byType(StorePaymentPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
