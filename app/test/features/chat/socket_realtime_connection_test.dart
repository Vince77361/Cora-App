import 'dart:async';

import 'package:cora/features/chat/data/socket_realtime_connection.dart';
import 'package:cora/features/chat/domain/message.dart';
import 'package:cora/features/chat/domain/realtime_connection.dart';
import 'package:flutter_test/flutter_test.dart';

/// 손으로 쓴 가짜 소켓. 테스트가 연결·끊김·이벤트를 직접 일으킨다.
class FakeSocket implements RealtimeSocket {
  FakeSocket(this.url, this.token);

  final String url;
  final String token;

  void Function()? _connect;
  void Function()? _disconnect;
  void Function()? _connectError;
  final _handlers = <String, void Function(Object?)>{};

  int connectCalls = 0;
  bool disposed = false;

  @override
  void onConnect(void Function() handler) => _connect = handler;

  @override
  void onDisconnect(void Function() handler) => _disconnect = handler;

  @override
  void onConnectError(void Function() handler) => _connectError = handler;

  @override
  void on(String event, void Function(Object? payload) handler) =>
      _handlers[event] = handler;

  @override
  void connect() => connectCalls++;

  @override
  void dispose() => disposed = true;

  void fireConnect() => _connect?.call();
  void fireDisconnect() => _disconnect?.call();
  void fireConnectError() => _connectError?.call();
  void fire(String event, Object? payload) => _handlers[event]?.call(payload);
}

const _messageJson = {
  'id': 'm7',
  'seq': 7,
  'kind': 'TEXT',
  'mine': false,
  'text': '안녕하세요',
  'card': null,
  'clientId': null,
  'createdAt': '2026-11-11T05:14:00.000Z',
};

class _Harness {
  _Harness({List<String?>? tokens, Duration stableAfter = Duration.zero})
    : _tokens = tokens ?? ['token-1'] {
    connection = SocketRealtimeConnection(
      baseUrl: 'http://127.0.0.1:3000',
      tokenProvider: () async => _tokens[_tokenCalls++ % _tokens.length],
      socketFactory: (url, token) {
        final socket = FakeSocket(url, token);
        sockets.add(socket);
        return socket;
      },
      backoff: const [
        Duration(seconds: 1),
        Duration(seconds: 2),
        Duration(seconds: 4),
        Duration(seconds: 8),
        Duration(seconds: 16),
        Duration(seconds: 30),
      ],
      stableAfter: stableAfter,
      wait: (delay) async {
        waits.add(delay);
        onWait?.call(waits.length);
      },
    );
    connection.events.listen(events.add);
    connection.reconnected.listen((_) => reconnects++);
  }

  late final SocketRealtimeConnection connection;
  final List<String?> _tokens;
  int _tokenCalls = 0;
  final sockets = <FakeSocket>[];
  final waits = <Duration>[];
  final events = <RealtimeEvent>[];
  int reconnects = 0;
  void Function(int waitCount)? onWait;

  FakeSocket get last => sockets.last;

  /// 이벤트 스트림에 쌓인 것을 비운다.
  Future<void> settle() => Future<void>.delayed(Duration.zero);
}

