import 'dart:convert';

import 'package:cora/core/ui/swipe_deck/swipe_physics.dart' show SwipeOutcome;
import 'package:cora/features/discovery/domain/pass_reason.dart';
import 'package:cora/features/store_discover/data/api_store_discover_repository.dart';
import 'package:cora/features/store_discover/domain/store_discover_repository.dart';
import 'package:cora_api/api.dart' as api;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../support/fake_http_client.dart';

ApiStoreDiscoverRepository _repo(FakeHttpClient fake) =>
    ApiStoreDiscoverRepository(
      api.ApiClient(basePath: 'http://127.0.0.1:3000')..client = fake,
    );

Map<String, dynamic> _body(http.BaseRequest request) =>
    jsonDecode((request as http.Request).body) as Map<String, dynamic>;

Map<String, Object?> _post(int position) => {
  'id': 'p$position',
  'position': position,
  'source': 'GALLERY',
  'kind': 'PHOTO',
  'photoUrl': 'https://x/p$position.jpg',
  'mediaUrl': 'https://x/p$position.jpg',
  'caption': '한 줄 $position',
  'instagramMediaId': null,
};

void main() {
  test('fetchCards maps the cards with their posts', () async {
    final fake = FakeHttpClient()
      ..body = jsonEncode({
        'day': '2026-11-19',
        'total': 5,
        'cards': [
          {
            'creatorId': 'c1',
            'displayName': '하루 한 컵',
            'contentFocus': '리빙 릴스',
            'followers': 640,
            'headline': '한 줄 1',
            'photoUrl': 'https://x/p1.jpg',
            'posts': [_post(1), _post(2)],
            'tags': ['리빙'],
          },
        ],
      });

    final result = await _repo(fake).fetchCards();

    expect(fake.requests.single.url.path, '/recommendations/store-creators');
    expect(result.total, 5);
    final card = result.cards.single;
    expect(card.creatorId, 'c1');
    expect(card.contentFocus, '리빙 릴스');
    expect(card.followers, 640);
    expect(card.posts.map((p) => p.caption), ['한 줄 1', '한 줄 2']);
    expect(card.posts.first.photoUrl, 'https://x/p1.jpg');
    expect(card.tags, ['리빙']);
  });

  test('decide sends the decision for a creator without a note', () async {
    final fake = FakeHttpClient()
      ..body = jsonEncode({
        'matched': false,
        'collaborationId': null,
        'conversationId': null,
        'decision': 'LIKE',
      });
    final repo = _repo(fake);

    await repo.decide('c1', SwipeOutcome.like);
    await repo.decide('c2', SwipeOutcome.hold);
    await repo.decide('c3', SwipeOutcome.pass);

    expect(fake.requests.map((r) => r.method).toSet(), {'PUT'});
    expect(fake.requests.first.url.path, '/discovery/decisions');
    final sent = [for (final r in fake.requests) _body(r)];
    expect(sent.map((b) => b['decision']), ['LIKE', 'HOLD', 'PASS']);
    expect(sent.every((b) => b['targetKind'] == 'CREATOR'), isTrue);
    expect(sent.map((b) => b['targetId']), ['c1', 'c2', 'c3']);
    // 사장님 하트에는 글도 제안도 붙이지 않는다(서버가 400으로 막는다).
    expect(
      sent.every((b) => !b.containsKey('note') || b['note'] == null),
      isTrue,
    );
    expect(
      sent.every((b) => !b.containsKey('proposal') || b['proposal'] == null),
      isTrue,
    );
  });

  test('setPassReason sends the reason for the creator', () async {
    final fake = FakeHttpClient()..body = '';
    await _repo(fake).setPassReason('c1', PassReason.region);

    expect(fake.requests.single.url.path, '/discovery/decisions/pass-reason');
    expect(_body(fake.requests.single), {
      'reason': 'REGION',
      'targetId': 'c1',
      'targetKind': 'CREATOR',
    });
  });

  test(
    'undoLast returns the creator id, or null when nothing can be undone',
    () async {
      final fake = FakeHttpClient()
        ..body = jsonEncode({'targetId': 'c1', 'targetKind': 'CREATOR'});
      expect(await _repo(fake).undoLast(), 'c1');
      expect(fake.requests.single.method, 'DELETE');
      expect(fake.requests.single.url.path, '/discovery/decisions/last');

      // 되돌릴 것이 없으면 본문 없는 200이다.
      final empty = FakeHttpClient()..body = '';
      expect(await _repo(empty).undoLast(), isNull);

      // 서로 관심이면 서버가 409로 거절한다.
      final conflict = FakeHttpClient()
        ..statusCode = 409
        ..body =
            '{"error":{"code":"CONFLICT","message":"되돌릴 수 없어요.","details":null}}';
      expect(await _repo(conflict).undoLast(), isNull);
    },
  );

  test('network failures become StoreDiscoverFailure', () async {
    final fake = FakeHttpClient()
      ..statusCode = 500
      ..body = '{"error":{"code":"X","message":"x","details":null}}';

    await expectLater(
      _repo(fake).fetchCards(),
      throwsA(isA<StoreDiscoverFailure>()),
    );
    await expectLater(
      _repo(fake).decide('c1', SwipeOutcome.like),
      throwsA(isA<StoreDiscoverFailure>()),
    );
  });
}
