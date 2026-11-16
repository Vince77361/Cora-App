import 'dart:convert';

import 'package:cora/features/principles/data/api_principles_repository.dart';
import 'package:cora/features/principles/domain/principles.dart';
import 'package:cora/features/principles/domain/principles_repository.dart';
import 'package:cora/features/store_onboarding/domain/my_store.dart';
import 'package:cora_api/api.dart' as api;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../support/fake_http_client.dart';

ApiPrinciplesRepository _repo(FakeHttpClient fake) => ApiPrinciplesRepository(
  api.ApiClient(basePath: 'http://127.0.0.1:3000')..client = fake,
);

const _wire = {
  'fields': ['FOOD_CAFE', 'ACCESSORY'],
  'blockedIndustries': ['GAMBLING', 'DIET_SUPPLEMENT'],
  'faceOk': true,
  'scriptOk': false,
  'honestReview': true,
  'feeBand': 'W500K_PLUS',
  'trialDays': 'ANY',
};

const _principles = Principles(
  fields: [IndustryCategory.foodCafe, IndustryCategory.accessory],
  blockedIndustries: [
    IndustryCategory.gambling,
    IndustryCategory.dietSupplement,
  ],
  faceOk: true,
  scriptOk: false,
  honestReview: true,
  feeBand: FeeBand.w500kPlus,
  trialDays: ProductTrialDays.any,
);

void main() {
  test('fetch maps every field', () async {
    final fake = FakeHttpClient()..body = jsonEncode(_wire);

    final principles = await _repo(fake).fetchMine();

    expect(fake.requests.single.url.path, '/creators/me/principles');
    expect(principles, _principles);
  });

  test('fetch returns null when no principles are set (404)', () async {
    final fake = FakeHttpClient()
      ..statusCode = 404
      ..body = jsonEncode({
        'error': {
          'code': 'NOT_FOUND',
          'message': '협업 원칙이 아직 없어요.',
          'details': null,
        },
      });

    expect(await _repo(fake).fetchMine(), isNull);
  });

  test('fetch throws a failure on a server error', () async {
    final fake = FakeHttpClient()..statusCode = 500;

    await expectLater(
      _repo(fake).fetchMine(),
      throwsA(isA<PrinciplesFailure>()),
    );
  });

  test('save sends the whole principles as a PUT', () async {
    final fake = FakeHttpClient()..body = jsonEncode(_wire);

    final saved = await _repo(fake).save(_principles);

    final request = fake.requests.single as http.Request;
    expect(request.method, 'PUT');
    expect(request.url.path, '/creators/me/principles');
    expect(jsonDecode(request.body), _wire);
    expect(saved, _principles);
  });

  test('save throws a failure when the server refuses', () async {
    final fake = FakeHttpClient()..statusCode = 400;

    await expectLater(
      _repo(fake).save(_principles),
      throwsA(isA<PrinciplesFailure>()),
    );
  });

  test('maps every industry, fee band and trial period both ways', () async {
    for (final industry in IndustryCategory.values) {
      final isSensitive = const {
        IndustryCategory.alcohol,
        IndustryCategory.gambling,
        IndustryCategory.loan,
        IndustryCategory.dietSupplement,
      }.contains(industry);
      final one = Principles(
        fields: isSensitive ? [IndustryCategory.other] : [industry],
        blockedIndustries: isSensitive ? [industry] : [],
        faceOk: true,
        scriptOk: true,
        honestReview: false,
        feeBand: FeeBand.w200k,
        trialDays: ProductTrialDays.d3,
      );
      final fake = FakeHttpClient();
      final repo = _repo(fake);
      // 서버가 받은 값을 그대로 돌려준다고 보고, 보낸 본문을 응답으로 되먹인다.
      fake.body = jsonEncode(_wire);
      await repo.save(one);
      fake.body = (fake.requests.single as http.Request).body;
      expect(await repo.fetchMine(), one);
    }
    for (final fee in FeeBand.values) {
      final fake = FakeHttpClient();
      final one = Principles(
        fields: const [IndustryCategory.other],
        blockedIndustries: const [],
        faceOk: false,
        scriptOk: false,
        honestReview: false,
        feeBand: fee,
        trialDays: ProductTrialDays.d7,
      );
      fake.body = jsonEncode(_wire);
      await _repo(fake).save(one);
      fake.body = (fake.requests.single as http.Request).body;
      expect((await _repo(fake).fetchMine())!.feeBand, fee);
    }
    for (final days in ProductTrialDays.values) {
      final fake = FakeHttpClient();
      final one = Principles(
        fields: const [IndustryCategory.other],
        blockedIndustries: const [],
        faceOk: false,
        scriptOk: false,
        honestReview: false,
        feeBand: FeeBand.w300k,
        trialDays: days,
      );
      fake.body = jsonEncode(_wire);
      await _repo(fake).save(one);
      fake.body = (fake.requests.single as http.Request).body;
      expect((await _repo(fake).fetchMine())!.trialDays, days);
    }
  });
}