void main() {
  test('connects to the realtime namespace with the current token', () async {
    final h = _Harness();
    await h.connection.start();

    expect(h.sockets, hasLength(1));
    expect(h.last.url, 'http://127.0.0.1:3000/realtime');
    expect(h.last.token, 'token-1');
    expect(h.last.connectCalls, 1);
  });

  test('does not connect twice when started twice', () async {
    final h = _Harness();
    await h.connection.start();
    await h.connection.start();

    expect(h.sockets, hasLength(1));
  });

  test('does not signal a reconnect for the first connection', () async {
    final h = _Harness();
    await h.connection.start();
    h.last.fireConnect();
    await h.settle();

    expect(h.reconnects, 0);
  });

  test('turns message.created into a message with the receiver view', () async {
    final h = _Harness();
    await h.connection.start();
    h.last.fire('message.created', {
      'conversationId': 'room-1',
      'message': _messageJson,
    });
    await h.settle();

    final event = h.events.single as MessageCreated;
    expect(event.conversationId, 'room-1');
    expect(event.message.seq, 7);
    expect(event.message.text, '안녕하세요');
    expect(event.message.mine, isFalse);
    expect(event.message.kind, MessageKind.text);
    expect(event.message.state, SendState.sent);
    // 상대 메시지에는 앱이 만든 값이 없어 서버의 id가 대신한다.
    expect(event.message.clientId, 'm7');
    expect(event.message.at, DateTime.utc(2026, 11, 11, 5, 14));
  });

  test('turns conversation.updated into an event with its reason', () async {
    final h = _Harness();
    await h.connection.start();
    h.last.fire('conversation.updated', {
      'conversationId': 'room-1',
      'reason': 'TERMS',
    });
    h.last.fire('conversation.updated', {
      'conversationId': 'room-2',
      'reason': 'SOMETHING_NEW',
    });
    await h.settle();

    final updates = h.events.cast<ConversationUpdated>().toList();
    expect(updates.map((e) => e.conversationId), ['room-1', 'room-2']);
    expect(updates[0].reason, ConversationUpdateReason.terms);
    expect(updates[1].reason, ConversationUpdateReason.unknown);
  });

  test('ignores malformed payloads', () async {
    final h = _Harness();
    await h.connection.start();
    h.last.fire('message.created', 'not a map');
    h.last.fire('message.created', {'conversationId': 'room-1'});
    h.last.fire('message.created', {
      'conversationId': 'room-1',
      'message': {'id': 'm1'},
    });
    h.last.fire('conversation.updated', {'reason': 'TERMS'});
    await h.settle();

    expect(h.events, isEmpty);
  });

  test('signals a reconnect when the connection comes back', () async {
    final h = _Harness();
    await h.connection.start();
    h.last.fireConnect();
    h.last.fireDisconnect();
    await h.settle();
    expect(h.sockets, hasLength(2));
    h.last.fireConnect();
    await h.settle();

    expect(h.reconnects, 1);
    expect(h.sockets.first.disposed, isTrue);
  });

  test(
    'does not signal a reconnect when the server drops it right after accepting',
    () async {
      final h = _Harness(stableAfter: const Duration(hours: 1));
      await h.connection.start();
      h.last.fireConnect();
      h.last.fireDisconnect();
      await h.settle();
      // 두 번째 시도도 받은 뒤 곧바로 끊긴다. 자리 잡기 전이라 다시 읽으라는 신호는 없다.
      h.last.fireConnect();
      h.last.fireDisconnect();
      await h.settle();

      expect(h.sockets, hasLength(3));
      expect(h.reconnects, 0);
      await h.connection.stop();
    },
  );

  test('signals a reconnect only once the connection has stayed up', () async {
    final h = _Harness(stableAfter: const Duration(milliseconds: 30));
    await h.connection.start();
    h.last.fireConnect();
    h.last.fireDisconnect();
    await h.settle();
    h.last.fireConnect();
    await h.settle();
    expect(h.reconnects, 0);

    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(h.reconnects, 1);
    await h.connection.stop();
  });

  test('puts the realtime namespace at the server root', () {
    expect(
      SocketRealtimeConnection.realtimeUrl('http://127.0.0.1:3000'),
      'http://127.0.0.1:3000/realtime',
    );
    expect(
      SocketRealtimeConnection.realtimeUrl('http://127.0.0.1:3000/'),
      'http://127.0.0.1:3000/realtime',
    );
    expect(
      SocketRealtimeConnection.realtimeUrl('https://api.cora.example/v1'),
      'https://api.cora.example/realtime',
    );
  });

  test('closes its streams and the socket when disposed', () async {
    final h = _Harness();
    var eventsDone = false;
    var reconnectedDone = false;
    h.connection.events.listen(null, onDone: () => eventsDone = true);
    h.connection.reconnected.listen(null, onDone: () => reconnectedDone = true);
    await h.connection.start();
    final socket = h.last;
    await h.connection.dispose();
    await h.settle();

    expect(socket.disposed, isTrue);
    expect(eventsDone, isTrue);
    expect(reconnectedDone, isTrue);
  });

  test('signals a reconnect after failing to connect at first', () async {
    final h = _Harness();
    await h.connection.start();
    h.last.fireConnectError();
    await h.settle();
    h.last.fireConnect();
    await h.settle();

    expect(h.reconnects, 1);
  });

  test('reconnects with a fresh token after session.expired', () async {
    final h = _Harness(tokens: ['old-token', 'new-token']);
    await h.connection.start();
    h.last.fireConnect();
    h.last.fire('session.expired', null);
    await h.settle();

    expect(h.events.single, isA<SessionExpired>());
    expect(h.sockets, hasLength(2));
    expect(h.sockets[0].token, 'old-token');
    expect(h.sockets[1].token, 'new-token');
    expect(h.sockets[0].disposed, isTrue);
  });

  test(
    'reconnects with the injected backoff and stops growing at 30 seconds',
    () async {
      final h = _Harness();
      // 여덟 번째 기다림에서 멈춘다.
      h.onWait = (count) {
        if (count == 8) unawaited(h.connection.stop());
      };
      h.connection.events.listen(null);
      await h.connection.start();
      // 연결할 때마다 곧바로 실패한다.
      var handled = 0;
      while (handled < h.sockets.length && handled < 20) {
        h.sockets[handled].fireConnectError();
        handled++;
        await h.settle();
      }

      expect(h.waits.map((d) => d.inSeconds), [1, 2, 4, 8, 16, 30, 30, 30]);
    },
  );

  test(
    'reconnects with a fresh token and growing backoff when the server drops it right after accepting',
    () async {
      // 토큰 검증에 실패하면 서버는 연결을 받은 뒤 곧바로 끊는다(`io server disconnect`).
      final h = _Harness(
        tokens: ['bad-1', 'bad-2', 'bad-3', 'good'],
        stableAfter: const Duration(hours: 1),
      );
      await h.connection.start();
      for (var i = 0; i < 3; i++) {
        h.last.fireConnect();
        h.last.fireDisconnect();
        await h.settle();
      }

      expect(h.sockets.map((s) => s.token), [
        'bad-1',
        'bad-2',
        'bad-3',
        'good',
      ]);
      expect(h.waits.map((d) => d.inSeconds), [1, 2, 4]);
      expect(h.sockets.take(3).every((s) => s.disposed), isTrue);
      await h.connection.stop();
    },
  );

  test('starts the backoff over after a connection that stayed up', () async {
    final h = _Harness();
    await h.connection.start();
    h.last.fireConnectError();
    await h.settle();
    h.last.fireConnectError();
    await h.settle();
    expect(h.waits.map((d) => d.inSeconds), [1, 2]);

    h.last.fireConnect();
    await h.settle();
    h.last.fireDisconnect();
    await h.settle();

    expect(h.waits.map((d) => d.inSeconds), [1, 2, 1]);
  });

  test('keeps retrying while there is no token', () async {
    final h = _Harness(tokens: [null, null, 'token-3']);
    h.onWait = (count) {
      if (count > 5) unawaited(h.connection.stop());
    };
    await h.connection.start();
    await h.settle();

    expect(h.waits.map((d) => d.inSeconds), [1, 2]);
    expect(h.sockets, hasLength(1));
    expect(h.last.token, 'token-3');
  });

  test('does not reconnect after stop and disposes the socket', () async {
    final h = _Harness();
    await h.connection.start();
    final socket = h.last;
    await h.connection.stop();
    socket.fireDisconnect();
    await h.settle();

    expect(socket.disposed, isTrue);
    expect(h.sockets, hasLength(1));
    expect(h.waits, isEmpty);
  });

  test('ignores events from a socket that was replaced', () async {
    final h = _Harness();
    await h.connection.start();
    final first = h.last;
    first.fireDisconnect();
    await h.settle();
    first.fire('message.created', {
      'conversationId': 'room-1',
      'message': _messageJson,
    });
    await h.settle();

    expect(h.events, isEmpty);
  });

  test('can start again after stop', () async {
    final h = _Harness(tokens: ['a', 'b']);
    await h.connection.start();
    await h.connection.stop();
    await h.connection.start();

    expect(h.sockets.map((s) => s.token), ['a', 'b']);
  });
}
