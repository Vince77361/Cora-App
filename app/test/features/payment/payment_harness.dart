import 'package:cora/core/config/app_config.dart';
import 'package:cora/features/offers/domain/offer_view.dart';
import 'package:cora/features/payment/presentation/checkout_launcher.dart';
import 'package:cora/features/payment/domain/payment_repository.dart';
import 'package:cora/features/payment/presentation/viewmodels/payment_view_model.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../store_home/fake_store_home_repository.dart';
import '../store_home/store_home_harness.dart';
import 'fake_payment_repository.dart';

/// 간격을 줄이고 횟수를 3번으로 한 확인 설정(테스트가 오래 기다리지 않게).
const fastPolling = PaymentPolling(
  interval: Duration(milliseconds: 10),
  attempts: 3,
);

/// 결제를 기다리는 오퍼가 하나 있는 사장님 홈.
FakeStoreHomeRepository homeWithPayableOffer() => FakeStoreHomeRepository(
  sent: [
    sentOffer(
      id: 'o1',
      name: '하루 한 컵',
      view: OfferView.accepted,
      collaborationId: 'col-1',
      paymentDaysLeft: 3,
    ),
  ],
);

/// 사장님 홈에서 `결제하기`를 눌러 A8을 연다. [launcher]를 주지 않으면 실제 결제창 열기를 쓴다.
Future<void> pumpPayment(
  WidgetTester tester, {
  FakePaymentRepository? payments,
  FakeStoreHomeRepository? home,
  FakeCheckoutLauncher? launcher,
  CoraEnv env = CoraEnv.dev,
  List<Override> overrides = const [],
  bool open = true,
}) async {
  await pumpStoreHome(
    tester,
    home: home ?? homeWithPayableOffer(),
    env: env,
    overrides: [
      paymentRepositoryProvider.overrideWithValue(
        payments ?? FakePaymentRepository(),
      ),
      paymentPollingProvider.overrideWithValue(fastPolling),
      if (launcher != null)
        checkoutLauncherProvider.overrideWithValue(launcher),
      ...overrides,
    ],
  );
  if (!open) return;
  await tester.tap(find.text('보낸 오퍼 1'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('결제하기'));
  await tester.pumpAndSettle();
}
