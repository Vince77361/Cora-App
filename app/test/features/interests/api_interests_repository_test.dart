import 'dart:convert';

import 'package:cora/features/discovery/domain/discovery_target.dart';
import 'package:cora/features/interests/data/api_interests_repository.dart';
import 'package:cora/features/interests/domain/compare_result.dart';
import 'package:cora/features/interests/domain/interest_card.dart';
import 'package:cora/features/interests/domain/interests_repository.dart';
import 'package:cora/features/negotiation/domain/brand_usage_rights.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart'
    show ContentFormat;
import 'package:cora/features/principles/domain/principles.dart' show FeeBand;
import 'package:cora_api/api.dart' as api;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../support/fake_http_client.dart';

/// 경로마다 다른 본문으로 답하는 가짜 HTTP 클라이언트(서로 관심 정보는 요청이 여러 개다).
class _RoutedClient extends http.BaseClient {
  final bodies = <String, Object?>{};
  final failing = <String>{};
  final requests = <http.BaseRequest>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request);
    final path = request.url.path;
    final fail = failing.contains(path);
    return http.StreamedResponse(
      Stream.value(
        utf8.encode(
          fail
              ? '{"error":{"code":"NOT_FOUND","message":"x","details":null}}'
              : jsonEncode(bodies[path]),
        ),
      ),
      fail ? 404 : 200,
      headers: {'content-type': 'application/json'},
      request: request,
    );
  }
}

ApiInterestsRepository _repo(http.Client client) => ApiInterestsRepository(
  api.ApiClient(basePath: 'http://127.0.0.1:3000')..client = client,
);

const _brandCardJson = {
  'collaborationId': 'collab-1',
  'feeBand': 'W300K',
  'feeLabel': 300000,
  'hasProposal': false,
  'headline': '출근 전 30초, 오늘의 손목 루틴',
  'name': '서윤의 작은 취향',
  'photoUrl': 'https://x/s.jpg',
  'shortName': '서윤',
  'startFrom': '2026-11-16',
  'state': 'MUTUAL',
  'targetId': 'c1',
  'targetKind': 'CREATOR',
};

Map<String, Object?> _termsVersion({int version = 2}) => {
  'brandConfirmed': true,
  'creatorConfirmed': false,
  'fee': 300000,
  'format': 'REELS',
  'maxCash': 300000,
  'payoutDays': 7,
  'performance': null,
  'pieces': 1,
  'productProvided': true,
  'proposedBy': 'SYSTEM',
  'revisionScope': 'NONE',
  'startDate': '2026-11-16',
  'title': '제목',
  'usageRights': 'REPOST_ONLY',
  'version': version,
};

Map<String, Object?> _latest({bool myTurn = true, int version = 2}) => {
  'followers': null,
  'mine': false,
  'myTurn': myTurn,
  'needsInstagram': false,
  'notice': null,
  'reasons': <String>[],
  'terms': _termsVersion(version: version),
  'trialDays': 'D7',
};

Map<String, Object?> _collaboration({required String role}) => {
  'brandProgress': null,
  'campaign': {'brandName': '모아 스튜디오', 'headline': '아침 루틴', 'id': 'camp-1'},
  'campaignBudgetLeft': null,
  'canCancel': false,
  'canRequestCancel': false,
  'cancelRequest': null,
  'counterpart': role == 'COMMISSIONER'
      ? {'name': '서윤의 작은 취향', 'photoUrl': 'https://x/creator.jpg'}
      : {'name': '모아 스튜디오', 'photoUrl': 'https://x/brand.jpg'},
  'countingEndsAt': null,
  'currentViews': null,
  'earnedSoFar': null,
  'escrowAmount': 0,
  'expectedRefund': null,
  'id': 'collab-1',
  'kind': 'BRAND_CONTRACT',
  'nextAction': null,
  'payoutScheduledFor': null,
  'payoutStatus': 'NONE',
  'role': role,
  'securedAmount': null,
  'settlement': null,
  'stage': 'MATCHED',
  'steps': <Object?>[],
  'store': null,
  'submitDueAt': null,
  'submittedUrl': null,
  'terms': null,
  'title': null,
  'viewReportStatus': 'NONE',
};

