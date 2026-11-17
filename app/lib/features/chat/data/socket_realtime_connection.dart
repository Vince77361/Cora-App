import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:cora_api/api.dart' as api;
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../domain/realtime_connection.dart';
import 'chat_wire.dart';

/// 소켓 하나. 연결 한 번에 쓰고 버린다(다시 붙을 때는 새 토큰으로 새 소켓을 만든다). 실제 구현은
/// `socket_io_client`를 감싼 것이고, 테스트는 손으로 쓴 가짜를 끼운다.
abstract class RealtimeSocket {
  void onConnect(void Function() handler);
  void onDisconnect(void Function() handler);
  void onConnectError(void Function() handler);

  /// 서버가 보낸 이벤트 [event]를 받는다. [handler]에는 디코딩된 본문이 온다.
  void on(String event, void Function(Object? payload) handler);

  void connect();

  /// 연결을 끊고 받던 것을 모두 놓는다.
  void dispose();
}

/// [url] 네임스페이스에 [token]으로 붙는 소켓을 만든다.
typedef RealtimeSocketFactory =
    RealtimeSocket Function(String url, String token);

/// 서버 게이트웨이(`/realtime` 네임스페이스)에 붙어 새 메시지와 방의 변경을 받는다.
///
/// 서버와의 약속(5번 계획 Task 4):
/// - 연결할 때 `auth: { token }`으로 현재 액세스 토큰을 보낸다. 서버가 토큰을 검증하지 못하면 바로 끊는다.
/// - 이벤트 `message.created`는 `{ conversationId, message }`, `conversation.updated`는
///   `{ conversationId, reason }`이다. `session.expired`는 토큰이 만료되는 때 서버가 보낸 뒤 끊는다.
/// - 앱은 이벤트를 보내지 않는다. 소켓은 상태를 바꾸지 않는다.
///
/// 끊기거나 연결하지 못하거나 `session.expired`를 받으면 새 토큰을 받아 [backoff]의 간격(기본 1·2·4·8·16·30초,
/// 마지막 간격에서 멈춘다)으로 다시 붙는다. 서버가 먼저 끊은 경우(`io server disconnect`, 토큰 검증 실패)도 같다:
/// socket.io는 그때 스스로 다시 붙지 않으므로 앱이 직접 다시 붙는다. 붙은 뒤 [stableAfter] 동안 끊기지 않으면
/// 간격은 처음으로 돌아간다. socket.io의 자동
/// 재연결은 끈다. 그 재연결은 처음 쓴 옛 토큰으로 붙기 때문이다.
class SocketRealtimeConnection implements RealtimeConnection {
  SocketRealtimeConnection({
    required String baseUrl,
    required this.tokenProvider,
    RealtimeSocketFactory? socketFactory,
    this.backoff = defaultBackoff,
    this.wait = _systemWait,
    this.stableAfter = const Duration(seconds: 10),
  }) : assert(backoff.isNotEmpty),
       _url = '$baseUrl/realtime',
       _socketFactory = socketFactory ?? ioSocketFactory;

