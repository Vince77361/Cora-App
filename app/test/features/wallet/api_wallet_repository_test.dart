import 'dart:convert';

import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/wallet/data/api_wallet_repository.dart';
import 'package:cora/features/wallet/domain/wallet.dart';
import 'package:cora/features/wallet/domain/wallet_repository.dart';
import 'package:cora_api/api.dart' as api;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_http_client.dart';

ApiWalletRepository _repo(FakeHttpClient fake) => ApiWalletRepository(
  api.ApiClient(basePath: 'http://127.0.0.1:3000')..client = fake,
);

Map<String, dynamic> _entry({
  required String kind,
  int? amount,
  int? views,
  String? voucherName,
  bool? voucherUsed,
  String stage = 'COUNTING',
  String format = 'REELS',
}) => {
  'amount': amount,
  'at': '2026-11-11T03:00:00.000Z',
  'collaborationId': 'c1',
  'counterpartName': '한그릇 라멘',
  'format': format,
  'kind': kind,
  'pieces': 1,
  'stage': stage,
  'views': views,
  'voucherName': voucherName,
  'voucherUsed': voucherUsed,
};

void main() {
  test('fetch maps the numbers, account, payday and entries', () async {
    final fake = FakeHttpClient()
      ..body = jsonEncode({
        'account': {
          'accountLast4': '0112',
          'bankFullName': '국민은행',
          'bankName': '국민',
          'holderName': '민서연',
        },
        'entries': [
          _entry(kind: 'PAYOUT_SCHEDULED', amount: 43200, views: 4320),
          _entry(kind: 'VOUCHER', voucherName: '2인 식사권', voucherUsed: false),
          _entry(
            kind: 'HELD',
            amount: 100000,
            stage: 'PUBLISHED',
            format: 'CARD_NEWS',
          ),
        ],
        'heldAmount': 100000,
        'nextPayout': {'amount': 43200, 'date': '2026-11-18'},
        'receivedThisMonth': 350000,
      });

    final wallet = await _repo(fake).fetch();

    expect(fake.requests.single.url.path, '/wallet');
    expect(wallet.account!.bankFullName, '국민은행');
    expect(wallet.account!.accountLast4, '0112');
    expect(wallet.nextPayout!.amount, 43200);
    // 지급일은 한국 시간 수요일 10:00이다.
    expect(wallet.nextPayout!.date, DateTime.utc(2026, 11, 18, 1));
    expect(wallet.receivedThisMonth, 350000);
    expect(wallet.heldAmount, 100000);
    expect(wallet.entries.map((e) => e.kind), [
      WalletEntryKind.payoutScheduled,
      WalletEntryKind.voucher,
      WalletEntryKind.held,
    ]);
    expect(wallet.entries.first.views, 4320);
    expect(wallet.entries[1].voucherUsed, isFalse);
    expect(wallet.entries[2].format, ContentFormat.cardNews);
    expect(wallet.entries[2].published, isTrue);
    expect(wallet.entries.first.published, isFalse);
  });

  test(
    'fetch keeps an unregistered account and no next payout as null',
    () async {
      final fake = FakeHttpClient()
        ..body = jsonEncode({
          'account': null,
          'entries': <Object>[],
          'heldAmount': 0,
          'nextPayout': null,
          'receivedThisMonth': 0,
        });

      final wallet = await _repo(fake).fetch();

      expect(wallet.account, isNull);
      expect(wallet.nextPayout, isNull);
      expect(wallet.entries, isEmpty);
    },
  );

  test('a failed request becomes a WalletFailure', () async {
    final fake = FakeHttpClient()..statusCode = 500;

    await expectLater(_repo(fake).fetch(), throwsA(isA<WalletFailure>()));
  });
}
