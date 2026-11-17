import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'message.dart';

/// 서버가 소켓으로 밀어 주는 일. 소켓은 상태를 바꾸지 않고 알리기만 한다. 놓쳤을 수 있으니 받은 쪽은
/// 번호가 빠졌거나 다시 붙었을 때 서버에서 다시 읽는다.
sealed class RealtimeEvent {
  const RealtimeEvent();
}

/// 새 메시지(내가 보낸 것과 안내 줄 포함). [message]의 `mine`은 받는 사람 기준이다.
class MessageCreated extends RealtimeEvent {
  const MessageCreated({required this.conversationId, required this.message});

  final String conversationId;
  final ChatMessage message;
}

/// 방의 머리가 바뀌었다(조건, 계약, 상태, 읽음). 받은 쪽은 방을 다시 읽는다.
class ConversationUpdated extends RealtimeEvent {
  const ConversationUpdated({
    required this.conversationId,
    required this.reason,
  });

  final String conversationId;
  final ConversationUpdateReason reason;
}

/// [ConversationUpdated]의 이유. 서버가 모르는 값을 보내면 [unknown]이다.
enum ConversationUpdateReason { terms, contract, status, read, unknown }

/// 로그인 세션이 끝나 서버가 연결을 끊는다. 연결은 새 토큰으로 스스로 다시 붙는다.
class SessionExpired extends RealtimeEvent {
  const SessionExpired();
}

/// 실시간 연결 포트. 세션이 생기면 [start], 없어지면 [stop]을 부른다.
abstract class RealtimeConnection {
  /// 서버가 밀어 준 일. 연결이 끊겼다 붙어도 같은 스트림이다.
  Stream<RealtimeEvent> get events;

  /// 끊겼다가 다시 붙을 때마다 알린다(처음 붙을 때는 알리지 않는다). 그사이 놓친 것을 다시 읽으라는 신호다.
  Stream<void> get reconnected;

  /// 연결을 시작한다. 이미 시작했으면 아무것도 하지 않는다.
  Future<void> start();

  /// 연결을 끊고 다시 붙지 않는다.
  Future<void> stop();
}

/// 실시간 연결. 기본값은 일부러 던진다. main.dart가 소켓 구현으로, 테스트가 가짜로 바꿔 끼운다.
final realtimeConnectionProvider = Provider<RealtimeConnection>(
  (ref) =>
      throw UnimplementedError('realtimeConnectionProvider must be overridden'),
);
