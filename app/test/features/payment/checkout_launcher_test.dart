import 'package:cora/features/payment/presentation/checkout_launcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fakeCheckoutPaymentId reads the payment from a dev checkout url', () {
    expect(
      fakeCheckoutPaymentId('cora-dev://fake-pay?paymentId=pay-1'),
      'pay-1',
    );
    expect(fakeCheckoutPaymentId('cora-dev://fake-pay?paymentId=a%20b'), 'a b');
  });

  test('fakeCheckoutPaymentId returns null for other addresses', () {
    expect(fakeCheckoutPaymentId('https://pay.example.com/checkout/1'), isNull);
    expect(fakeCheckoutPaymentId('cora-dev://fake-pay'), isNull);
    expect(fakeCheckoutPaymentId('cora-dev://fake-instagram'), isNull);
  });
}
