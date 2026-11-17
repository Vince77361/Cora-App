import 'dart:convert';

import 'package:cora/features/chat/data/api_chat_repository.dart';
import 'package:cora/features/chat/domain/chat_repository.dart';
import 'package:cora/features/chat/domain/conversation.dart';
import 'package:cora/features/chat/domain/message.dart';
import 'package:cora/features/collaboration/domain/collaboration.dart'
    show CollaborationKind;
import 'package:cora/features/offer_terms/domain/offer_terms.dart'
    show ContentFormat;
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

ApiChatRepository _repo(http.Client client) => ApiChatRepository(
  api.ApiClient(basePath: 'http://127.0.0.1:3000')..client = client,
);

const _counterpart = {
  'name': '모아 스튜디오',
  'photoUrl': 'https://x/moa.jpg',
  'userId': 'u-2',
};

const _summaryJson = {
  'id': 'room-1',
  'contextLabel': '느린 결, 일상의 주얼리 캠페인',
  'counterpart': _counterpart,
  'kind': 'BRAND_CONTRACT',
  'lastMessage': {
    'at': '2026-11-11T05:14:00.000Z',
    'kind': 'TEXT',
    'preview': '안녕하세요!',
  },
  'muted': true,
  'section': 'REQUEST',
  'status': 'REQUESTED',
  'unreadCount': 2,
};

Map<String, Object?> _detailJson({Object? terms, Object? campaignTerms}) => {
  'id': 'room-1',
  'blockedByMe': false,
  'campaignTerms': campaignTerms,
  'canDrop': false,
  'canLikeCampaign': false,
  'canProposeTerms': false,
  'canSend': false,
  'canSendContentCard': false,
  'collaborationId': 'collab-1',
  'contextLabel': '느린 결, 일상의 주얼리 캠페인',
  'contractStatus': 'NONE',
  'counterpart': _counterpart,
  'kind': 'BRAND_CONTRACT',
  'lastMessage': null,
  'lastReadSeq': 0,
  'lastSeq': 1,
  'muted': false,
  'myRole': 'COMMISSIONER',
  'requestedByMe': false,
  'section': 'REQUEST',
  'stage': 'INQUIRY',
  'status': 'REQUESTED',
  'storeTerms': null,
  'terms': terms,
  'unreadCount': 1,
};

const _messageJson = {
  'id': 'm1',
  'seq': 1,
  'kind': 'TEXT',
  'mine': true,
  'text': '안녕하세요',
  'card': null,
  'clientId': 'c-1',
  'createdAt': '2026-11-11T05:14:00.000Z',
};

