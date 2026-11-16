import 'dart:convert';

import 'package:cora/features/brand_onboarding/data/api_campaign_repository.dart';
import 'package:cora/features/brand_onboarding/domain/campaign.dart';
import 'package:cora/features/brand_onboarding/domain/campaign_repository.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart'
    show ContentFormat;
import 'package:cora/features/principles/domain/principles.dart'
    show ProductTrialDays;
import 'package:cora_api/api.dart' as api;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../support/fake_http_client.dart';

ApiCampaignRepository _repo(FakeHttpClient fake) => ApiCampaignRepository(
  api.ApiClient(basePath: 'http://127.0.0.1:3000')..client = fake,
);

const _wire = {
  'id': 'campaign-1',
  'headline': '나만의 아침 루틴 속 작은 포인트',
  'fee': 300000,
  'budget': 1000000,
  'productProvided': true,
  'format': 'REELS',
  'startFrom': '2026-11-20',
  'trialDays': 'D7',
  'mustInclude': ['제품 로고'],
  'notRequired': ['FACE', 'SCRIPT_READING'],
  'status': 'ACTIVE',
};

final _input = CampaignInput(
  headline: '나만의 아침 루틴 속 작은 포인트',
  fee: 300000,
  budget: 1000000,
  productProvided: true,
  format: ContentFormat.reels,
  startFrom: DateTime(2026, 11, 20),
  trialDays: ProductTrialDays.d7,
  mustInclude: const ['제품 로고'],
  notRequired: const [NotRequired.face, NotRequired.scriptReading],
);

String _error(String code, String message) => jsonEncode({
  'error': {'code': code, 'message': message, 'details': null},
});

void main() {
  test('fetch maps every field', () async {
    final fake = FakeHttpClient()..body = jsonEncode(_wire);

    final campaign = (await _repo(fake).fetchMyActive())!;

    expect(fake.requests.single.url.path, '/campaigns/mine/active');
    expect(campaign.id, 'campaign-1');
    expect(campaign.budget, 1000000);
    expect(campaign.format, ContentFormat.reels);
    expect(campaign.startFrom, DateTime(2026, 11, 20));
    expect(campaign.trialDays, ProductTrialDays.d7);
    expect(campaign.mustInclude, ['제품 로고']);
    expect(campaign.notRequired, [NotRequired.face, NotRequired.scriptReading]);
    expect(campaign.status, CampaignStatus.active);
  });

  test('fetch returns null when there is no active campaign (404)', () async {
    final fake = FakeHttpClient()
      ..statusCode = 404
      ..body = _error('NOT_FOUND', '없어요.');

    expect(await _repo(fake).fetchMyActive(), isNull);
  });

  test('create sends the budget and every other field', () async {
    final fake = FakeHttpClient()..body = jsonEncode(_wire);

    await _repo(fake).create(_input);

    final request = fake.requests.single as http.Request;
    expect(request.method, 'POST');
    expect(request.url.path, '/campaigns');
    expect(jsonDecode(request.body), {
      'headline': '나만의 아침 루틴 속 작은 포인트',
      'fee': 300000,
      'budget': 1000000,
      'productProvided': true,
      'format': 'REELS',
      'startFrom': '2026-11-20',
      'trialDays': 'D7',
      'mustInclude': ['제품 로고'],
      'notRequired': ['FACE', 'SCRIPT_READING'],
    });
  });

  test(
    'update patches the campaign and close posts to its close path',
    () async {
      final fake = FakeHttpClient()..body = jsonEncode(_wire);

      await _repo(fake).update('campaign-1', _input);
      await _repo(fake).close('campaign-1');

      final update = fake.requests.first as http.Request;
      expect(update.method, 'PATCH');
      expect(update.url.path, '/campaigns/campaign-1');
      final close = fake.requests.last as http.Request;
      expect(close.method, 'POST');
      expect(close.url.path, '/campaigns/campaign-1/close');
    },
  );

  test('a 400 carries the server message so the screen can show it', () async {
    final fake = FakeHttpClient()
      ..statusCode = 400
      ..body = _error('VALIDATION_FAILED', '캠페인 예산은 제작비 이상이어야 해요.');

    await expectLater(
      _repo(fake).create(_input),
      throwsA(
        isA<CampaignFailure>().having(
          (e) => e.message,
          'message',
          '캠페인 예산은 제작비 이상이어야 해요.',
        ),
      ),
    );
  });

  test('a 409 carries the message and a 500 carries none', () async {
    final conflict = FakeHttpClient()
      ..statusCode = 409
      ..body = _error('CONFLICT', '이미 진행 중인 캠페인이 있어요.');
    await expectLater(
      _repo(conflict).create(_input),
      throwsA(
        isA<CampaignFailure>().having(
          (e) => e.message,
          'message',
          '이미 진행 중인 캠페인이 있어요.',
        ),
      ),
    );

    final broken = FakeHttpClient()
      ..statusCode = 500
      ..body = _error('INTERNAL', '서버 내부 문구');
    await expectLater(
      _repo(broken).create(_input),
      throwsA(
        isA<CampaignFailure>().having((e) => e.message, 'message', isNull),
      ),
    );
  });
}
