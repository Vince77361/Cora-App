import 'dart:convert';

import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/store_result/data/api_store_result_repository.dart';
import 'package:cora/features/store_result/domain/store_result_repository.dart';
import 'package:cora_api/api.dart' as api;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_http_client.dart';

ApiStoreResultRepository _repo(FakeHttpClient fake) => ApiStoreResultRepository(
  api.ApiClient(basePath: 'http://127.0.0.1:3000')..client = fake,
);

void main() {
  test('reads the result of a collaboration', () async {
    final fake = FakeHttpClient()
      ..body = jsonEncode({
        'creator': {'userId': 'u1', 'name': '하루 한 컵', 'photoUrl': null},
        'format': 'REELS',
        'postedAt': '2026-11-04T03:00:00.000Z',
        'postUrl': 'https://www.instagram.com/reel/abc',
        'views': 12500,
        'usualViews': 4000,
        'multiplierTenths': 31,
        'payout': 25000,
        'refund': 35000,
        'fixedCash': 0,
        'fixedCashOnly': false,
      });

    final result = await _repo(fake).fetch('col-1');

    expect(fake.requests.single.url.path, '/collaborations/col-1/result');
    expect(result.creator.name, '하루 한 컵');
    expect(result.format, ContentFormat.reels);
    expect(result.views, 12500);
    expect(result.multiplierTenths, 31);
    expect(result.payout, 25000);
    expect(result.refund, 35000);
    expect(result.postedAt, DateTime.utc(2026, 11, 4, 3));
    expect(result.hasComparison, isTrue);
  });

  test('keeps missing numbers as null and hides the comparison', () async {
    final fake = FakeHttpClient()
      ..body = jsonEncode({
        'creator': {'userId': 'u1', 'name': '하루 한 컵', 'photoUrl': null},
        'format': 'BLOG',
        'postedAt': '2026-11-04T03:00:00.000Z',
        'postUrl': 'https://blog.example.com/p/1',
        'views': null,
        'usualViews': null,
        'multiplierTenths': null,
        'payout': 30000,
        'refund': 0,
        'fixedCash': 30000,
        'fixedCashOnly': true,
      });

    final result = await _repo(fake).fetch('col-1');

    expect(result.views, isNull);
    expect(result.fixedCashOnly, isTrue);
    expect(result.hasComparison, isFalse);
  });

  test(
    'maps a 404 to not found and other failures to a plain failure',
    () async {
      final notFound = FakeHttpClient()
        ..statusCode = 404
        ..body =
            '{"error":{"code":"NOT_FOUND","message":"없어요","details":null}}';
      await expectLater(
        _repo(notFound).fetch('col-1'),
        throwsA(
          isA<StoreResultFailure>().having((e) => e.notFound, 'notFound', true),
        ),
      );

      final broken = FakeHttpClient()
        ..statusCode = 500
        ..body = '{}';
      await expectLater(
        _repo(broken).fetch('col-1'),
        throwsA(
          isA<StoreResultFailure>().having(
            (e) => e.notFound,
            'notFound',
            false,
          ),
        ),
      );
    },
  );
}
