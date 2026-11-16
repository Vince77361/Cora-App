import 'dart:convert';

import 'package:cora/core/ui/swipe_deck/swipe_physics.dart' show SwipeOutcome;
import 'package:cora/features/discovery/data/api_discovery_repository.dart';
import 'package:cora/features/discovery/domain/discovery_card.dart';
import 'package:cora/features/discovery/domain/discovery_repository.dart';
import 'package:cora/features/discovery/domain/discovery_target.dart';
import 'package:cora/features/discovery/domain/pass_reason.dart';
import 'package:cora/features/discovery/domain/reward_proposal.dart';
import 'package:cora/features/principles/domain/principles.dart' show FeeBand;
import 'package:cora_api/api.dart' as api;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../support/fake_http_client.dart';

ApiDiscoveryRepository _repo(FakeHttpClient fake) => ApiDiscoveryRepository(
  api.ApiClient(basePath: 'http://127.0.0.1:3000')..client = fake,
);

const _creatorCard = {
  'creatorId': 'c1',
  'displayName': '서윤의 작은 취향',
  'feeBand': 'W300K',
  'headline': '출근 전 30초, 오늘의 손목 루틴',
  'instagramHandle': null,
  'photoUrl': 'https://x/y.jpg',
  'reasons': ['FIELD', 'TRIAL'],
  'tags': ['얼굴출연없음', '소품'],
  'theyLikedMe': true,
};

