import 'dart:convert';

import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/store_onboarding/data/api_content_draft_repository.dart';
import 'package:cora/features/store_onboarding/data/api_store_repository.dart';
import 'package:cora/features/store_onboarding/domain/content_draft.dart';
import 'package:cora/features/store_onboarding/domain/content_draft_repository.dart';
import 'package:cora/features/store_onboarding/domain/my_store.dart';
import 'package:cora/features/store_onboarding/domain/source_link.dart';
import 'package:cora/features/store_onboarding/domain/store_repository.dart';
import 'package:cora_api/api.dart' as api;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../support/fake_http_client.dart';

String _storeJson({String status = 'DRAFT', String step = 'PAGE'}) =>
    jsonEncode({
      'id': 'store-1',
      'status': status,
      'onboardingStep': step,
      'name': '한그릇 라멘',
      'category': '라멘집',
      'industry': 'BEAUTY',
      'neighborhood': '성수동',
      'regionSido': '서울특별시',
      'regionSigungu': '성동구',
      'coverPhotoUrl': 'https://example.test/cover.jpg',
      'signatureMenu': null,
      'hours': '11:30 – 21:00',
      'seats': null,
      'bestShootingTime': null,
      'intro': '소개',
      'defaultTerms': {
        'format': 'CARD_NEWS',
        'rewardType': 'BOTH',
        'voucherName': '2인 식사권',
        'voucherValue': 40000,
        'perViewAmount': 10,
        'perViewCap': 100000,
      },
      'sourceLinks': [
        {'kind': 'NAVER_MAP', 'url': 'https://naver.me/abc', 'summary': '찾음'},
        {
          'kind': 'INSTAGRAM',
          'url': 'https://instagram.com/a',
          'summary': null,
        },
      ],
    });

ApiStoreRepository _stores(FakeHttpClient fake) => ApiStoreRepository(
  api.ApiClient(basePath: 'http://127.0.0.1:3000')..client = fake,
);

ApiContentDraftRepository _drafts(FakeHttpClient fake) =>
    ApiContentDraftRepository(
      api.ApiClient(basePath: 'http://127.0.0.1:3000')..client = fake,
    );

Map<String, dynamic> _bodyOf(http.BaseRequest r) =>
    jsonDecode((r as http.Request).body) as Map<String, dynamic>;

const _notFound =
    '{"error":{"code":"NOT_FOUND","message":"가게를 먼저 만들어 주세요.","details":null}}';

