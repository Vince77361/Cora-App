import 'dart:convert';

import 'package:cora/features/negotiation/data/api_negotiation_repository.dart';
import 'package:cora/features/negotiation/domain/contract.dart';
import 'package:cora/features/negotiation/domain/negotiation_repository.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart'
    show ContentFormat;
import 'package:cora/features/payment/domain/payment_repository.dart'
    show PaymentMethod;
import 'package:cora_api/api.dart' as api;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_http_client.dart';

ApiNegotiationRepository _repo(FakeHttpClient fake) => ApiNegotiationRepository(
  api.ApiClient(basePath: 'http://127.0.0.1:3000')..client = fake,
);

Map<String, Object?> _terms({Map<String, Object?>? performance}) => {
  'brandConfirmed': true,
  'changedFields': <String>[],
  'createdAt': '2026-11-11T03:00:00.000Z',
  'creatorConfirmed': true,
  'fee': 350000,
  'format': 'REELS',
  'maxCash': performance == null ? 350000 : 410000,
  'payoutDays': 7,
  'performance': performance,
  'pieces': 1,
  'previousMaxCash': null,
  'productProvided': true,
  'proposedBy': 'BRAND',
  'revisionScope': 'GUIDE_1',
  'startDate': '2026-11-23',
  'title': '출근 전 30초, 오늘의 손목 루틴',
  'usageRights': 'REPOST_ONLY',
  'version': 2,
};

Map<String, Object?> _quote() => {
  'creatorName': '서윤의 작은 취향',
  'creatorPhotoUrl': null,
  'escrow': 410000,
  'fee': 41000,
  'feeRate': 10,
  'fixedCash': 350000,
  'format': 'REELS',
  'orderName': '캠페인 제작비',
  'perViewCap': 60000,
  'pieces': 1,
  'total': 451000,
  'voucherName': null,
  'voucherPeople': null,
  'voucherValue': null,
};

/// 서버의 `ContractModel`. 계약의 진행(`status`)은 서버 문서에서 협업의 3값 열거형과 이름이 같아 생성된 클라이언트가
/// 풀지 못하므로, 앱이 직접 푸는 값들을 모두 시험한다.
Map<String, Object?> _contract(
  String status, {
  Map<String, Object?>? performance,
  Object? quote,
  bool voided = false,
}) => {
  'brandConsentedAt': null,
  'brandName': '모아 스튜디오',
  'concludedAt': status == 'CONCLUDED' ? '2026-11-23T03:00:00.000Z' : null,
  'creatorConsentedAt': status == 'AWAITING_CREATOR' || status == 'NOT_READY'
      ? null
      : '2026-11-20T03:00:00.000Z',
  'creatorName': '서윤의 작은 취향',
  'myConsentTexts': ['하나', '둘', '셋'],
  'quote': quote,
  'status': status,
  'terms': _terms(performance: performance),
  'termsVersion': 2,
  'voidedNotice': voided,
};

String _error(String code, String message, {Object? details}) => jsonEncode({
  'error': {'code': code, 'message': message, 'details': details},
});

