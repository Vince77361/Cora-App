import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'conversation.dart';
import 'message.dart';

/// 신고할 수 있는 대상의 종류. 서버의 `POST /reports`(`targetKind`)와 같다.
enum ReportTargetKind { user, conversation }

/// 신고 대상. 내가 참가한 방이나 그 상대여야 한다.
class ReportTarget {
  const ReportTarget(this.kind, this.id);

  final ReportTargetKind kind;
  final String id;
}

/// 신고 사유 하나. 서버의 `SPAM | ABUSE | FRAUD | OTHER`와 같다.
enum ReportReason { spam, abuse, fraud, other }

/// 대화 목록, 대화방, 메시지 요청이 서버와 주고받는 포트. 실패하면 [ChatFailure]를 던진다.
abstract class ChatRepository {
  /// 내 대화 목록. 답해야 하는 메시지 요청이 먼저, 다음은 마지막 메시지가 최근인 순.
  Future<List<ConversationSummary>> fetchList();

  Future<ConversationDetail> fetch(String id);

  /// 메시지를 번호 오름차순으로. [afterSeq]는 빠진 번호를 받을 때, [beforeSeq]는 위로 넘겨 볼 때다.
  /// 둘 다 없으면 마지막 50개다.
  Future<List<ChatMessage>> fetchMessages(
    String id, {
    int? afterSeq,
    int? beforeSeq,
  });

  /// 메시지를 보낸다. 같은 [clientId]로 다시 보내도 서버는 새 메시지를 만들지 않고 처음 것을 돌려준다.
  Future<ChatMessage> send(
    String id, {
    required String clientId,
    required MessageKind kind,
    String? text,
  });

  Future<void> markRead(String id, int seq);

  Future<void> setMuted(String id, bool muted);

  /// 대화 상대를 차단한다. 돈이 보관 중인 협업이 있으면 [ChatFailure.conflict]다.
  Future<void> block(String id);

  /// 신고한다. 이미 신고했으면 [ChatFailure.conflict]다.
  Future<void> report(ReportTarget target, ReportReason reason, String? detail);

  /// 메시지 요청을 수락해 방을 연다. 이미 답한 요청이면 [ChatFailure.conflict]다.
  Future<ConversationDetail> acceptRequest(String id);

  /// 메시지 요청을 거절한다. 상대에게는 대화가 열리지 않았다고만 보인다.
  Future<void> declineRequest(String id);
}

/// 서버와 주고받지 못했다. 서버 응답의 문구는 담지 않는다.
class ChatFailure implements Exception {
  const ChatFailure(this.kind) : message = null;

  /// 연결 문제이거나 서버가 처리하지 못한 일.
  const ChatFailure.failed() : kind = ChatFailureKind.failed, message = null;

  /// 이미 답했거나 상태가 맞지 않다(409). [message]는 서버가 사용자에게 보이라고 준 문구다(같은 409라도 이유가
  /// 여럿인 요청이 가려 쓴다). 없으면 null이다.
  const ChatFailure.conflict([this.message]) : kind = ChatFailureKind.conflict;

  /// 방이 없거나 참가자가 아니다(404).
  const ChatFailure.notFound()
    : kind = ChatFailureKind.notFound,
      message = null;

  final ChatFailureKind kind;
  final String? message;

  bool get isConflict => kind == ChatFailureKind.conflict;
  bool get isNotFound => kind == ChatFailureKind.notFound;

  @override
  String toString() => 'ChatFailure($kind)';
}

enum ChatFailureKind { failed, conflict, notFound }

/// 대화 저장소. 기본값은 일부러 던진다. main.dart가 API 구현으로, 테스트가 가짜로 바꿔 끼운다.
final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) =>
      throw UnimplementedError('chatRepositoryProvider must be overridden'),
);
