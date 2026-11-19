import 'dart:convert';

import 'package:cora/features/applicant_picks/data/api_applicant_picks_repository.dart';
import 'package:cora/features/applicant_picks/domain/applicant_pick.dart';
import 'package:cora/features/applicant_picks/domain/applicant_picks_repository.dart';
import 'package:cora_api/api.dart' as api;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_http_client.dart';

ApiApplicantPicksRepository _repo(FakeHttpClient fake) =>
    ApiApplicantPicksRepository(
      api.ApiClient(basePath: 'http://127.0.0.1:3000')..client = fake,
    );

Map<String, dynamic> _creator({
  required bool instagramConnected,
  int? followers,
}) => {
  'userId': 'u1',
  'displayName': '하루 한 컵',
  'contentFocus': '리빙 릴스',
  'photoUrl': null,
  'regionSido': '서울특별시',
  'regionSigungu': '성동구',
  'instagramConnected': instagramConnected,
  'followers': followers,
};

void main() {
  test(
    'reads the picks and keeps followers only for connected creators',
    () async {
      final fake = FakeHttpClient()
        ..body = jsonEncode({
          'source': 'APPLICANTS',
          'totalNew': 5,
          'items': [
            {
              'applicationId': 'a1',
              'appliedAt': '2026-11-11T00:01:00.000Z',
              'creator': _creator(instagramConnected: true, followers: 640),
              'pitch': '한 줄',
              'reasons': ['같은 구·군'],
            },
            {
              'applicationId': 'a2',
              'appliedAt': '2026-11-11T00:02:00.000Z',
              // 연동을 끊은 크리에이터의 오래된 팔로워 값은 보이지 않는다.
              'creator': _creator(instagramConnected: false, followers: 900),
              'pitch': null,
              'reasons': [],
            },
          ],
        });

      final picks = await _repo(fake).fetchPicks();

      expect(
        fake.requests.single.url.path,
        '/stores/me/applications/recommended',
      );
      expect(picks.source, PicksSource.applicants);
      expect(picks.totalNew, 5);
      expect(picks.items.first.applicationId, 'a1');
      expect(picks.items.first.appliedAt, DateTime.utc(2026, 11, 11, 0, 1));
      expect(picks.items.first.creator.followers, 640);
      expect(picks.items.first.reasons, ['같은 구·군']);
      expect(picks.items.last.creator.followers, isNull);
      expect(picks.items.last.pitch, isNull);
    },
  );

  test(
    'keeps picks taken from all creators with no application or applied time',
    () async {
      final fake = FakeHttpClient()
        ..body = jsonEncode({
          'source': 'ALL',
          'totalNew': 0,
          'items': [
            {
              'applicationId': null,
              'appliedAt': null,
              'creator': _creator(instagramConnected: true, followers: 640),
              'pitch': null,
              'reasons': [],
            },
            {
              'applicationId': null,
              'appliedAt': null,
              'creator': _creator(instagramConnected: false, followers: 900),
              'pitch': null,
              'reasons': [],
            },
          ],
        });

      final picks = await _repo(fake).fetchPicks();

      expect(picks.source, PicksSource.all);
      expect(picks.totalNew, 0);
      expect(picks.items, hasLength(2));
      expect(picks.items.first.applicationId, isNull);
      expect(picks.items.first.appliedAt, isNull);
      expect(picks.items.first.creator.followers, 640);
      expect(picks.items.last.creator.followers, isNull);
    },
  );

  test('maps any failure to a plain failure', () async {
    final fake = FakeHttpClient()
      ..statusCode = 404
      ..body = '{"error":{"code":"NOT_FOUND","message":"없어요","details":null}}';

    await expectLater(
      _repo(fake).fetchPicks(),
      throwsA(isA<ApplicantPicksFailure>()),
    );
  });
}
