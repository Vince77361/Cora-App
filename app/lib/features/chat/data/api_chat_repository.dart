import 'package:cora_api/api.dart' as api;
import 'package:flutter/foundation.dart';

import '../../../core/network/api_error.dart';
import '../domain/chat_repository.dart';
import '../domain/conversation.dart';
import '../domain/message.dart';
import 'chat_wire.dart';

/// 생성된 API 클라이언트(`cora_api`)로 대화를 읽고 쓴다. 생성된 타입은 이 계층 밖으로 내보내지 않는다.
///
class ApiChatRepository implements ChatRepository {
  ApiChatRepository(api.ApiClient client)
    : _conversations = api.ConversationsApi(client),
      _blocks = api.BlocksApi(client),
      _reports = api.ReportsApi(client);

  final api.ConversationsApi _conversations;
  final api.BlocksApi _blocks;
  final api.ReportsApi _reports;

  @override
  Future<List<ConversationSummary>> fetchList() => _guard(() async {
    final rows = await _conversations.listConversations();
    if (rows == null) throw const ChatFailure.failed();
    return [for (final m in rows) conversationSummaryFromWire(m)];
  });

  @override
  Future<ConversationDetail> fetch(String id) => _guard(() async {
    final m = await _conversations.getConversation(id);
    if (m == null) throw const ChatFailure.failed();
    return conversationDetailFromWire(m);
  });

  @override
  Future<List<ChatMessage>> fetchMessages(
    String id, {
    int? afterSeq,
    int? beforeSeq,
  }) => _guard(() async {
    final rows = await _conversations.listMessages(
      id,
      afterSeq: afterSeq,
      beforeSeq: beforeSeq,
    );
    if (rows == null) throw const ChatFailure.failed();
    return [for (final m in rows) chatMessageFromWire(m)];
  });

  @override
  Future<ChatMessage> send(
    String id, {
    required String clientId,
    required MessageKind kind,
    String? text,
  }) => _guard(() async {
    final m = await _conversations.sendMessage(
      id,
      _SendBody(clientId: clientId, kind: sendableKindToWire(kind), text: text),
    );
    if (m == null) throw const ChatFailure.failed();
    return chatMessageFromWire(m);
  });

  @override
  Future<void> markRead(String id, int seq) => _guard(
    () => _conversations.markConversationRead(id, api.MarkReadDto(seq: seq)),
  );

  @override
  Future<void> setMuted(String id, bool muted) => _guard(() async {
    await _conversations.setConversationMuted(
      id,
      api.SetMutedDto(muted: muted),
    );
  });

  @override
  Future<void> block(String id) =>
      _guard(() => _blocks.blockConversationMember(id));

  @override
  Future<void> report(
    ReportTarget target,
    ReportReason reason,
    String? detail,
  ) => _guard(
    () => _reports.createReport(
      api.CreateReportDto(
        targetKind: reportTargetKindToWire(target.kind),
        targetId: target.id,
        reason: reportReasonToWire(reason),
        detail: detail,
      ),
    ),
  );

  @override
  Future<ConversationDetail> acceptRequest(String id) => _guard(() async {
    final m = await _conversations.acceptMessageRequest(id);
    if (m == null) throw const ChatFailure.failed();
    return conversationDetailFromWire(m);
  });

  @override
  Future<void> declineRequest(String id) =>
      _guard(() => _conversations.declineMessageRequest(id));

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on ChatFailure {
      rethrow;
    } catch (error) {
      final parsed = ApiError.from(error);
      // 사용자에게는 보이지 않는다. 종류와 상태 코드만 남긴다(응답 본문과 문구는 남기지 않는다).
      if (kDebugMode) {
        debugPrint(
          '[chat] 실패: 종류=${error.runtimeType} 상태=${parsed.status} 코드=${parsed.code}',
        );
      }
      if (parsed.isConflict) throw const ChatFailure.conflict();
      if (parsed.isNotFound) throw const ChatFailure.notFound();
      throw const ChatFailure.failed();
    }
  }
}

/// 보내는 본문. 생성된 `SendMessageDto`는 글이 없으면 `"text": null`을 싣는데 서버는 콘텐츠 카드에 `text`가
/// 있으면(null 포함) 400으로 거절한다. 그래서 글이 없을 때는 키를 아예 싣지 않는다.
/// 서버가 null을 없는 것으로 보게 고쳐지면 이 클래스를 지우고 `SendMessageDto`를 그대로 쓴다(DTO에 칸이 더해져도
/// 여기서는 조용히 빠지기 때문이다).
class _SendBody extends api.SendMessageDto {
  _SendBody({required super.clientId, required super.kind, super.text});

  @override
  Map<String, dynamic> toJson() => {
    'clientId': clientId,
    'kind': kind,
    if (text != null) 'text': text,
  };
}