void main() {
  // 실패 로그(디버그 출력)가 테스트 출력에 섞이지 않게 한다.
  final originalDebugPrint = debugPrint;
  setUp(() => debugPrint = (message, {wrapWidth}) {});
  tearDown(() => debugPrint = originalDebugPrint);

  test('maps the list rows with their section and status', () async {
    final rows = await _repo(_Client(200, [_summaryJson])).fetchList();

    expect(rows, hasLength(1));
    final row = rows.single;
    expect(row.id, 'room-1');
    expect(row.counterpartName, '모아 스튜디오');
    expect(row.counterpartPhotoUrl, 'https://x/moa.jpg');
    expect(row.section, ConversationSection.request);
    expect(row.status, ConversationStatus.requested);
    expect(row.muted, isTrue);
    expect(row.unreadCount, 2);
    expect(row.lastMessage?.preview, '안녕하세요!');
    expect(row.lastMessage?.kind, MessageKind.text);
  });

  test('maps the campaign terms of an inquiry', () async {
    final detail = await _repo(
      _Client(
        200,
        _detailJson(
          campaignTerms: {
            'fee': 300000,
            'format': 'REELS',
            'productProvided': false,
            'startFrom': '2026-11-16',
          },
        ),
      ),
    ).fetch('room-1');

    expect(detail.kind, CollaborationKind.brandContract);
    expect(detail.myRole, ChatRole.commissioner);
    expect(detail.stage, ConversationStage.inquiry);
    expect(detail.isRequestForMe, isTrue);
    expect(detail.campaignTerms?.fee, 300000);
    expect(detail.campaignTerms?.format, ContentFormat.reels);
    expect(detail.campaignTerms?.startFrom, DateTime(2026, 11, 16));
    expect(detail.terms, isNull);
  });

  test('reads messages after a sequence number', () async {
    final client = _Client(200, [_messageJson]);
    final messages = await _repo(client).fetchMessages('room-1', afterSeq: 3);

    expect(client.requests.single.url.path, '/conversations/room-1/messages');
    expect(client.requests.single.url.queryParameters['afterSeq'], '3');
    expect(messages.single.seq, 1);
    expect(messages.single.mine, isTrue);
    expect(messages.single.clientId, 'c-1');
  });

  test('sends a message with its client id', () async {
    final client = _Client(201, _messageJson);
    final sent = await _repo(
      client,
    ).send('room-1', clientId: 'c-1', kind: MessageKind.text, text: '안녕하세요');

    final body = jsonDecode(client.requests.single.body) as Map;
    expect(body, {'clientId': 'c-1', 'kind': 'TEXT', 'text': '안녕하세요'});
    expect(sent.state, SendState.sent);
  });

  test('sends a content card without a text key', () async {
    final client = _Client(201, {
      ..._messageJson,
      'kind': 'CONTENT_CARD',
      'text': null,
      'card': {'title': '이런 분위기로 찍을게요', 'photoUrl': null},
    });
    final sent = await _repo(
      client,
    ).send('room-1', clientId: 'c-2', kind: MessageKind.contentCard);

    // 서버가 카드에 `text: null`도 거절해서 키가 없어야 한다.
    final body = jsonDecode(client.requests.single.body) as Map;
    expect(body, {'clientId': 'c-2', 'kind': 'CONTENT_CARD'});
    expect(sent.kind, MessageKind.contentCard);
    expect(sent.card?.title, '이런 분위기로 찍을게요');
  });

  test('accepts a request and returns the opened room', () async {
    final client = _Client(200, _detailJson());
    final detail = await _repo(client).acceptRequest('room-1');

    expect(client.requests.single.method, 'POST');
    expect(
      client.requests.single.url.path,
      '/conversations/room-1/request/accept',
    );
    expect(detail.id, 'room-1');
  });

  test('declines a request', () async {
    final client = _Client(204, null);
    await _repo(client).declineRequest('room-1');

    expect(
      client.requests.single.url.path,
      '/conversations/room-1/request/decline',
    );
  });

  test('reads and mutes through the matching endpoints', () async {
    final read = _Client(204, null);
    await _repo(read).markRead('room-1', 4);
    expect(jsonDecode(read.requests.single.body), {'seq': 4});

    final mute = _Client(200, {'muted': true});
    await _repo(mute).setMuted('room-1', true);
    expect(mute.requests.single.method, 'PUT');
    expect(jsonDecode(mute.requests.single.body), {'muted': true});
  });

  test('turns 409 and 404 into the matching failures', () async {
    const body = {
      'error': {'code': 'CONFLICT', 'message': '이미 답했어요.', 'details': null},
    };
    await expectLater(
      _repo(_Client(409, body)).acceptRequest('room-1'),
      throwsA(isA<ChatFailure>().having((f) => f.isConflict, 'conflict', true)),
    );
    await expectLater(
      _repo(
        _Client(404, {
          'error': {'code': 'NOT_FOUND', 'message': 'x', 'details': null},
        }),
      ).fetch('room-1'),
      throwsA(isA<ChatFailure>().having((f) => f.isNotFound, 'notFound', true)),
    );
    await expectLater(
      _repo(
        _Client(500, {
          'error': {'code': 'INTERNAL', 'message': 'x'},
        }),
      ).fetchList(),
      throwsA(
        isA<ChatFailure>().having(
          (f) => f.kind,
          'kind',
          ChatFailureKind.failed,
        ),
      ),
    );
  });

  test('blocks the other side through the block endpoint', () async {
    final client = _Client(200, {
      ..._detailJson(),
      'status': 'CLOSED',
      'blockedByMe': true,
    });
    await _repo(client).block('room-1');

    expect(client.requests.single.method, 'POST');
    expect(client.requests.single.url.path, '/conversations/room-1/block');
  });

  test('a block refused for held money is a conflict', () async {
    final client = _Client(409, {
      'error': {
        'code': 'CONFLICT',
        'message': '진행 중인 협업이 있어요. 문의하기로 알려 주세요.',
        'details': null,
      },
    });
    await expectLater(
      _repo(client).block('room-1'),
      throwsA(isA<ChatFailure>().having((f) => f.isConflict, 'conflict', true)),
    );
  });

  test('a conflict carries the server message', () async {
    final client = _Client(409, {
      'error': {
        'code': 'CONFLICT',
        'message': '협업의 상태가 바뀌었어요. 잠시 뒤 다시 시도해 주세요.',
        'details': null,
      },
    });
    await expectLater(
      _repo(client).block('room-1'),
      throwsA(
        isA<ChatFailure>().having(
          (f) => f.message,
          'message',
          '협업의 상태가 바뀌었어요. 잠시 뒤 다시 시도해 주세요.',
        ),
      ),
    );
  });

  test('reports a conversation with its reason and detail', () async {
    final client = _Client(201, {'id': 'report-1'});
    await _repo(client).report(
      const ReportTarget(ReportTargetKind.conversation, 'room-1'),
      ReportReason.fraud,
      '선입금을 요구해요',
    );

    expect(client.requests.single.method, 'POST');
    expect(client.requests.single.url.path, '/reports');
    expect(jsonDecode(client.requests.single.body), {
      'targetKind': 'CONVERSATION',
      'targetId': 'room-1',
      'reason': 'FRAUD',
      'detail': '선입금을 요구해요',
    });
  });

  test('every report reason and target kind maps to the wire value', () async {
    const wire = {
      ReportReason.spam: 'SPAM',
      ReportReason.abuse: 'ABUSE',
      ReportReason.fraud: 'FRAUD',
      ReportReason.other: 'OTHER',
    };
    for (final entry in wire.entries) {
      final client = _Client(201, {'id': 'report-1'});
      await _repo(client).report(
        const ReportTarget(ReportTargetKind.user, 'u-2'),
        entry.key,
        null,
      );
      final body = jsonDecode(client.requests.single.body) as Map;
      expect(body['reason'], entry.value);
      expect(body['targetKind'], 'USER');
    }
  });

  test('a second report is a conflict', () async {
    final client = _Client(409, {
      'error': {'code': 'CONFLICT', 'message': '이미 신고했어요.', 'details': null},
    });
    await expectLater(
      _repo(client).report(
        const ReportTarget(ReportTargetKind.conversation, 'room-1'),
        ReportReason.spam,
        null,
      ),
      throwsA(isA<ChatFailure>().having((f) => f.isConflict, 'conflict', true)),
    );
  });
}