  static const defaultBackoff = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
    Duration(seconds: 16),
    Duration(seconds: 30),
  ];

  static Future<void> _systemWait(Duration delay) =>
      Future<void>.delayed(delay);

  /// 연결할 때마다 부르는, 그 순간 유효한 액세스 토큰. 세션이 없으면 null.
  final Future<String?> Function() tokenProvider;

  /// 다시 붙기 전에 기다리는 간격. 다 쓰면 마지막 값을 되풀이한다.
  final List<Duration> backoff;

  /// 간격만큼 기다리는 함수. 테스트가 기다리지 않고 간격만 기록하게 바꾼다.
  final Future<void> Function(Duration) wait;

  /// 붙은 뒤 이만큼 끊기지 않아야 연결이 자리 잡은 것으로 보고 간격을 처음으로 돌린다. 서버가 토큰을 검증하지
  /// 못하면 연결을 받은 뒤 곧바로 끊어서(`io server disconnect`) `connect`가 오고 바로 `disconnect`가 온다.
  /// 붙자마자 간격을 돌리면 그 경우에 1초마다 끝없이 두드리게 된다.
  final Duration stableAfter;

  final String _url;
  final RealtimeSocketFactory _socketFactory;
  Timer? _stableTimer;

  final _events = StreamController<RealtimeEvent>.broadcast();
  final _reconnected = StreamController<void>.broadcast();

  bool _running = false;

  // 소켓을 새로 만들거나 버릴 때마다 올린다. 버려진 소켓이 뒤늦게 부르는 콜백을 가려 내는 표시다.
  int _generation = 0;
  int _attempt = 0;
  bool _needsCatchUp = false;
  RealtimeSocket? _socket;

  @override
  Stream<RealtimeEvent> get events => _events.stream;

  @override
  Stream<void> get reconnected => _reconnected.stream;

  @override
  Future<void> start() async {
    if (_running) return;
    _running = true;
    _attempt = 0;
    _needsCatchUp = false;
    await _open(++_generation);
  }

  @override
  Future<void> stop() async {
    _running = false;
    _generation++;
    _discardSocket();
  }

  bool _alive(int generation) => _running && generation == _generation;

  Future<void> _open(int generation) async {
    String? token;
    try {
      token = await tokenProvider();
    } catch (_) {
      token = null;
    }
    if (!_alive(generation)) return;
    if (token == null || token.isEmpty) {
      // 기다림은 이 호출 밖에서 이어 간다. [start]가 연결이 될 때까지 붙잡혀 있지 않게 한다.
      unawaited(_retry(generation));
      return;
    }
    final socket = _socketFactory(_url, token);
    _socket = socket;
    socket
      ..onConnect(() {
        if (!_alive(generation)) return;
        _stableTimer?.cancel();
        _stableTimer = Timer(stableAfter, () {
          if (_alive(generation)) _attempt = 0;
        });
        if (_needsCatchUp) {
          _needsCatchUp = false;
          _reconnected.add(null);
        }
      })
      ..onDisconnect(() => _lost(generation))
      ..onConnectError(() => _lost(generation))
      ..on('message.created', (p) {
        if (_alive(generation)) _onMessageCreated(p);
      })
      ..on('conversation.updated', (p) {
        if (_alive(generation)) _onConversationUpdated(p);
      })
      ..on('session.expired', (_) {
        if (!_alive(generation)) return;
        _events.add(const SessionExpired());
        _lost(generation);
      })
      ..connect();
  }

  /// 연결이 끊겼거나 붙지 못했다. 옛 소켓을 버리고 새 토큰으로 다시 붙을 차례를 잡는다.
  void _lost(int generation) {
    if (!_alive(generation)) return;
    _needsCatchUp = true;
    final next = ++_generation;
    _discardSocket();
    unawaited(_retry(next));
  }

  Future<void> _retry(int generation) async {
    final delay = backoff[math.min(_attempt, backoff.length - 1)];
    _attempt++;
    await wait(delay);
    if (!_alive(generation)) return;
    await _open(generation);
  }

  void _discardSocket() {
    _stableTimer?.cancel();
    _stableTimer = null;
    final socket = _socket;
    _socket = null;
    if (socket == null) return;
    try {
      socket.dispose();
    } catch (_) {
      // 이미 닫힌 소켓을 닫다 난 오류는 버릴 소켓이라 무시한다.
    }
  }

  void _onMessageCreated(Object? payload) {
    if (payload is! Map) return;
    final conversationId = payload['conversationId'];
    final raw = payload['message'];
    if (conversationId is! String || raw is! Map) return;
    try {
      final model = api.MessageModel.fromJson(raw);
      if (model == null) return;
      _events.add(
        MessageCreated(
          conversationId: conversationId,
          message: chatMessageFromWire(model),
        ),
      );
    } catch (error) {
      // 모양이 어긋난 이벤트는 건너뛴다. 빠진 번호는 앱이 다음에 서버에서 다시 읽어 메운다.
      developer.log(
        'message.created 읽기 실패: ${error.runtimeType}',
        name: 'realtime',
      );
    }
  }

  void _onConversationUpdated(Object? payload) {
    if (payload is! Map) return;
    final conversationId = payload['conversationId'];
    if (conversationId is! String) return;
    _events.add(
      ConversationUpdated(
        conversationId: conversationId,
        reason: updateReasonFromWire(payload['reason']),
      ),
    );
  }
}

/// `socket_io_client`로 [url](네임스페이스 포함)에 붙는 소켓. 웹소켓만 쓴다: 서버가 여러 대일 때 처음 요청과
/// 이어지는 요청이 같은 서버로 가야 하는 긴 폴링을 쓰지 않으려는 것이다.
RealtimeSocket ioSocketFactory(String url, String token) {
  final socket = io.io(
    url,
    io.OptionBuilder()
        .setTransports(['websocket'])
        .setAuth({'token': token})
        .enableForceNew()
        .disableAutoConnect()
        .disableReconnection()
        .build(),
  );
  return _IoSocket(socket);
}

class _IoSocket implements RealtimeSocket {
  _IoSocket(this._socket);

  final io.Socket _socket;

  @override
  void onConnect(void Function() handler) =>
      _socket.onConnect((_) => handler());

  @override
  void onDisconnect(void Function() handler) =>
      _socket.onDisconnect((_) => handler());

  @override
  void onConnectError(void Function() handler) =>
      _socket.onConnectError((_) => handler());

  @override
  void on(String event, void Function(Object? payload) handler) =>
      _socket.on(event, (payload) => handler(payload));

  @override
  void connect() => _socket.connect();

  @override
  void dispose() => _socket.dispose();
}
