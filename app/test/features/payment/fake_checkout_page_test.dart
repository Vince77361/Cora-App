import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/network/api_client_provider.dart';
import 'package:cora/features/payment/domain/payment_repository.dart';
import 'package:cora/features/payment/presentation/pages/fake_checkout_page.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_http_client.dart';
import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../store_home/store_home_harness.dart';
import 'fake_payment_repository.dart';
import 'payment_harness.dart';

const _submit = '결제하고 보관 맡기기';

/// 실제 결제창 열기(앱 안의 가짜 결제창)로 A8에서 결제를 시작한다.
Future<(FakePaymentRepository, FakeHttpClient)> _openFakeCheckout(
  WidgetTester tester, {
  List<PaymentStatus> statuses = const [PaymentStatus.approved],
}) async {
  final payments = FakePaymentRepository(statuses: statuses);
  final http = FakeHttpClient();
  await pumpPayment(
    tester,
    payments: payments,
    overrides: <Override>[httpClientProvider.overrideWithValue(http)],
  );
  await tester.tap(find.text(_submit));
  await tester.pumpAndSettle();
  return (payments, http);
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('opens the fake checkout with the amount', (tester) async {
    await _openFakeCheckout(tester);

    expect(find.byType(FakeCheckoutPage), findsOneWidget);
    expect(topPath(tester), AppRoutes.devFakeCheckout);
    expect(find.text('110,000원'), findsOneWidget);
    for (final label in ['결제 승인', '결제 실패', '닫기']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('approving calls the dev route and closes the window', (
    tester,
  ) async {
    final (payments, http) = await _openFakeCheckout(tester);

    await tester.tap(find.text('결제 승인'));
    await tester.pumpAndSettle();

    final request = http.requests.last;
    expect(request.method, 'POST');
    expect(request.url.path, '/dev/fake-payments/pay-1/approve');
    expect(request.headers['Authorization'], startsWith('Bearer '));
    // 창이 닫히면 앱이 상태를 묻고, 승인이라 홈으로 간다.
    expect(find.byType(FakeCheckoutPage), findsNothing);
    expect(payments.statusCalls, 1);
    expect(currentPath(tester), AppRoutes.store);
    expect(find.text('결제했어요. 크리에이터에게 알렸어요.'), findsOneWidget);
  });

  testWidgets('failing calls the dev route and A8 asks to retry', (
    tester,
  ) async {
    final (_, http) = await _openFakeCheckout(
      tester,
      statuses: [PaymentStatus.failed],
    );

    await tester.tap(find.text('결제 실패'));
    await tester.pumpAndSettle();

    expect(http.requests.last.url.path, '/dev/fake-payments/pay-1/fail');
    expect(find.byType(FakeCheckoutPage), findsNothing);
    expect(find.text('결제가 완료되지 않았어요. 다시 시도해 주세요.'), findsOneWidget);
  });

  testWidgets('closing sends nothing and A8 keeps asking', (tester) async {
    final (payments, http) = await _openFakeCheckout(
      tester,
      statuses: [PaymentStatus.pending],
    );
    final before = http.requests.length;

    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();

    expect(http.requests.length, before);
    expect(find.byType(FakeCheckoutPage), findsNothing);
    expect(payments.statusCalls, fastPolling.attempts);
    expect(find.text('결제가 완료되지 않았어요. 다시 시도해 주세요.'), findsOneWidget);
  });

  testWidgets('stays open and says so when the dev route fails', (
    tester,
  ) async {
    final (_, http) = await _openFakeCheckout(tester);
    http.statusCode = 404;
    http.body = '{"error":{"code":"NOT_FOUND","message":"결제를 찾을 수 없어요."}}';

    await tester.tap(find.text('결제 승인'));
    await tester.pumpAndSettle();

    expect(find.byType(FakeCheckoutPage), findsOneWidget);
    expect(find.text(FakeCheckoutPage.sendFailed), findsOneWidget);
  });
}
