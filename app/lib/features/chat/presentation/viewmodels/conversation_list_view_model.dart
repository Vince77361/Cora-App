import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/current_user_provider.dart';
import '../../domain/chat_repository.dart';
import '../../domain/conversation.dart';
import '../../domain/realtime_connection.dart';

class ConversationListState {
  const ConversationListState({
    required this.requests,
    required this.conversations,
  });

  /// 내가 답해야 하는 메시지 요청. 목록 맨 위에 따로 모인다.
  final List<ConversationSummary> requests;

  /// 그 밖의 대화. 서버가 마지막 메시지가 최근인 순으로 준다.
  final List<ConversationSummary> conversations;

  bool get isEmpty => requests.isEmpty && conversations.isEmpty;
}

/// 대화 목록(하단 메뉴의 `대화`). 로그인한 사용자가 바뀌면 다시 읽고, 소켓이 새 메시지나 방의 변경을
/// 알리거나 연결이 다시 붙으면 서버에서 다시 읽는다. 화면을 모두 떠나면 버려서 다시 열 때 새로 읽는다.
final conversationListViewModelProvider =
    AsyncNotifierProvider.autoDispose<
      ConversationListViewModel,
      ConversationListState
    >(ConversationListViewModel.new, retry: (_, _) => null);

class ConversationListViewModel extends AsyncNotifier<ConversationListState> {
  ChatRepository get _repo => ref.read(chatRepositoryProvider);

  bool _refreshing = false;
  bool _refreshAgain = false;

  @override
  Future<ConversationListState> build() async {
    ref.watch(currentUserIdProvider);
    final connection = ref.watch(realtimeConnectionProvider);
    final events = connection.events.listen((event) {
      // 소켓은 알리기만 한다. 목록은 서버가 정렬한 값을 다시 읽어 맞춘다.
      if (event is MessageCreated || event is ConversationUpdated) {
        unawaited(refresh());
      }
    });
    final reconnected = connection.reconnected.listen((_) => refresh());
    ref.onDispose(() {
      events.cancel();
      reconnected.cancel();
    });
    return _load();
  }

  Future<ConversationListState> _load() async {
    final rows = await _repo.fetchList();
    return ConversationListState(
      requests: [
        for (final r in rows)
          if (r.section == ConversationSection.request) r,
      ],
      conversations: [
        for (final r in rows)
          if (r.section != ConversationSection.request) r,
      ],
    );
  }

  /// 서버 값으로 다시 읽는다. 실패하면 보던 내용을 그대로 둔다. 읽는 중에 또 부르면 끝난 뒤 한 번 더 읽는다.
  Future<void> refresh() async {
    if (_refreshing) {
      _refreshAgain = true;
      return;
    }
    _refreshing = true;
    try {
      do {
        _refreshAgain = false;
        try {
          final fresh = await _load();
          if (!ref.mounted) return;
          state = AsyncData(fresh);
        } on ChatFailure {
          // 보던 값 유지.
        }
      } while (_refreshAgain && ref.mounted);
    } finally {
      _refreshing = false;
    }
  }
}