void main() {
  test('fetchContract reads every status the server can send', () async {
    for (final entry in {
      'NOT_READY': ContractStatus.notReady,
      'AWAITING_CREATOR': ContractStatus.awaitingCreator,
      'AWAITING_BRAND': ContractStatus.awaitingBrand,
      'PAYING': ContractStatus.paying,
      'CONCLUDED': ContractStatus.concluded,
    }.entries) {
      final fake = FakeHttpClient()..body = jsonEncode(_contract(entry.key));

      final contract = await _repo(fake).fetchContract('col-1');

      expect(
        fake.requests.single.url.path,
        '/collaborations/col-1/contract',
        reason: entry.key,
      );
      expect(contract.status, entry.value, reason: entry.key);
    }
  });

  test('fetchContract maps the names, terms, quote and dates', () async {
    final fake = FakeHttpClient()
      ..body = jsonEncode(
        _contract(
          'AWAITING_BRAND',
          performance: {'cap': 60000, 'ratePer1000': 2000},
          quote: _quote(),
          voided: true,
        ),
      );

    final contract = await _repo(fake).fetchContract('col-1');

    expect(contract.brandName, '모아 스튜디오');
    expect(contract.creatorName, '서윤의 작은 취향');
    expect(contract.myConsentTexts, ['하나', '둘', '셋']);
    expect(contract.voidedNotice, isTrue);
    expect(contract.version, 2);
    expect(contract.terms!.fee, 350000);
    expect(contract.terms!.maxCash, 410000);
    expect(contract.terms!.performance!.cap, 60000);
    final quote = contract.quote!;
    expect(quote.fixedCash, 350000);
    expect(quote.viewPayCap, 60000);
    expect(quote.escrow, 410000);
    expect(quote.fee, 41000);
    expect(quote.total, 451000);
    expect(quote.format, ContentFormat.reels);
    expect(contract.creatorConsentedAt, DateTime.utc(2026, 11, 20, 3));
    expect(contract.concludedAt, isNull);
  });

  test('fetchContract without terms or quote keeps them empty', () async {
    final fake = FakeHttpClient()
      ..body = jsonEncode({
        ..._contract('NOT_READY'),
        'terms': null,
        'termsVersion': null,
        'myConsentTexts': <String>[],
      });

    final contract = await _repo(fake).fetchContract('col-1');

    expect(contract.terms, isNull);
    expect(contract.quote, isNull);
    expect(contract.myConsentTexts, isEmpty);
  });

  test(
    'fetchContract fails on an unknown status or a missing contract',
    () async {
      final unknown = FakeHttpClient()
        ..body = jsonEncode(_contract('SOMETHING'));
      await expectLater(
        _repo(unknown).fetchContract('col-1'),
        throwsA(isA<NegotiationFailure>()),
      );

      final missing = FakeHttpClient()
        ..statusCode = 404
        ..body = _error('NOT_FOUND', '협업을 찾을 수 없어요.');
      await expectLater(
        _repo(missing).fetchContract('col-1'),
        throwsA(isA<NegotiationFailure>()),
      );
    },
  );

  test(
    'consentAsCreator posts the version and the texts as they are',
    () async {
      final fake = FakeHttpClient()
        ..body = jsonEncode(_contract('AWAITING_BRAND'));

      final contract = await _repo(
        fake,
      ).consentAsCreator('col-1', 2, ['하나', '둘', '셋']);

      final request = fake.requests.single as dynamic;
      expect(request.method, 'POST');
      expect(
        request.url.path,
        '/collaborations/col-1/contract/creator-consent',
      );
      expect(jsonDecode(request.body as String), {
        'termsVersion': 2,
        'accepted': ['하나', '둘', '셋'],
      });
      expect(contract.status, ContractStatus.awaitingBrand);
    },
  );

  test('consentAsBrand posts the method and no amount', () async {
    final fake = FakeHttpClient()
      ..statusCode = 201
      ..body = jsonEncode({
        'paymentId': 'pay-1',
        'checkoutUrl': 'cora-dev://fake-pay?paymentId=pay-1',
      });

    final made = await _repo(
      fake,
    ).consentAsBrand('col-1', 2, ['하나', '둘', '셋'], PaymentMethod.easyPay);

    final request = fake.requests.single as dynamic;
    expect(request.url.path, '/collaborations/col-1/contract/brand-consent');
    expect(jsonDecode(request.body as String), {
      'termsVersion': 2,
      'accepted': ['하나', '둘', '셋'],
      'method': 'EASY_PAY',
    });
    expect(made.paymentId, 'pay-1');
    expect(made.checkoutUrl, 'cora-dev://fake-pay?paymentId=pay-1');
  });

  group('consent errors', () {
    test('a stale version carries the latest version number', () async {
      final fake = FakeHttpClient()
        ..statusCode = 409
        ..body = _error(
          'STALE_VERSION',
          '이전 판본이라 동의할 수 없어요.',
          details: {'latestVersion': 3},
        );

      await expectLater(
        _repo(fake).consentAsCreator('col-1', 2, []),
        throwsA(
          isA<NegotiationStale>().having((e) => e.latestVersion, 'latest', 3),
        ),
      );
      await expectLater(
        _repo(fake).consentAsBrand('col-1', 2, [], PaymentMethod.card),
        throwsA(isA<NegotiationStale>()),
      );
    });

    test('a conflict and a bad text list carry the server message', () async {
      final conflict = FakeHttpClient()
        ..statusCode = 409
        ..body = _error('CONFLICT', '지금은 계약에 동의할 수 없어요.');
      await expectLater(
        _repo(conflict).consentAsCreator('col-1', 2, []),
        throwsA(
          isA<NegotiationRejected>().having(
            (e) => e.message,
            'message',
            '지금은 계약에 동의할 수 없어요.',
          ),
        ),
      );

      final invalid = FakeHttpClient()
        ..statusCode = 400
        ..body = _error('VALIDATION_FAILED', '확인란을 모두 확인해 주세요.');
      await expectLater(
        _repo(invalid).consentAsBrand('col-1', 2, [], PaymentMethod.card),
        throwsA(isA<NegotiationRejected>()),
      );
    });

    test('a server error shows no server text', () async {
      final fake = FakeHttpClient()
        ..statusCode = 500
        ..body = _error('INTERNAL', '서버 내부 사정');

      await expectLater(
        _repo(fake).consentAsCreator('col-1', 2, []),
        throwsA(isA<NegotiationFailure>()),
      );
      await expectLater(
        _repo(fake).consentAsBrand('col-1', 2, [], PaymentMethod.card),
        throwsA(isA<NegotiationFailure>()),
      );
    });
  });
}
