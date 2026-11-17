import 'dart:convert';

import 'package:cora/features/discovery/domain/discovery_card.dart'
    show MatchReason;
import 'package:cora/features/negotiation/data/api_negotiation_repository.dart';
import 'package:cora/features/negotiation/domain/brand_usage_rights.dart';
import 'package:cora/features/negotiation/domain/negotiation_repository.dart';
import 'package:cora/features/negotiation/domain/terms_version.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart'
    show ContentFormat, ViewPay;
import 'package:cora_api/api.dart' as api;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../support/fake_http_client.dart';

ApiNegotiationRepository _repo(FakeHttpClient fake) => ApiNegotiationRepository(
  api.ApiClient(basePath: 'http://127.0.0.1:3000')..client = fake,
);

Map<String, Object?> _version({Map<String, Object?>? performance}) => {
  'brandConfirmed': false,
  'changedFields': <String>[],
  'createdAt': '2026-11-11T03:00:00.000Z',
  'creatorConfirmed': true,
  'fee': 300000,
  'format': 'REELS',
  'maxCash': 360000,
  'payoutDays': 14,
  'performance': performance,
  'pieces': 2,
  'previousMaxCash': null,
  'productProvided': true,
  'proposedBy': 'CREATOR',
  'revisionScope': 'DRAFT_2',
  'startDate': '2026-11-16',
  'title': '출근 전 30초, 오늘의 손목 루틴',
  'usageRights': 'ADS_TOO',
  'version': 3,
};

Map<String, Object?> _latest({
  Map<String, Object?>? performance,
  Object? followers = 8200,
}) => {
  'followers': followers,
  'mine': true,
  'myTurn': false,
  'needsInstagram': false,
  'notice': '얼굴 출연과 제품 설명문 낭독은 진행하지 않아요.',
  'reasons': ['FIELD', 'FEE', 'TRIAL'],
  'fields': ['리빙·소품', '패션'],
  'terms': _version(performance: performance),
  'trialDays': 'D7',
};