void main() {
  group('ApiStoreRepository', () {
    test('fetchMine maps every field of the store', () async {
      final fake = FakeHttpClient()..body = _storeJson();

      final store = (await _stores(fake).fetchMine())!;

      expect(fake.requests.single.url.path, '/stores/me');
      expect(store.status, StoreStatus.draft);
      expect(store.onboardingStep, StoreOnboardingStep.page);
      expect(store.industry, IndustryCategory.beauty);
      expect(store.name, '한그릇 라멘');
      expect(store.regionText, '서울특별시 성동구');
      expect(store.signatureMenu, isNull);
      expect(
        store.defaultTerms,
        const OfferTerms(
          format: ContentFormat.cardNews,
          rewardType: RewardType.both,
          voucherName: '2인 식사권',
          voucherValue: 40000,
          perViewAmount: 10,
          perViewCap: 100000,
        ),
      );
      expect(store.sourceLinks, const [
        SourceLink(
          kind: SourceLinkKind.naverMap,
          url: 'https://naver.me/abc',
          summary: '찾음',
        ),
        SourceLink(
          kind: SourceLinkKind.instagram,
          url: 'https://instagram.com/a',
        ),
      ]);
      expect(store.wasAutoFilled, isTrue);
    });

    test('fetchMine is null when the user has no store yet (404)', () async {
      final fake = FakeHttpClient()
        ..statusCode = 404
        ..body = _notFound;

      expect(await _stores(fake).fetchMine(), isNull);
    });

    test('fetchMine throws a StoreFailure on a server error', () async {
      final fake = FakeHttpClient()
        ..statusCode = 500
        ..body = '{"error":{"code":"INTERNAL","message":"x"}}';

      await expectLater(
        _stores(fake).fetchMine(),
        throwsA(isA<StoreFailure>()),
      );
    });

    test('analyze sends the links and maps the result', () async {
      final fake = FakeHttpClient()
        ..body = jsonEncode({
          'store': jsonDecode(_storeJson()),
          'analysisFailed': true,
        });

      final result = await _stores(fake).analyze(const [
        SourceLink(
          kind: SourceLinkKind.catchtable,
          url: 'https://app.catchtable.co.kr/x',
        ),
      ]);

      expect(result.analysisFailed, isTrue);
      final request = fake.requests.single;
      expect(request.method, 'POST');
      expect(request.url.path, '/stores/me/analyze');
      expect(_bodyOf(request), {
        'links': [
          {'kind': 'CATCHTABLE', 'url': 'https://app.catchtable.co.kr/x'},
        ],
      });
    });

    test('update sends only the fields that have a value (no nulls)', () async {
      final fake = FakeHttpClient()..body = _storeJson();

      await _stores(fake).update(
        const StoreEdit(
          name: '두그릇 라멘',
          seats: '',
          industry: IndustryCategory.fashion,
          regionSido: '부산광역시',
        ),
      );

      final request = fake.requests.single;
      expect(request.method, 'PATCH');
      expect(request.url.path, '/stores/me');
      expect(_bodyOf(request), {
        'name': '두그릇 라멘',
        'seats': '',
        'industry': 'FASHION',
        'regionSido': '부산광역시',
      });
    });

    test('update can send only a cover photo path', () async {
      final fake = FakeHttpClient()..body = _storeJson();

      await _stores(
        fake,
      ).update(const StoreEdit(coverPhotoPath: 'stores/u/a.jpg'));

      expect(_bodyOf(fake.requests.single), {
        'coverPhotoPath': 'stores/u/a.jpg',
      });
    });

    test('advance sends the step', () async {
      final fake = FakeHttpClient()..body = _storeJson(step: 'DRAFTS');

      final store = await _stores(fake).advance(StoreOnboardingStep.drafts);

      expect(store.onboardingStep, StoreOnboardingStep.drafts);
      expect(fake.requests.single.url.path, '/stores/me/onboarding-step');
      expect(_bodyOf(fake.requests.single), {'step': 'DRAFTS'});
    });

    test('a 409 becomes a StoreFailure flagged as a conflict', () async {
      final fake = FakeHttpClient()
        ..statusCode = 409
        ..body = '{"error":{"code":"CONFLICT","message":"x"}}';

      await expectLater(
        _stores(fake).publish(),
        throwsA(
          isA<StoreFailure>().having((e) => e.isConflict, 'conflict', true),
        ),
      );
    });

    test('setDefaultTerms sends the chosen terms', () async {
      final fake = FakeHttpClient()..body = _storeJson();

      await _stores(fake).setDefaultTerms(
        const OfferTermsInput(
          format: ContentFormat.reels,
          rewardType: RewardType.voucher,
          voucherName: '2인 식사권',
          voucherValue: 40000,
        ),
      );

      final body = _bodyOf(fake.requests.single);
      expect(body['format'], 'REELS');
      expect(body['rewardType'], 'VOUCHER');
      expect(body['voucherValue'], 40000);
    });
  });

  group('ApiContentDraftRepository', () {
    const draftJson = {
      'kind': 'REELS_SCRIPT',
      'bodyLabel': '촬영 순서',
      'body': '본문',
      'scenes': [
        {'label': '장면 1', 'text': '김이 오르는\n첫 숟가락', 'usesPhoto': true},
      ],
      'regenerationsLeftToday': 7,
    };

    test('fetchMine maps the drafts', () async {
      final fake = FakeHttpClient()..body = jsonEncode([draftJson]);

      final drafts = await _drafts(fake).fetchMine();

      expect(fake.requests.single.url.path, '/stores/me/content-drafts');
      expect(drafts.single.kind, ContentDraftKind.reelsScript);
      expect(drafts.single.scenes.single.usesPhoto, isTrue);
      expect(drafts.single.regenerationsLeftToday, 7);
    });

    test('regenerate posts the kind and maps a 429 to the limit', () async {
      final fake = FakeHttpClient()..body = jsonEncode(draftJson);
      final fresh = await _drafts(
        fake,
      ).regenerate(ContentDraftKind.reelsScript);
      expect(fresh.bodyLabel, '촬영 순서');
      expect(fake.requests.single.method, 'POST');
      expect(fake.requests.single.url.path, contains('REELS_SCRIPT'));

      final limited = FakeHttpClient()
        ..statusCode = 429
        ..body =
            '{"error":{"code":"RATE_LIMITED","message":"오늘은 더 만들 수 없어요."}}';
      await expectLater(
        _drafts(limited).regenerate(ContentDraftKind.blog),
        throwsA(isA<DraftRegenerationLimit>()),
      );
    });

    test('other failures become a ContentDraftFailure', () async {
      final fake = FakeHttpClient()
        ..statusCode = 500
        ..body = '{"error":{"code":"INTERNAL","message":"x"}}';

      await expectLater(
        _drafts(fake).fetchMine(),
        throwsA(isA<ContentDraftFailure>()),
      );
    });
  });
}
