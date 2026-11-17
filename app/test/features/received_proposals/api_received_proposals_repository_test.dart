import 'dart:convert';

import 'package:cora/features/offer_terms/domain/offer_terms.dart'
    show ContentFormat;
import 'package:cora/features/received_proposals/data/api_received_proposals_repository.dart';
import 'package:cora/features/received_proposals/domain/received_proposals_repository.dart';
import 'package:cora_api/api.dart' as api;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// 한 번 정해진 상태와 본문으로 답하고, 받은 요청을 기록한다.
class _Client extends http.BaseClient {
  _Client(this.status, this.body);

  final int status;
  final Object? body;
  final requests = <http.Request>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request as http.Request);
    return http.StreamedResponse(
      Stream.value(utf8.encode(body == null ? '' : jsonEncode(body))),
      status,
      headers: {'content-type': 'application/json'},
      request: request,
    );
  }
}

ApiReceivedProposalsRepository _repo(http.Client client) =>
    ApiReceivedProposalsRepository(
      api.ApiClient(basePath: 'http://127.0.0.1:3000')..client = client,
    );

const _proposalJson = {
  'brandName': '모아 스튜디오',
  'brandPhotoUrl': 'https://x/moa.jpg',
  'campaignId': 'c1',
  'contentPhotoUrl': 'https://x/content.jpg',
  'contentTitle': '매일 손이 가는 물건들',
  'fee': 350000,
  'format': 'CARD_NEWS',
  'note': '실제로 사용하는 장면이 좋았어요.',
  'performance': {'cap': 60000, 'ratePer1000': 2000},
  'productProvided': true,
};

void main() {
  // 실패 로그(디버그 출력)가 테스트 출력에 섞이지 않게 한다.
  final originalDebugPrint = debugPrint;
  setUp(() => debugPrint = (message, {wrapWidth}) {});
  tearDown(() => debugPrint = originalDebugPrint);

  test(
    'maps a received proposal with the brand note and performance',
    () async {
      final client = _Client(200, [_proposalJson]);
      final rows = await _repo(client).fetchAll();

      expect(client.requests.single.url.path, '/discovery/received-proposals');
      final p = rows.single;
      expect(p.campaignId, 'c1');
      expect(p.brandName, '모아 스튜디오');
      expect(p.brandPhotoUrl, 'https://x/moa.jpg');
      expect(p.contentPhotoUrl, 'https://x/content.jpg');
      expect(p.contentTitle, '매일 손이 가는 물건들');
      expect(p.fee, 350000);
      expect(p.format, ContentFormat.cardNews);
      expect(p.note, '실제로 사용하는 장면이 좋았어요.');
      expect(p.performance?.ratePerThousand, 2000);
      expect(p.performance?.cap, 60000);
      expect(p.productProvided, isTrue);
    },
  );

  test('maps a proposal with only terms and no copied content', () async {
    final rows = await _repo(
      _Client(200, [
        {
          ..._proposalJson,
          'brandPhotoUrl': null,
          'contentPhotoUrl': null,
          'contentTitle': null,
          'note': null,
          'performance': null,
        },
      ]),
    ).fetchAll();

    final p = rows.single;
    expect(p.contentTitle, isNull);
    expect(p.note, isNull);
    expect(p.performance, isNull);
  });

  test('reads an empty list', () async {
    expect(await _repo(_Client(200, [])).fetchAll(), isEmpty);
  });

  test('a server error on the list becomes a failure', () async {
    await expectLater(
      _repo(_Client(500, null)).fetchAll(),
      throwsA(isA<ReceivedProposalsFailure>()),
    );
  });

  test('sends the inquiry with the message and the one line', () async {
    final client = _Client(201, {
      'collaborationId': 'collab-1',
      'conversationId': 'room-1',
    });
    final result = await _repo(
      client,
    ).inquire('c1', message: '제품은 언제 받나요?', contentLine: '손목 루틴');

    final request = client.requests.single;
    expect(request.method, 'POST');
    expect(request.url.path, '/discovery/received-proposals/c1/inquiry');
    expect(jsonDecode(request.body), {
      'message': '제품은 언제 받나요?',
      'contentLine': '손목 루틴',
    });
    expect(result.collaborationId, 'collab-1');
    expect(result.conversationId, 'room-1');
  });

  test(
    'a 409 on the inquiry is a conflict and anything else a failure',
    () async {
      const conflictBody = {
        'error': {'code': 'CONFLICT', 'message': '이미 질문했어요.', 'details': null},
      };
      await expectLater(
        _repo(_Client(409, conflictBody)).inquire('c1', message: '질문'),
        throwsA(
          isA<ReceivedProposalsFailure>().having(
            (e) => e.isConflict,
            'isConflict',
            isTrue,
          ),
        ),
      );
      await expectLater(
        _repo(_Client(500, null)).inquire('c1', message: '질문'),
        throwsA(
          isA<ReceivedProposalsFailure>().having(
            (e) => e.isConflict,
            'isConflict',
            isFalse,
          ),
        ),
      );
    },
  );
}
