import 'dart:convert';

import 'package:cora/features/store_interests/data/api_store_interests_repository.dart';
import 'package:cora/features/store_interests/domain/store_interests_repository.dart';
import 'package:cora_api/api.dart' as api;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_http_client.dart';

ApiStoreInterestsRepository _repo(FakeHttpClient fake) =>
    ApiStoreInterestsRepository(
      api.ApiClient(basePath: 'http://127.0.0.1:3000')..client = fake,
    );

Map<String, Object?> _row(String id, {bool mutual = false}) => {
  'creatorId': id,
  'name': '서윤의 작은 취향',
  'shortName': '서윤',
  'contentFocus': '일상형 릴스',
  'followers': 3100,
  'photoUrl': 'https://x/$id.jpg',
  'mutual': mutual,
};

void main() {
  test('fetchSaved reads the saved tab and maps the rows', () async {
    final fake = FakeHttpClient()..body = jsonEncode([_row('c1')]);

    final rows = await _repo(fake).fetchSaved();

    final request = fake.requests.single;
    expect(request.url.path, '/discovery/store-interests');
    expect(request.url.queryParameters['tab'], 'saved');
    expect(rows.single.creatorId, 'c1');
    expect(rows.single.name, '서윤의 작은 취향');
    expect(rows.single.shortName, '서윤');
    expect(rows.single.contentFocus, '일상형 릴스');
    expect(rows.single.followers, 3100);
    expect(rows.single.photoUrl, 'https://x/c1.jpg');
    expect(rows.single.mutual, isFalse);
  });

  test('fetchSent reads the sent tab and keeps the mutual flag', () async {
    final fake = FakeHttpClient()
      ..body = jsonEncode([_row('c1', mutual: true), _row('c2')]);

    final rows = await _repo(fake).fetchSent();

    expect(fake.requests.single.url.queryParameters['tab'], 'sent');
    expect(rows.map((r) => r.mutual), [true, false]);
  });

  test('a failed response becomes a StoreInterestsFailure', () async {
    final fake = FakeHttpClient()..statusCode = 500;

    await expectLater(
      _repo(fake).fetchSaved(),
      throwsA(isA<StoreInterestsFailure>()),
    );
  });
}
