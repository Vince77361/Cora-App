import 'dart:convert';

import 'package:cora/features/payout_account/data/api_payout_account_repository.dart';
import 'package:cora/features/payout_account/domain/payout_account_repository.dart';
import 'package:cora_api/api.dart' as api;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_http_client.dart';

ApiPayoutAccountRepository _repo(FakeHttpClient fake) =>
    ApiPayoutAccountRepository(
      api.ApiClient(basePath: 'http://127.0.0.1:3000')..client = fake,
    );

void main() {
  test('fetch maps the account', () async {
    final fake = FakeHttpClient()
      ..body = jsonEncode({
        'accountLast4': '0112',
        'bankCode': '004',
        'bankFullName': '국민은행',
        'bankName': '국민',
        'holderName': '민서연',
      });

    final account = await _repo(fake).fetch();

    expect(fake.requests.single.url.path, '/payout-account');
    expect(account!.bankFullName, '국민은행');
    expect(account.accountLast4, '0112');
    expect(account.holderName, '민서연');
  });

  test('fetch returns null when no account is registered (404)', () async {
    final fake = FakeHttpClient()
      ..statusCode = 404
      ..body = jsonEncode({
        'error': {
          'code': 'NOT_FOUND',
          'message': '등록된 지급 계좌가 없어요.',
          'details': null,
        },
      });

    expect(await _repo(fake).fetch(), isNull);
  });

  test('banks maps the list', () async {
    final fake = FakeHttpClient()
      ..body = jsonEncode([
        {'code': '004', 'name': '국민', 'fullName': '국민은행'},
      ]);

    final banks = await _repo(fake).banks();

    expect(fake.requests.single.url.path, '/payout-account/banks');
    expect((banks.single.code, banks.single.name), ('004', '국민'));
  });

  test('save sends the number with the bank code', () async {
    final fake = FakeHttpClient()
      ..body = jsonEncode({
        'accountLast4': '0112',
        'bankCode': '004',
        'bankFullName': '국민은행',
        'bankName': '국민',
        'holderName': '민서연',
      });

    await _repo(
      fake,
    ).save(bankCode: '004', accountNumber: '1234567890112', holderName: '민서연');

    final request = fake.requests.single as dynamic;
    expect(request.method, 'PUT');
    expect(jsonDecode(request.body as String), {
      'accountNumber': '1234567890112',
      'bankCode': '004',
      'holderName': '민서연',
    });
  });

  test('keeps the message of a 4xx and drops the one of a 500', () async {
    final rejected = FakeHttpClient()
      ..statusCode = 400
      ..body = jsonEncode({
        'error': {
          'code': 'VALIDATION_FAILED',
          'message': '지원하지 않는 은행이에요.',
          'details': null,
        },
      });
    await expectLater(
      _repo(rejected).save(
        bankCode: '004',
        accountNumber: '1234567890112',
        holderName: '민서연',
      ),
      throwsA(
        isA<PayoutAccountFailure>().having(
          (e) => e.message,
          'message',
          '지원하지 않는 은행이에요.',
        ),
      ),
    );

    // 키가 없는 서버의 오류 본문은 내부 사정이라 화면에 보이지 않는다.
    final broken = FakeHttpClient()
      ..statusCode = 500
      ..body = jsonEncode({
        'error': {
          'code': 'INTERNAL',
          'message': 'PAYOUT_ACCOUNT_KEY',
          'details': null,
        },
      });
    await expectLater(
      _repo(broken).save(
        bankCode: '004',
        accountNumber: '1234567890112',
        holderName: '민서연',
      ),
      throwsA(
        isA<PayoutAccountFailure>().having((e) => e.message, 'message', isNull),
      ),
    );
  });
}
