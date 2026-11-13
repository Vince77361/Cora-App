import 'dart:convert';

import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/payment/data/api_payment_repository.dart';
import 'package:cora/features/payment/domain/payment_repository.dart';
import 'package:cora_api/api.dart' as api;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_http_client.dart';

ApiPaymentRepository _repo(FakeHttpClient fake) => ApiPaymentRepository(
  api.ApiClient(basePath: 'http://127.0.0.1:3000')..client = fake,
);

final _quoteJson = jsonEncode({
  'creatorName': '하루 한 컵',
  'creatorPhotoUrl': 'https://example.test/c.jpg',
  'escrow': 100000,
  'fee': 10000,
  'feeRate': 10,
  'fixedCash': 0,
  'format': 'REELS',
  'orderName': '릴스 1편',
  'pieces': 1,
  'total': 110000,
  'perViewCap': 100000,
  'voucherName': null,
  'voucherPeople': null,
  'voucherValue': null,
});

void main() {
  test('fetchQuote reads the screen values from the quote', () async {
    final fake = FakeHttpClient()..body = _quoteJson;

    final quote = await _repo(fake).fetchQuote('col-1');

    expect(
      fake.requests.single.url.path,
      '/collaborations/col-1/payment-quote',
    );
    expect(quote.creatorName, '하루 한 컵');
    expect(quote.creatorPhotoUrl, 'https://example.test/c.jpg');
    expect(quote.format, ContentFormat.reels);
    expect(quote.pieces, 1);
    expect(quote.voucherName, isNull);
    expect((quote.escrow, quote.fee, quote.total), (100000, 10000, 110000));
  });

  test('create sends the method and returns the checkout address', () async {
    final fake = FakeHttpClient()
      ..statusCode = 201
      ..body = jsonEncode({
        'paymentId': 'pay-1',
        'checkoutUrl': 'cora-dev://fake-pay?paymentId=pay-1',
      });

    final created = await _repo(fake).create('col-1', PaymentMethod.easyPay);

    final request = fake.requests.single as dynamic;
    expect(request.method, 'POST');
    expect(request.url.path, '/collaborations/col-1/payments');
    expect(jsonDecode(request.body as String), {'method': 'EASY_PAY'});
    expect(created.paymentId, 'pay-1');
    expect(created.checkoutUrl, 'cora-dev://fake-pay?paymentId=pay-1');
  });

  test('fetchStatus maps every status', () async {
    final expected = {
      'PENDING': PaymentStatus.pending,
      'APPROVED': PaymentStatus.approved,
      'FAILED': PaymentStatus.failed,
      'CANCELLED': PaymentStatus.cancelled,
    };
    for (final entry in expected.entries) {
      final fake = FakeHttpClient()..body = jsonEncode({'status': entry.key});
      expect(await _repo(fake).fetchStatus('pay-1'), entry.value);
      expect(fake.requests.single.url.path, '/payments/pay-1');
    }
  });

  test('turns a 409 into a conflict failure and drops the message', () async {
    final fake = FakeHttpClient()
      ..statusCode = 409
      ..body =
          '{"error":{"code":"CONFLICT","message":"결제할 수 있는 협업이 아니에요.","details":null}}';

    await expectLater(
      _repo(fake).create('col-1', PaymentMethod.card),
      throwsA(
        isA<PaymentFailure>().having((f) => f.conflict, 'conflict', true),
      ),
    );
    await expectLater(
      _repo(fake).fetchQuote('col-1'),
      throwsA(
        isA<PaymentFailure>().having((f) => f.conflict, 'conflict', true),
      ),
    );
  });

  test('turns any other failure into a plain failure', () async {
    final fake = FakeHttpClient()
      ..statusCode = 500
      ..body = '{"error":{"code":"INTERNAL","message":"x","details":null}}';

    await expectLater(
      _repo(fake).fetchStatus('pay-1'),
      throwsA(
        isA<PaymentFailure>().having((f) => f.conflict, 'conflict', false),
      ),
    );
  });
}