void main() {
  test('fetchSaved asks for the saved tab and maps the cards', () async {
    final fake = FakeHttpClient()
      ..body = jsonEncode([
        _brandCardJson,
        {
          ..._brandCardJson,
          'collaborationId': null,
          'feeLabel': null,
          'startFrom': null,
          'state': 'HELD',
          'targetId': 'c3',
          'hasProposal': true,
        },
      ]);

    final cards = await _repo(fake).fetchSaved();

    expect(fake.requests.single.url.path, '/discovery/interests');
    expect(fake.requests.single.url.queryParameters['tab'], 'saved');
    final first = cards.first;
    expect(first.target, const DiscoveryTarget.creator('c1'));
    expect(first.state, InterestState.mutual);
    expect(first.fee, 300000);
    expect(first.feeBand, FeeBand.w300k);
    expect(first.startFrom, DateTime(2026, 11, 16));
    expect(first.collaborationId, 'collab-1');
    expect(first.shortName, '서윤');
    final held = cards.last;
    expect(held.state, InterestState.held);
    expect(held.fee, isNull);
    expect(held.startFrom, isNull);
    expect(held.hasProposal, isTrue);
    expect(held.collaborationId, isNull);
  });

  test('a creator-side card targets the campaign', () async {
    final fake = FakeHttpClient()
      ..body = jsonEncode([
        {
          ..._brandCardJson,
          'feeBand': null,
          'targetId': 'camp-1',
          'targetKind': 'CAMPAIGN',
          'state': 'WAITING',
        },
      ]);

    final card = (await _repo(fake).fetchSaved()).single;

    expect(card.target, const DiscoveryTarget.campaign('camp-1'));
    expect(card.state, InterestState.waiting);
    expect(card.feeBand, isNull);
  });

  test('fetchSaved turns any failure into an InterestsFailure', () async {
    final fake = FakeHttpClient()
      ..statusCode = 500
      ..body = '{"error":{"code":"INTERNAL","message":"x","details":null}}';

    await expectLater(
      _repo(fake).fetchSaved(),
      throwsA(isA<InterestsFailure>()),
    );
  });

  test('compare maps the two sides and the differing rows', () async {
    Map<String, Object?> side(String id, {String state = 'WAITING'}) => {
      'collaborationId': state == 'MUTUAL' ? 'collab-1' : null,
      'creatorId': id,
      'faceOk': id == 'c2',
      'fee': id == 'c1' ? 300000 : null,
      'feeBand': 'W400K',
      'format': 'REELS',
      'name': '이름 $id',
      'perfCap': id == 'c1' ? null : 60000,
      'photoUrl': null,
      'pieces': 1,
      'productProvided': true,
      'shortName': '짧 $id',
      'startDate': id == 'c1' ? '2026-11-16' : null,
      'state': state,
      'usageRights': id == 'c1' ? 'REPOST_ONLY' : 'ADS_TOO',
    };
    final fake = FakeHttpClient()
      ..body = jsonEncode({
        'differs': ['FEE', 'USAGE', 'FACE'],
        'sides': [side('c1', state: 'MUTUAL'), side('c2')],
      });

    final result = await _repo(fake).compare('c1', 'c2');

    final request = fake.requests.single;
    expect(request.url.path, '/discovery/compare');
    expect(request.url.queryParameters, {'a': 'c1', 'b': 'c2'});
    expect(result.differs, {CompareRow.fee, CompareRow.usage, CompareRow.face});
    final left = result.sides.first;
    expect(left.state, InterestState.mutual);
    expect(left.collaborationId, 'collab-1');
    expect(left.format, ContentFormat.reels);
    expect(left.fee, 300000);
    expect(left.startDate, DateTime(2026, 11, 16));
    expect(left.usageRights, BrandUsageRights.repostOnly);
    expect(left.faceOk, isFalse);
    final right = result.sides.last;
    expect(right.fee, isNull);
    expect(right.feeBand, FeeBand.w400k);
    expect(right.perfCap, 60000);
    expect(right.usageRights, BrandUsageRights.adsToo);
    expect(right.faceOk, isTrue);
    expect(right.startDate, isNull);
  });

  test('compare fails when the server does not return two sides', () async {
    final fake = FakeHttpClient()
      ..body = jsonEncode({'differs': <String>[], 'sides': <Object?>[]});

    await expectLater(
      _repo(fake).compare('c1', 'c2'),
      throwsA(isA<InterestsFailure>()),
    );
  });

  group('fetchMatch', () {
    test('reads a brand-side match from the collaboration, the latest terms '
        'and the brand profile', () async {
      final client = _RoutedClient()
        ..bodies['/collaborations/collab-1'] = _collaboration(
          role: 'COMMISSIONER',
        )
        ..bodies['/collaborations/collab-1/terms/latest'] = _latest()
        ..bodies['/brands/me'] = {
          'industry': 'FASHION',
          'name': '모아 스튜디오',
          'photoUrl': 'https://x/brand-me.jpg',
          'tagline': '느린 결, 일상의 주얼리',
          'userId': 'u1',
        };

      final info = await _repo(client).fetchMatch('collab-1');

      expect(info.isBrand, isTrue);
      expect(info.brandName, '모아 스튜디오');
      expect(info.brandTagline, '느린 결, 일상의 주얼리');
      expect(info.brandPhotoUrl, 'https://x/brand-me.jpg');
      expect(info.creatorName, '서윤의 작은 취향');
      expect(info.creatorPhotoUrl, 'https://x/creator.jpg');
      expect(info.pendingProposals, 1);
      expect(info.baseVersion, 2);
    });

    test(
      'a latest version I already confirmed counts as zero proposals',
      () async {
        final client = _RoutedClient()
          ..bodies['/collaborations/collab-1'] = _collaboration(
            role: 'COMMISSIONER',
          )
          ..bodies['/collaborations/collab-1/terms/latest'] = _latest(
            myTurn: false,
            version: 3,
          )
          ..bodies['/brands/me'] = {
            'industry': 'FASHION',
            'name': '모아 스튜디오',
            'photoUrl': null,
            'tagline': null,
            'userId': 'u1',
          };

        final info = await _repo(client).fetchMatch('collab-1');

        expect(info.pendingProposals, 0);
        expect(info.baseVersion, 3);
        expect(info.brandTagline, isNull);
      },
    );

    test('reads a creator-side match with the tagline from the campaign '
        'detail', () async {
      final client = _RoutedClient()
        ..bodies['/collaborations/collab-1'] = _collaboration(role: 'CREATOR')
        ..bodies['/collaborations/collab-1/terms/latest'] = _latest()
        ..bodies['/creators/me'] = {
          'cardHeadline': null,
          'cardPhotoUrl': null,
          'contentFocus': null,
          'displayName': '서윤의 작은 취향',
          'followers': null,
          'instagramConnected': false,
          'instagramHandle': null,
          'photoUrl': 'https://x/me.jpg',
          'regionSido': '서울',
          'regionSigungu': null,
          'userId': 'u2',
        }
        ..bodies['/campaigns/camp-1/detail'] = {
          'brandName': '모아 스튜디오',
          'brandTagline': '느린 결, 일상의 주얼리',
          'campaignId': 'camp-1',
          'fee': 300000,
          'headline': '아침 루틴',
          'kind': 'CAMPAIGN',
          'mustInclude': <String>[],
          'myDecision': null,
          'notRequired': <String>[],
          'overlapCount': 0,
          'photoUrl': null,
          'productProvided': true,
          'reasons': <String>[],
          'startFrom': '2026-11-20',
          'tags': <String>[],
          'trialDays': 'D7',
        };

      final info = await _repo(client).fetchMatch('collab-1');

      expect(info.isBrand, isFalse);
      expect(info.brandName, '모아 스튜디오');
      expect(info.brandTagline, '느린 결, 일상의 주얼리');
      expect(info.brandPhotoUrl, 'https://x/brand.jpg');
      expect(info.creatorName, '서윤의 작은 취향');
      expect(info.creatorPhotoUrl, 'https://x/me.jpg');
    });

    test('a creator-side match still opens when the campaign detail cannot be '
        'read', () async {
      final client = _RoutedClient()
        ..bodies['/collaborations/collab-1'] = _collaboration(role: 'CREATOR')
        ..bodies['/collaborations/collab-1/terms/latest'] = _latest()
        ..bodies['/creators/me'] = {
          'cardHeadline': null,
          'cardPhotoUrl': null,
          'contentFocus': null,
          'displayName': '서윤의 작은 취향',
          'followers': null,
          'instagramConnected': false,
          'instagramHandle': null,
          'photoUrl': null,
          'regionSido': '서울',
          'regionSigungu': null,
          'userId': 'u2',
        };
      // 캠페인 상세는 경로가 없어 실패한다.
      final info = await _repo(client).fetchMatch('collab-1');

      expect(info.brandTagline, isNull);
      expect(info.brandName, '모아 스튜디오');
    });

    test('a failed read becomes an InterestsFailure', () async {
      final client = _RoutedClient()
        ..bodies['/collaborations/collab-1'] = _collaboration(
          role: 'COMMISSIONER',
        )
        ..failing.add('/collaborations/collab-1/terms/latest');

      await expectLater(
        _repo(client).fetchMatch('collab-1'),
        throwsA(isA<InterestsFailure>()),
      );
    });
  });
}
