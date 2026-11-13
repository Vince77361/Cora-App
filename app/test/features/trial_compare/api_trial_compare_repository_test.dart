import 'dart:convert';

import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/store_onboarding/data/api_store_repository.dart';
import 'package:cora/features/trial_compare/data/api_trial_compare_repository.dart';
import 'package:cora/features/trial_compare/domain/trial_compare_repository.dart';
import 'package:cora/features/trial_compare/domain/trial_info.dart';
import 'package:cora_api/api.dart' as api;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../support/fake_http_client.dart';

ApiTrialCompareRepository _repo(FakeHttpClient fake) =>
    ApiTrialCompareRepository(
      api.ApiClient(basePath: 'http://127.0.0.1:3000')..client = fake,
    );

String _storeJson({Map<String, dynamic>? trialInfo, String? trialBanner}) =>
    jsonEncode({
      'id': 'store-1',
      'status': 'PUBLISHED',
      'onboardingStep': 'DONE',
      'name': '한그릇 라멘',
      'category': null,
      'industry': 'FOOD_CAFE',
      'neighborhood': null,
      'regionSido': null,
      'regionSigungu': null,
      'coverPhotoUrl': null,
      'signatureMenu': null,
      'hours': null,
      'seats': null,
      'bestShootingTime': null,
      'intro': null,
      'slug': 'a',
      'publicUrl': 'cora.page/l/a',
      'tags': [],
      'customerPhrases': [],
      'recruitLine': null,
      'trialInfo': trialInfo,
      'trialBanner': trialBanner,
      'defaultTerms': null,
      'sourceLinks': [],
    });

void main() {
  test('reads the three month comparison', () async {
    final fake = FakeHttpClient()
      ..body = jsonEncode({
        'trial': {
          'monthlyFee': 300000,
          'endsOn': '2026-12-10',
          'postCount': 9,
          'spent': 900000,
        },
        'cora': {
          'offerCount': 4,
          'spent': 152000,
          'averageMultiplierTenths': 26,
          'contentByFormat': [
            {'format': 'REELS', 'count': 4},
          ],
        },
      });

    final comparison = await _repo(fake).fetchComparison();

    expect(fake.requests.single.url.path, '/stores/me/trial-comparison');
    expect(comparison.trial.monthlyFee, 300000);
    expect(comparison.trial.endsOn, DateTime(2026, 12, 10));
    expect(comparison.trial.postCount, 9);
    expect(comparison.cora.offerCount, 4);
    expect(comparison.cora.averageMultiplierTenths, 26);
    expect(comparison.cora.contentByFormat.single.format, ContentFormat.reels);
    expect(comparison.cora.contentByFormat.single.count, 4);
  });

  test(
    'fails instead of using today when the end date cannot be read',
    () async {
      final fake = FakeHttpClient()
        ..body = jsonEncode({
          'trial': {
            'monthlyFee': 300000,
            'endsOn': 'soon',
            'postCount': 9,
            'spent': 900000,
          },
          'cora': {
            'offerCount': 0,
            'spent': 0,
            'averageMultiplierTenths': null,
            'contentByFormat': [],
          },
        });

      await expectLater(
        _repo(fake).fetchComparison(),
        throwsA(isA<TrialCompareFailure>()),
      );
    },
  );

  test('maps a 404 to not found', () async {
    final fake = FakeHttpClient()
      ..statusCode = 404
      ..body = '{"error":{"code":"NOT_FOUND","message":"없어요","details":null}}';

    await expectLater(
      _repo(fake).fetchComparison(),
      throwsA(
        isA<TrialCompareFailure>().having((e) => e.notFound, 'notFound', true),
      ),
    );
  });

  test(
    'saves, clears, snoozes and marks the hint with the right calls',
    () async {
      final fake = FakeHttpClient()
        ..body = _storeJson(
          trialInfo: {
            'monthlyFee': 300000,
            'endsOn': '2026-12-10',
            'postCount': 9,
          },
        );
      await _repo(fake).saveInfo(
        TrialInfo(
          monthlyFee: 300000,
          endsOn: DateTime(2026, 12, 10),
          postCount: 9,
        ),
      );
      final put = fake.requests.single as http.Request;
      expect(put.method, 'PUT');
      expect(put.url.path, '/stores/me/trial-info');
      expect(jsonDecode(put.body), {
        'monthlyFee': 300000,
        'endsOn': '2026-12-10',
        'postCount': 9,
      });

      final other = FakeHttpClient()
        ..statusCode = 204
        ..body = '';
      final repo = _repo(other);
      await repo.deleteInfo();
      await repo.snooze();
      await repo.markHintSeen();
      expect(other.requests.map((r) => '${r.method} ${r.url.path}'), [
        'DELETE /stores/me/trial-info',
        'POST /stores/me/trial-info/snooze',
        'POST /stores/me/trial-info/hint-seen',
      ]);
    },
  );

  test('my store carries the trial info and the home banner', () async {
    final fake = FakeHttpClient()
      ..body = _storeJson(
        trialInfo: {
          'monthlyFee': 300000,
          'endsOn': '2026-12-10',
          'postCount': 9,
        },
        trialBanner: 'COMPARE',
      );
    final store = (await ApiStoreRepository(
      api.ApiClient(basePath: 'http://127.0.0.1:3000')..client = fake,
    ).fetchMine())!;

    expect(
      store.trialInfo,
      TrialInfo(
        monthlyFee: 300000,
        endsOn: DateTime(2026, 12, 10),
        postCount: 9,
      ),
    );
    expect(store.trialBanner, TrialBannerKind.compare);

    final hint = FakeHttpClient()..body = _storeJson(trialBanner: 'HINT');
    final hintStore = (await ApiStoreRepository(
      api.ApiClient(basePath: 'http://127.0.0.1:3000')..client = hint,
    ).fetchMine())!;
    expect(hintStore.trialInfo, isNull);
    expect(hintStore.trialBanner, TrialBannerKind.hint);
  });
}
