import 'dart:convert';

import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/proposals/data/api_counter_proposal_repository.dart';
import 'package:cora/features/proposals/domain/counter_proposal_repository.dart';
import 'package:cora/features/proposals/domain/creator_series.dart';
import 'package:cora_api/api.dart' as api;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../support/fake_http_client.dart';

ApiCounterProposalRepository _repo(FakeHttpClient fake) =>
    ApiCounterProposalRepository(
      api.ApiClient(basePath: 'http://127.0.0.1:3000')..client = fake,
    );

const _terms = OfferTerms(
  format: ContentFormat.cardNews,
  reward: Reward(
    voucher: Voucher(name: '식사권', value: 40000, people: 2),
    fixedCash: 30000,
    viewPay: ViewPay(ratePerThousand: 2000, cap: 60000),
  ),
);

String _error(int code, String message) =>
    '{"error":{"code":"CONFLICT","message":"$message","details":null}}';

void main() {
  test('reads my series', () async {
    final fake = FakeHttpClient()
      ..body = jsonEncode([
        {'id': 's1', 'name': '한 그릇 일기', 'format': 'REELS', 'note': '손 중심'},
        {'id': 's2', 'name': '점심 지도', 'format': 'CARD_NEWS', 'note': null},
      ]);

    final series = await _repo(fake).fetchSeries();

    expect(fake.requests.single.url.path, '/creators/me/series');
    expect(series, const [
      CreatorSeries(
        id: 's1',
        name: '한 그릇 일기',
        format: ContentFormat.reels,
        note: '손 중심',
      ),
      CreatorSeries(id: 's2', name: '점심 지도', format: ContentFormat.cardNews),
    ]);
  });

  test('creates a series', () async {
    final fake = FakeHttpClient()
      ..statusCode = 201
      ..body = jsonEncode({
        'id': 's9',
        'name': '새 시리즈',
        'format': 'SHORTS',
        'note': null,
      });

    final created = await _repo(
      fake,
    ).addSeries(name: '새 시리즈', format: ContentFormat.shorts);

    final request = fake.requests.single as http.Request;
    expect(request.method, 'POST');
    expect(jsonDecode(request.body), {
      'name': '새 시리즈',
      'format': 'SHORTS',
      'note': null,
    });
    expect(created.id, 's9');
  });

  test('sends a new proposal to the store with every part', () async {
    final fake = FakeHttpClient()
      ..statusCode = 201
      ..body = '{"offerId":"o1","version":2}';

    final result = await _repo(fake).sendToStore(
      's1',
      const CounterProposal(
        terms: _terms,
        seriesId: 'series-1',
        idea: '  손만 찍어요  ',
        principles: ['얼굴출연없음'],
      ),
    );

    final request = fake.requests.single as http.Request;
    expect(request.url.path, '/stores/s1/proposals');
    expect(jsonDecode(request.body), {
      'format': 'CARD_NEWS',
      'reward': {
        'voucher': {'name': '식사권', 'value': 40000, 'people': 2},
        'fixedCash': 30000,
        'perView': {'ratePerThousand': 2000, 'cap': 60000},
      },
      'usageRights': 'STORE_REPOST_3M',
      'idea': '손만 찍어요',
      'principles': ['얼굴출연없음'],
      'seriesId': 'series-1',
    });
    expect(result, (offerId: 'o1', version: 2));
  });

  test(
    'sends the next version of an open offer with a blank idea left out',
    () async {
      final fake = FakeHttpClient()
        ..body =
            '{"id":"v","offerId":"o1","version":3,"author":"CREATOR","createdAt":"2026-11-13T00:00:00.000Z"}';

      await _repo(fake)
          .sendVersion('o1', const CounterProposal(terms: _terms, idea: '  '))
          .catchError((_) {});

      final request = fake.requests.single as http.Request;
      expect(request.url.path, '/offers/o1/versions');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['idea'], isNull);
      expect(body['principles'], isEmpty);
    },
  );

  test('keeps the server message of a rejected send', () async {
    final fake = FakeHttpClient()
      ..statusCode = 409
      ..body = _error(409, '인스타그램을 연동하면 수락할 수 있어요.');

    await expectLater(
      _repo(fake).sendToStore('s1', const CounterProposal(terms: _terms)),
      throwsA(
        isA<CounterProposalFailure>().having(
          (f) => f.message,
          'message',
          '인스타그램을 연동하면 수락할 수 있어요.',
        ),
      ),
    );
  });

  test('hides the message of a server failure', () async {
    final fake = FakeHttpClient()
      ..statusCode = 500
      ..body = _error(500, '내부 오류');

    await expectLater(
      _repo(fake).fetchSeries(),
      throwsA(
        isA<CounterProposalFailure>().having(
          (f) => f.message,
          'message',
          isNull,
        ),
      ),
    );
  });
}