void main() {
  test('fetchLatest maps the latest version and my situation', () async {
    final fake = FakeHttpClient()
      ..body = jsonEncode(
        _latest(performance: {'cap': 60000, 'ratePer1000': 2000}),
      );

    final latest = await _repo(fake).fetchLatest('col-1');

    expect(fake.requests.single.url.path, '/collaborations/col-1/terms/latest');
    expect(latest.mine, isTrue);
    expect(latest.myTurn, isFalse);
    expect(latest.needsInstagram, isFalse);
    expect(latest.notice, '얼굴 출연과 제품 설명문 낭독은 진행하지 않아요.');
    expect(latest.reasons, [
      MatchReason.field,
      MatchReason.fee,
      MatchReason.trial,
    ]);
    expect(latest.fields, ['리빙·소품', '패션']);
    expect(latest.followers, 8200);
    final t = latest.terms;
    expect(t.version, 3);
    expect(t.title, '출근 전 30초, 오늘의 손목 루틴');
    expect(t.fee, 300000);
    expect(t.maxCash, 360000);
    expect(t.productProvided, isTrue);
    expect(t.performance, const ViewPay(ratePerThousand: 2000, cap: 60000));
    expect((t.format, t.pieces), (ContentFormat.reels, 2));
    expect(t.startDate, DateTime(2026, 11, 16));
    expect(t.revisionScope, RevisionScope.draftTwice);
    expect(t.usageRights, BrandUsageRights.adsToo);
    expect(t.payoutDays, 14);
    expect((t.brandConfirmed, t.creatorConfirmed), (false, true));
    expect(t.agreed, isFalse);
    expect(t.proposedBy, TermsProposer.creator);
  });

  test(
    'fetchLatest keeps a missing performance and follower count null',
    () async {
      final fake = FakeHttpClient()
        ..body = jsonEncode(_latest(followers: null));

      final latest = await _repo(fake).fetchLatest('col-1');

      expect(latest.terms.performance, isNull);
      expect(latest.followers, isNull);
    },
  );

  test('every revision scope, usage right and proposer maps', () async {
    for (final (wire, expected) in [
      ('NONE', RevisionScope.none),
      ('GUIDE_1', RevisionScope.guideOnce),
      ('DRAFT_1', RevisionScope.draftOnce),
      ('DRAFT_2', RevisionScope.draftTwice),
    ]) {
      final fake = FakeHttpClient()
        ..body = jsonEncode({
          ..._latest(),
          'terms': {..._version(), 'revisionScope': wire},
        });
      expect(
        (await _repo(fake).fetchLatest('c')).terms.revisionScope,
        expected,
      );
    }
    for (final (wire, expected) in [
      ('REPOST_ONLY', BrandUsageRights.repostOnly),
      ('ADS_TOO', BrandUsageRights.adsToo),
      ('NONE', BrandUsageRights.none),
    ]) {
      final fake = FakeHttpClient()
        ..body = jsonEncode({
          ..._latest(),
          'terms': {..._version(), 'usageRights': wire},
        });
      expect((await _repo(fake).fetchLatest('c')).terms.usageRights, expected);
    }
    for (final (wire, expected) in [
      ('BRAND', TermsProposer.brand),
      ('CREATOR', TermsProposer.creator),
      ('SYSTEM', TermsProposer.system),
    ]) {
      final fake = FakeHttpClient()
        ..body = jsonEncode({
          ..._latest(),
          'terms': {..._version(), 'proposedBy': wire},
        });
      expect((await _repo(fake).fetchLatest('c')).terms.proposedBy, expected);
    }
  });

  test('a failed read is a NegotiationFailure', () async {
    final fake = FakeHttpClient()
      ..statusCode = 404
      ..body = '{"error":{"code":"NOT_FOUND","message":"x","details":null}}';

    await expectLater(
      _repo(fake).fetchLatest('col-1'),
      throwsA(isA<NegotiationFailure>()),
    );
  });

  test('confirm posts the version number in the path', () async {
    final fake = FakeHttpClient()
      ..statusCode = 201
      ..body = jsonEncode(_version());

    await _repo(fake).confirm('col-1', 3);

    final request = fake.requests.single;
    expect(request.method, 'POST');
    expect(request.url.path, '/collaborations/col-1/terms/3/confirm');
  });

  test('a stale version carries the latest version number', () async {
    final fake = FakeHttpClient()
      ..statusCode = 409
      ..body = jsonEncode({
        'error': {
          'code': 'STALE_VERSION',
          'message': '이전 판본이라 수락할 수 없어요.',
          'details': {'latestVersion': 4},
        },
      });

    await expectLater(
      _repo(fake).confirm('col-1', 3),
      throwsA(
        isA<NegotiationStale>().having((e) => e.latestVersion, 'latest', 4),
      ),
    );
  });

  test(
    'a conflict with a server message is rejected with that message',
    () async {
      final fake = FakeHttpClient()
        ..statusCode = 409
        ..body = jsonEncode({
          'error': {
            'code': 'CONFLICT',
            'message': '인스타그램을 연동하면 수락할 수 있어요.',
            'details': null,
          },
        });

      await expectLater(
        _repo(fake).confirm('col-1', 3),
        throwsA(
          isA<NegotiationRejected>().having(
            (e) => e.message,
            'message',
            '인스타그램을 연동하면 수락할 수 있어요.',
          ),
        ),
      );
    },
  );

  test('a server error shows no server text', () async {
    final fake = FakeHttpClient()
      ..statusCode = 500
      ..body =
          '{"error":{"code":"INTERNAL","message":"db down","details":null}}';

    await expectLater(
      _repo(fake).confirm('col-1', 3),
      throwsA(isA<NegotiationFailure>()),
    );
  });

  test('drop posts the reason to the collaboration drop endpoint', () async {
    const wire = {
      DropReason.schedule: 'SCHEDULE',
      DropReason.budget: 'BUDGET',
      DropReason.direction: 'DIRECTION',
      DropReason.other: 'OTHER',
    };
    for (final entry in wire.entries) {
      // 응답 본문은 쓰지 않는다(빈 본문이면 생성 클라이언트가 읽지 않는다).
      final fake = FakeHttpClient()
        ..statusCode = 200
        ..body = '';

      await _repo(fake).drop('col-1', entry.key);

      final request = fake.requests.single as http.Request;
      expect(request.method, 'POST');
      expect(request.url.path, '/collaborations/col-1/drop');
      expect(jsonDecode(request.body), {'reason': entry.value});
    }
  });

  test('a refused drop carries the server message', () async {
    final fake = FakeHttpClient()
      ..statusCode = 409
      ..body = jsonEncode({
        'error': {
          'code': 'CONFLICT',
          'message': '지금은 협의를 그만둘 수 없어요.',
          'details': null,
        },
      });

    await expectLater(
      _repo(fake).drop('col-1', DropReason.budget),
      throwsA(
        isA<NegotiationRejected>().having(
          (e) => e.message,
          'message',
          '지금은 협의를 그만둘 수 없어요.',
        ),
      ),
    );
  });

  test('a failed drop shows no server text', () async {
    final fake = FakeHttpClient()
      ..statusCode = 500
      ..body =
          '{"error":{"code":"INTERNAL","message":"db down","details":null}}';

    await expectLater(
      _repo(fake).drop('col-1', DropReason.other),
      throwsA(isA<NegotiationFailure>()),
    );
  });

  group('history and proposing', () {
    Map<String, Object?> history({String agreement = 'WAITING_BRAND'}) => {
      'agreement': agreement,
      'editable': true,
      'versions': [
        {
          ..._version(performance: {'cap': 60000, 'ratePer1000': 2000}),
          'version': 2,
          'changedFields': ['FEE', 'START_DATE', 'PERFORMANCE'],
          'previousMaxCash': 300000,
        },
        {..._version(), 'version': 1, 'proposedBy': 'SYSTEM'},
      ],
    };

    test('fetchHistory maps the versions, the changed fields and the '
        'agreement', () async {
      final fake = FakeHttpClient()..body = jsonEncode(history());

      final h = await _repo(fake).fetchHistory('col-1');

      expect(fake.requests.single.url.path, '/collaborations/col-1/terms');
      expect(fake.requests.single.method, 'GET');
      expect(h.versions.map((v) => v.version), [2, 1]);
      expect(h.latest.changedFields, [
        TermsField.fee,
        TermsField.startDate,
        TermsField.performance,
      ]);
      expect(h.latest.previousMaxCash, 300000);
      expect(h.latest.createdAt, DateTime.utc(2026, 11, 11, 3));
      expect(h.previous!.version, 1);
      expect(h.previous!.proposedBy, TermsProposer.system);
      expect(h.agreement, TermsAgreement.waitingBrand);
      expect(h.editable, isTrue);
    });

    test('every agreement state maps', () async {
      for (final (wire, expected) in [
        ('NONE', TermsAgreement.none),
        ('WAITING_BRAND', TermsAgreement.waitingBrand),
        ('WAITING_CREATOR', TermsAgreement.waitingCreator),
        ('AGREED', TermsAgreement.agreed),
      ]) {
        final fake = FakeHttpClient()
          ..body = jsonEncode(history(agreement: wire));
        expect((await _repo(fake).fetchHistory('c')).agreement, expected);
      }
    });

    test('fetchHistory fails on a server error', () async {
      final fake = FakeHttpClient()
        ..statusCode = 500
        ..body = '{}';

      await expectLater(
        _repo(fake).fetchHistory('col-1'),
        throwsA(isA<NegotiationFailure>()),
      );
    });

    TermsChanges changes({ViewPay? performance}) => TermsChanges(
      title: '새 제목',
      fee: 350000,
      productProvided: false,
      performance: performance,
      startDate: DateTime(2026, 11, 23),
      format: ContentFormat.cardNews,
      pieces: 2,
      revisionScope: RevisionScope.draftOnce,
      usageRights: BrandUsageRights.adsToo,
      payoutDays: 14,
    );

    test('propose sends all nine fields with the base version', () async {
      final fake = FakeHttpClient()
        ..statusCode = 201
        ..body = jsonEncode(_version());

      final made = await _repo(fake).propose(
        'col-1',
        2,
        changes(performance: const ViewPay(ratePerThousand: 2000, cap: 60000)),
      );

      final request = fake.requests.single as http.Request;
      expect(request.method, 'POST');
      expect(request.url.path, '/collaborations/col-1/terms');
      expect(jsonDecode(request.body), {
        'baseVersion': 2,
        'title': '새 제목',
        'fee': 350000,
        'productProvided': false,
        'performance': {'cap': 60000, 'ratePer1000': 2000},
        'startDate': '2026-11-23',
        'format': 'CARD_NEWS',
        'pieces': 2,
        'revisionScope': 'DRAFT_1',
        'usageRights': 'ADS_TOO',
        'payoutDays': 14,
      });
      expect(made.version, 3);
    });

    test(
      'propose sends performance null only when it is switched off',
      () async {
        final fake = FakeHttpClient()
          ..statusCode = 201
          ..body = jsonEncode(_version());

        await _repo(fake).propose('col-1', 2, changes());

        final body = jsonDecode((fake.requests.single as http.Request).body);
        expect(body, containsPair('performance', null));
        expect(body['title'], '새 제목');
      },
    );

    test('propose maps a stale version with the latest number', () async {
      final fake = FakeHttpClient()
        ..statusCode = 409
        ..body = jsonEncode({
          'error': {
            'code': 'STALE_VERSION',
            'message': '상대가 먼저 새 조건을 제안했어요.',
            'details': {'latestVersion': 4},
          },
        });

      await expectLater(
        _repo(fake).propose('col-1', 2, changes()),
        throwsA(
          isA<NegotiationStale>().having((e) => e.latestVersion, 'latest', 4),
        ),
      );
    });

    test('propose keeps the server message of other conflicts and bad '
        'requests', () async {
      for (final (status, code, message) in [
        (409, 'CONFLICT', '결제가 진행 중이라 조건을 바꿀 수 없어요.'),
        (400, 'VALIDATION_FAILED', '바꾼 조건이 없어요.'),
      ]) {
        final fake = FakeHttpClient()
          ..statusCode = status
          ..body = jsonEncode({
            'error': {'code': code, 'message': message, 'details': null},
          });

        await expectLater(
          _repo(fake).propose('col-1', 2, changes()),
          throwsA(
            isA<NegotiationRejected>().having(
              (e) => e.message,
              'message',
              message,
            ),
          ),
        );
      }
    });

    test('propose hides a server error body', () async {
      final fake = FakeHttpClient()
        ..statusCode = 500
        ..body =
            '{"error":{"code":"INTERNAL","message":"db 비밀","details":null}}';

      await expectLater(
        _repo(fake).propose('col-1', 2, changes()),
        throwsA(isA<NegotiationFailure>()),
      );
    });
  });
}