void main() {
  test('fetchCreatorCards maps cards and the total', () async {
    final fake = FakeHttpClient()
      ..body = jsonEncode({
        'day': '2026-11-16',
        'total': 3,
        'cards': [_creatorCard],
      });

    final result = await _repo(fake).fetchCreatorCards();

    expect(fake.requests.single.url.path, '/recommendations/creators');
    expect(result.total, 3);
    final card = result.cards.single;
    expect(card.creatorId, 'c1');
    expect(card.feeBand, FeeBand.w300k);
    expect(card.tags, ['얼굴출연없음', '소품']);
    expect(card.reasons, [MatchReason.field, MatchReason.trial]);
    expect(card.theyLikedMe, isTrue);
  });

  test(
    'fetchCampaignCards reads the card kind and keeps the shared fields',
    () async {
      final fake = FakeHttpClient()
        ..body = jsonEncode({
          'day': '2026-11-16',
          'total': 1,
          'cards': [
            {
              'kind': 'CAMPAIGN',
              'campaignId': 'camp-1',
              'brandName': '느린 결',
              'brandTagline': '일상의 주얼리',
              'headline': '아침 루틴',
              'fee': 300000,
              'productProvided': true,
              'photoUrl': null,
              'reasons': ['FEE'],
              'tags': ['릴스'],
            },
          ],
        });

      final result = await _repo(fake).fetchCampaignCards();

      final card = result.cards.single as CampaignCard;
      expect(card.campaignId, 'camp-1');
      expect(card.fee, 300000);
      expect(card.productProvided, isTrue);
      expect(card.reasons, [MatchReason.fee]);
    },
  );

  test('fetchPreviewCards maps the read-only cards', () async {
    final fake = FakeHttpClient()
      ..body = jsonEncode({
        'total': 1,
        'cards': [
          {
            'creatorId': 'c1',
            'displayName': '서윤',
            'feeBand': 'W500K_PLUS',
            'headline': null,
            'photoUrl': null,
            'tags': ['소품'],
          },
        ],
      });

    final cards = await _repo(fake).fetchPreviewCards();

    expect(fake.requests.single.url.path, '/recommendations/preview');
    expect(cards.single.feeBand, FeeBand.w500kPlus);
    expect(cards.single.headline, isNull);
  });

  test(
    'decide sends the target, the decision, the note and the proposal',
    () async {
      final fake = FakeHttpClient()
        ..body = jsonEncode({
          'decision': 'LIKE',
          'matched': true,
          'collaborationId': 'collab-1',
        });

      final result = await _repo(fake).decide(
        const DiscoveryTarget.creator('c1'),
        SwipeOutcome.like,
        note: '좋아요',
        proposal: const RewardProposal(
          fee: 300000,
          productProvided: true,
          performance: (ratePer1000: 2000, cap: 100000),
        ),
      );

      final request = fake.requests.single as http.Request;
      expect(request.method, 'PUT');
      expect(request.url.path, '/discovery/decisions');
      expect(jsonDecode(request.body), {
        'decision': 'LIKE',
        'note': '좋아요',
        'proposal': {
          'fee': 300000,
          'performance': {'cap': 100000, 'ratePer1000': 2000},
          'productProvided': true,
        },
        'targetId': 'c1',
        'targetKind': 'CREATOR',
      });
      expect(result.matched, isTrue);
      expect(result.collaborationId, 'collab-1');
    },
  );

  test('decide maps pass and hold and the campaign target', () async {
    for (final (outcome, wire) in [
      (SwipeOutcome.pass, 'PASS'),
      (SwipeOutcome.hold, 'HOLD'),
    ]) {
      final fake = FakeHttpClient()
        ..body = jsonEncode({
          'decision': wire,
          'matched': false,
          'collaborationId': null,
        });
      await _repo(
        fake,
      ).decide(const DiscoveryTarget.campaign('camp-1'), outcome);
      final body = jsonDecode((fake.requests.single as http.Request).body);
      expect(body['decision'], wire);
      expect(body['targetKind'], 'CAMPAIGN');
      expect(body.containsKey('proposal'), isFalse);
      expect(body.containsKey('note'), isFalse);
    }
  });

  test('passing a store uses the store-pass path', () async {
    final fake = FakeHttpClient()
      ..statusCode = 204
      ..body = '';

    await _repo(
      fake,
    ).decide(const DiscoveryTarget.store('s1'), SwipeOutcome.pass);

    expect(fake.requests.single.method, 'PUT');
    expect(fake.requests.single.url.path, '/discovery/store-passes/s1');
  });

  test('decide throws a failure on a server error', () async {
    final fake = FakeHttpClient()..statusCode = 500;

    await expectLater(
      _repo(
        fake,
      ).decide(const DiscoveryTarget.creator('c1'), SwipeOutcome.like),
      throwsA(isA<DiscoveryFailure>()),
    );
  });

  test('setPassReason sends the reason for the target', () async {
    final fake = FakeHttpClient()
      ..statusCode = 204
      ..body = '';

    await _repo(
      fake,
    ).setPassReason(const DiscoveryTarget.creator('c1'), PassReason.region);

    final request = fake.requests.single as http.Request;
    expect(request.url.path, '/discovery/decisions/pass-reason');
    expect(jsonDecode(request.body), {
      'reason': 'REGION',
      'targetId': 'c1',
      'targetKind': 'CREATOR',
    });
  });

  test(
    'undoLast returns the undone target, or null when the body is empty',
    () async {
      final fake = FakeHttpClient()
        ..body = jsonEncode({'targetId': 'c1', 'targetKind': 'CREATOR'});
      final undone = await _repo(fake).undoLast();
      expect(fake.requests.single.method, 'DELETE');
      expect(fake.requests.single.url.path, '/discovery/decisions/last');
      expect(undone, const DiscoveryTarget.creator('c1'));

      final empty = FakeHttpClient()..body = '';
      expect(await _repo(empty).undoLast(), isNull);
    },
  );

  test(
    'undoLast says nothing to undo for a matched card (409) and fails on a server error',
    () async {
      final matched = FakeHttpClient()
        ..statusCode = 409
        ..body = jsonEncode({
          'error': {
            'code': 'CONFLICT',
            'message': '서로 관심이 된 카드예요.',
            'details': null,
          },
        });
      expect(await _repo(matched).undoLast(), isNull);

      final broken = FakeHttpClient()..statusCode = 500;
      await expectLater(
        _repo(broken).undoLast(),
        throwsA(isA<DiscoveryFailure>()),
      );
    },
  );
}
