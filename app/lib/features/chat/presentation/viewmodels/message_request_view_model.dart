import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/current_user_provider.dart';
import '../../domain/chat_repository.dart';
import '../../domain/conversation.dart';
import '../../domain/message.dart';
import '../chat_text.dart';
import 'conversation_list_view_model.dart';

class MessageRequestState {
  const MessageRequestState({
    required this.detail,
    this.firstMessage,
    this.busy = false,
    this.notice,
  });

  final ConversationDetail detail;

  /// 요청에 담긴 첫 메시지. 읽지 못했으면 null.
  final ChatMessage? firstMessage;

  /// 수락이나 거절을 보내는 중. 그동안은 다시 누르지 못한다.
  final bool busy;

  /// 방금 한 일이 실패했을 때 버튼 위에 보일 문구.
  final String? notice;

  MessageRequestState copyWith({
    bool? busy,
    String? notice,
    bool clearNotice = false,
  }) => MessageRequestState(
    detail: detail,
    firstMessage: firstMessage,
    busy: busy ?? this.busy,
    notice: clearNotice ? null : (notice ?? this.notice),
  );
}

/// 수락·거절의 결과. 화면이 이동이나 안내를 고르는 데 쓴다.
enum RequestOutcome { done, conflict, failed }

/// 메시지 요청 하나(11). 요청이 담은 캠페인 조건과 첫 메시지를 읽고, 수락(대화 열기)과 거절을 보낸다.
final messageRequestViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<MessageRequestViewModel, MessageRequestState, String>(
      MessageRequestViewModel.new,
      retry: (_, _) => null,
    );

class MessageRequestViewModel extends AsyncNotifier<MessageRequestState> {
  MessageRequestViewModel(this._id);

  final String _id;

  ChatRepository get _repo => ref.read(chatRepositoryProvider);

  @override
  Future<MessageRequestState> build() async {
    ref.watch(currentUserIdProvider);
    // 레코드의 `.wait`는 실패를 ParallelWaitError로 감싸서 화면이 원래 예외를 알 수 없다.
    final results = await Future.wait<Object>([
      _repo.fetch(_id),
      _repo.fetchMessages(_id),
    ]);
    final messages = results[1] as List<ChatMessage>;
    ChatMessage? first;
    for (final m in messages) {
      if (m.kind != MessageKind.system) {
        first = m;
        break;
      }
    }
    return MessageRequestState(
      detail: results[0] as ConversationDetail,
      firstMessage: first,
    );
  }

  /// `대화 열기`. 열린 방은 [acceptRequest]가 돌려준 머리로 대화방 화면이 다시 읽는다.
  Future<RequestOutcome> accept() => _answer(() => _repo.acceptRequest(_id));

  /// `요청 거절`을 확인한 뒤.
  Future<RequestOutcome> decline() => _answer(() => _repo.declineRequest(_id));

  Future<RequestOutcome> _answer(Future<void> Function() call) async {
    final current = state.value;
    if (current == null || current.busy) return RequestOutcome.failed;
    state = AsyncData(current.copyWith(busy: true, clearNotice: true));
    try {
      await call();
      if (!ref.mounted) return RequestOutcome.done;
      // 답한 요청은 목록의 `메시지 요청` 묶음에서 빠지거나 일반 줄이 된다.
      ref.invalidate(conversationListViewModelProvider);
      state = AsyncData(current.copyWith(busy: false));
      return RequestOutcome.done;
    } on ChatFailure catch (failure) {
      if (!ref.mounted) return RequestOutcome.failed;
      final conflict = failure.isConflict;
      if (conflict) ref.invalidate(conversationListViewModelProvider);
      state = AsyncData(
        current.copyWith(
          busy: false,
          notice: conflict
              ? ChatTexts.requestAlreadyAnswered
              : ChatTexts.requestActionFailed,
        ),
      );
      return conflict ? RequestOutcome.conflict : RequestOutcome.failed;
    }
  }
}
