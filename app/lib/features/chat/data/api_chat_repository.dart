import 'package:cora_api/api.dart' as api;
import 'package:flutter/foundation.dart';

import '../../../core/network/api_error.dart';
import '../domain/chat_repository.dart';
import '../domain/conversation.dart';
import '../domain/message.dart';
import 'chat_wire.dart';

/// 생성된 API 클라이언트(`cora_api`)로 대화를 읽고 쓴다. 생성된 타입은 이 계층 밖으로 내보내지 않는다.
///
/// 차단과 신고의 서버(5번 계획 Task 5)는 아직 없어서 [block]과 [report]는 [UnimplementedError]를
/// 던진다. 그 Task가 생성 클라이언트를 만들면 여기만 채운다.
class ApiChatRepository implements ChatRepository {
  ApiChatRepository(api.ApiClient client)
    : _conversations = api.ConversationsApi(client);

  final api.ConversationsApi _conversations;

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
      api.SendMessageDto(
        clientId: clientId,
        kind: sendableKindToWire(kind),
        text: text,
      ),
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
  Future<void> block(String id) => throw UnimplementedError(
    'blockConversationMember는 5번 계획 Task 5에서 서버와 함께 만든다.',
  );

  @override
  Future<void> report(
    ReportTarget target,
    ReportReason reason,
    String? detail,
  ) => throw UnimplementedError('createReport는 5번 계획 Task 5에서 서버와 함께 만든다.');

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
