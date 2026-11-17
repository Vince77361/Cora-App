import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/id/uuid_v4.dart';
import '../../../../core/time/clock.dart';
import '../../../../core/ui/swipe_deck/swipe_physics.dart' show SwipeOutcome;
import '../../../auth/domain/current_user_provider.dart';
import '../../../collaboration/domain/collaboration_repository.dart';
import '../../../discovery/domain/discovery_repository.dart';
import '../../../discovery/domain/discovery_target.dart';
import '../../../negotiation/domain/negotiation_repository.dart';
import '../../domain/chat_repository.dart';
import '../../domain/conversation.dart';
import '../../domain/message.dart';
import '../../domain/realtime_connection.dart';
import '../chat_text.dart';
import 'conversation_list_view_model.dart';

/// 서버가 한 번에 주는 메시지 수. 이보다 적게 오면 더 없다.
const chatPageSize = 50;

/// [current]에 [incoming]을 번호 기준으로 합쳐 번호 순으로 돌려준다. 같은 번호가 두 번 오면 먼저 있던 것을 쓴다
/// (소켓과 서버 응답이 같은 메시지를 따로 가져와도 한 번만 보인다).
List<ChatMessage> mergeMessages(
  List<ChatMessage> current,
  Iterable<ChatMessage> incoming,
) {
  final bySeq = <int, ChatMessage>{
    for (final m in current)
      if (m.seq != null) m.seq!: m,
  };
  for (final m in incoming) {
    final seq = m.seq;
    if (seq != null) bySeq.putIfAbsent(seq, () => m);
  }
  final seqs = bySeq.keys.toList()..sort();
  return [for (final seq in seqs) bySeq[seq]!];
}

/// 맨 앞에서부터 빠짐없이 이어지는 마지막 번호. 이 뒤로 빠진 번호가 있으면 여기부터 다시 받는다.
/// 메시지가 없으면 0이다.
int contiguousLastSeq(List<ChatMessage> messages) {
  if (messages.isEmpty) return 0;
  var last = messages.first.seq!;
  for (final m in messages.skip(1)) {
    if (m.seq != last + 1) break;
    last = m.seq!;
  }
  return last;
}

bool _hasGap(List<ChatMessage> messages) {
  for (var i = 1; i < messages.length; i++) {
    if (messages[i].seq != messages[i - 1].seq! + 1) return true;
  }
  return false;
}

class ChatThreadState {
  const ChatThreadState({
    required this.detail,
    required this.messages,
    this.pending = const [],
    this.hasOlder = false,
    this.loadingOlder = false,
    this.liking = false,
    this.likeSent = false,
    this.notice,
  });

  final ConversationDetail detail;

  /// 서버가 확정한 메시지(번호 순).
  final List<ChatMessage> messages;

  /// 보내는 중이거나 보내지 못한 내 메시지(보낸 순서). 서버가 같은 `clientId`의 메시지를 주면 빠진다.
  final List<ChatMessage> pending;
  final bool hasOlder;
  final bool loadingOlder;

  /// `관심 보내기`를 보내는 중이거나 보냈다(서로 관심이 아직 아니다).
  final bool liking;
  final bool likeSent;

  /// 방금 한 일이 실패했을 때 입력란 위에 보일 문구.
  final String? notice;

  bool get isEmpty => messages.isEmpty && pending.isEmpty;

  ChatThreadState copyWith({
    ConversationDetail? detail,
    List<ChatMessage>? messages,
    List<ChatMessage>? pending,
    bool? hasOlder,
    bool? loadingOlder,
    bool? liking,
    bool? likeSent,
    String? notice,
    bool clearNotice = false,
  }) => ChatThreadState(
    detail: detail ?? this.detail,
    messages: messages ?? this.messages,
    pending: pending ?? this.pending,
    hasOlder: hasOlder ?? this.hasOlder,
    loadingOlder: loadingOlder ?? this.loadingOlder,
    liking: liking ?? this.liking,
    likeSent: likeSent ?? this.likeSent,
    notice: clearNotice ? null : (notice ?? this.notice),
  );
}

/// 대화방 하나(D3). 메시지를 읽어 번호 순으로 두고, 소켓이 밀어 주는 새 메시지를 받고, 빠진 번호나
/// 끊겼다 붙은 뒤에는 서버에서 메운다. 보내기는 먼저 화면에 올리고(`pending`) 서버가 받으면 확정한다.
final chatThreadViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<ChatThreadViewModel, ChatThreadState, String>(
      ChatThreadViewModel.new,
      retry: (_, _) => null,
    );

class ChatThreadViewModel extends AsyncNotifier<ChatThreadState> {
  ChatThreadViewModel(this._id);

  final String _id;

  ChatRepository get _repo => ref.read(chatRepositoryProvider);

  /// 처음 읽는 동안 소켓으로 먼저 온 메시지. 다 읽은 뒤 합친다.
  final _early = <ChatMessage>[];

  /// 서버에 읽었다고 알린 마지막 번호.
  int _markedSeq = 0;
  bool _visible = false;

  bool _catchingUp = false;
  bool _catchUpAgain = false;

  /// 콘텐츠 카드를 보내다 실패해도 다시 누르면 같은 값으로 보내서 카드가 두 번 가지 않게 한다.
  String? _cardClientId;

  @override
  Future<ChatThreadState> build() async {
    ref.watch(currentUserIdProvider);
    final connection = ref.watch(realtimeConnectionProvider);
    final events = connection.events.listen(_onEvent);
    final reconnected = connection.reconnected.listen((_) => _recover());
    ref.onDispose(() {
      events.cancel();
      reconnected.cancel();
    });
    // 레코드의 `.wait`는 실패를 ParallelWaitError로 감싸서 화면이 원래 예외를 알 수 없다.
    final results = await Future.wait<Object>([
      _repo.fetch(_id),
      _repo.fetchMessages(_id),
    ]);
    final detail = results[0] as ConversationDetail;
    final page = results[1] as List<ChatMessage>;
    _markedSeq = detail.lastReadSeq;
    final messages = mergeMessages(page, _early);
    _early.clear();
    // 다 읽은 뒤에야 상태가 있으므로 다음 틈에 이어서 한다.
    scheduleMicrotask(() {
      if (!ref.mounted) return;
      if (_hasGap(messages)) unawaited(_catchUp());
      _maybeMarkRead();
    });
    return ChatThreadState(
      detail: detail,
      messages: messages,
      hasOlder: page.length >= chatPageSize,
    );
  }

  void _onEvent(RealtimeEvent event) {
    switch (event) {
      case MessageCreated(:final conversationId, :final message)
          when conversationId == _id:
        _receive([message]);
      // 읽음은 내 다른 기기가 읽었다는 알림이라 이 화면이 바꿀 것이 없다.
      case ConversationUpdated(:final conversationId, :final reason)
          when conversationId == _id && reason != ConversationUpdateReason.read:
        unawaited(_refreshDetail());
      default:
    }
  }

  /// 소켓이나 서버 응답으로 온 확정 메시지를 합친다. 번호가 빠져 있으면 서버에서 메운다. [fillGap]이 false이면
  /// 메우는 중에 받은 쪽(`_catchUp`)이 부른 것이라 구멍이 남아도 다시 메우기를 시작하지 않는다.
  void _receive(List<ChatMessage> incoming, {bool fillGap = true}) {
    final current = state.value;
    if (current == null) {
      _early.addAll(incoming);
      return;
    }
    final messages = mergeMessages(current.messages, incoming);
    final arrived = {for (final m in incoming) m.clientId};
    state = AsyncData(
      current.copyWith(
        messages: messages,
        // 서버가 돌려준 내 메시지는 더는 보내는 중이 아니다.
        pending: [
          for (final p in current.pending)
            if (!arrived.contains(p.clientId)) p,
        ],
      ),
    );
    if (fillGap && _hasGap(messages)) unawaited(_catchUp());
    _maybeMarkRead();
  }

  /// 연결이 끊겼다 붙었다. 그사이 놓친 메시지와 머리의 변경을 서버에서 다시 읽는다.
  void _recover() {
    if (state.value == null) return;
    unawaited(_catchUp());
    unawaited(_refreshDetail());
  }

  /// 한 번의 메우기가 서버를 부를 수 있는 최대 횟수(겹쳐 들어온 요청으로 다시 도는 것까지 합친다).
  static const _catchUpBudget = 20;

  /// 마지막으로 이어진 번호 뒤를 서버에서 받아 메운다. 50개가 꽉 차 오면 더 있는 것이니 이어서 받는다.
  /// 이미 받는 중에 또 부르면 끝난 뒤 한 번 더 한다.
  ///
  /// 서버가 끝내 주지 않는 번호가 있으면(행을 지웠다거나 숨겼다) 이어진 번호가 늘지 않으므로 거기서 멈추고, 전체
  /// 횟수도 [_catchUpBudget]으로 막는다. 멈춘 뒤에는 다음 `message.created`나 `reconnected`가 다시 시도한다.
  Future<void> _catchUp() async {
    if (_catchingUp) {
      _catchUpAgain = true;
      return;
    }
    _catchingUp = true;
    var budget = _catchUpBudget;
    try {
      do {
        _catchUpAgain = false;
        while (budget > 0) {
          final current = state.value;
          if (current == null) return;
          budget--;
          final before = contiguousLastSeq(current.messages);
          final page = await _repo.fetchMessages(_id, afterSeq: before);
          if (!ref.mounted) return;
          _receive(page, fillGap: false);
          final after = contiguousLastSeq(state.value?.messages ?? const []);
          // 이어진 번호가 늘지 않았거나 더 받을 것이 없으면 이번 메우기는 끝이다.
          if (after <= before || page.length < chatPageSize) break;
        }
      } while (_catchUpAgain && budget > 0 && ref.mounted);
    } on ChatFailure {
      // 못 읽으면 다음 메시지나 다음 재연결이 다시 메운다.
    } finally {
      _catchingUp = false;
    }
  }

  Future<void> _refreshDetail() async {
    try {
      final fresh = await _repo.fetch(_id);
      final current = state.value;
      if (!ref.mounted || current == null) return;
      state = AsyncData(current.copyWith(detail: fresh));
    } on ChatFailure {
      // 보던 머리를 그대로 둔다.
    }
  }

  /// 위로 끝까지 올렸다. 지금 가진 가장 오래된 번호 앞의 50개를 읽는다.
  Future<void> loadOlder() async {
    final current = state.value;
    if (current == null ||
        !current.hasOlder ||
        current.loadingOlder ||
        current.messages.isEmpty) {
      return;
    }
    state = AsyncData(current.copyWith(loadingOlder: true));
    try {
      final page = await _repo.fetchMessages(
        _id,
        beforeSeq: current.messages.first.seq,
      );
      final latest = state.value;
      if (!ref.mounted || latest == null) return;
      state = AsyncData(
        latest.copyWith(
          messages: mergeMessages(latest.messages, page),
          hasOlder: page.length >= chatPageSize,
          loadingOlder: false,
        ),
      );
    } on ChatFailure {
      final latest = state.value;
      if (!ref.mounted || latest == null) return;
      state = AsyncData(latest.copyWith(loadingOlder: false));
    }
  }

  /// 글을 보낸다. 먼저 `sending`으로 화면에 올리고 서버가 받으면 확정한다. 실패하면 `failed`로 남는다.
  Future<void> send(String raw) async {
    final current = state.value;
    final text = raw.trim();
    if (current == null ||
        text.isEmpty ||
        text.runes.length > ChatTexts.messageMax) {
      return;
    }
    final message = ChatMessage(
      clientId: uuidV4(),
      kind: MessageKind.text,
      mine: true,
      text: text,
      at: ref.read(clockProvider).now(),
      state: SendState.sending,
    );
    state = AsyncData(
      current.copyWith(
        pending: [...current.pending, message],
        clearNotice: true,
      ),
    );
    await _deliver(message.clientId);
  }

  /// 보내지 못한 메시지를 같은 `clientId`로 다시 보낸다. 서버가 이미 받았다면 새로 만들지 않고 처음 것을 준다.
  Future<void> retry(String clientId) async {
    final current = state.value;
    if (current == null) return;
    final index = current.pending.indexWhere((m) => m.clientId == clientId);
    if (index < 0 || current.pending[index].state != SendState.failed) return;
    _setPendingState(clientId, SendState.sending);
    await _deliver(clientId);
  }

  Future<void> _deliver(String clientId) async {
    final current = state.value;
    if (current == null) return;
    final index = current.pending.indexWhere((m) => m.clientId == clientId);
    if (index < 0) return;
    try {
      final sent = await _repo.send(
        _id,
        clientId: clientId,
        kind: MessageKind.text,
        text: current.pending[index].text,
      );
      if (!ref.mounted) return;
      _receive([sent]);
    } on ChatFailure {
      if (!ref.mounted) return;
      _setPendingState(clientId, SendState.failed);
    }
  }

  void _setPendingState(String clientId, SendState next) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        pending: [
          for (final m in current.pending)
            if (m.clientId == clientId)
              ChatMessage(
                clientId: m.clientId,
                kind: m.kind,
                mine: m.mine,
                text: m.text,
                at: m.at,
                state: next,
              )
            else
              m,
        ],
      ),
    );
  }

  /// 내 콘텐츠 카드를 보낸다. 카드의 사진과 제목은 서버가 프로필에서 복사해 넣는다.
  Future<bool> sendContentCard() async {
    if (state.value == null) return false;
    final clientId = _cardClientId ??= uuidV4();
    try {
      final sent = await _repo.send(
        _id,
        clientId: clientId,
        kind: MessageKind.contentCard,
      );
      if (!ref.mounted) return true;
      _cardClientId = null;
      // 이전 시도가 남긴 실패 문구는 이제 지운다.
      clearNotice();
      _receive([sent]);
      return true;
    } on ChatFailure {
      final current = state.value;
      if (!ref.mounted || current == null) return false;
      state = AsyncData(current.copyWith(notice: ChatTexts.cardFailed));
      return false;
    }
  }

  /// 알림 끄기·켜기.
  Future<void> toggleMute() async {
    final current = state.value;
    if (current == null) return;
    final next = !current.detail.muted;
    try {
      await _repo.setMuted(_id, next);
      final latest = state.value;
      if (!ref.mounted || latest == null) return;
      state = AsyncData(
        latest.copyWith(
          detail: latest.detail.copyWith(muted: next),
          clearNotice: true,
        ),
      );
      _refreshList();
    } on ChatFailure {
      final latest = state.value;
      if (!ref.mounted || latest == null) return;
      state = AsyncData(latest.copyWith(notice: ChatTexts.muteFailed));
    }
  }

  /// 이 대화의 상대를 차단한다. 성공하면 null, 실패하면 시트에 보일 문구를 돌려준다. 돈이 보관 중인 협업이 있으면
  /// 서버가 409로 막는다.
  ///
  /// 성공하면 방이 닫힌 모습으로 먼저 바꾼다(서버의 `conversation.updated`와 머리 다시 읽기가 이어서 맞춘다).
  /// 차단한 쪽에는 `차단한 대화예요.`, 상대 쪽에는 서버가 닫았다고만 알려 `대화가 종료됐어요.`로 보인다.
  Future<String?> block() async {
    try {
      await _repo.block(_id);
    } on ChatFailure catch (failure) {
      if (!failure.isConflict) return ChatTexts.actionFailed;
      // 409는 돈이 보관 중이어서만이 아니다(협업 상태가 그사이 바뀐 경우도 있다). 서버 문구가 보관 중 문구가 아니면
      // 그 문구를 보인다.
      final server = failure.message;
      return server == null || server == ChatTexts.blockConflict
          ? ChatTexts.blockConflict
          : server;
    }
    final current = state.value;
    if (!ref.mounted || current == null) return null;
    state = AsyncData(
      current.copyWith(
        detail: current.detail.copyWith(
          blockedByMe: true,
          status: ConversationStatus.closed,
        ),
        clearNotice: true,
      ),
    );
    _refreshList();
    unawaited(_refreshDetail());
    return null;
  }

  /// 이 대화방을 신고한다. 성공하면 null, 이미 신고했으면 `이미 신고했어요.`, 그 밖의 실패는 일반 문구를 돌려준다.
  /// 빈 설명은 보내지 않는다.
  Future<String?> report(ReportReason reason, String? detail) async {
    final text = detail?.trim();
    try {
      await _repo.report(
        ReportTarget(ReportTargetKind.conversation, _id),
        reason,
        text == null || text.isEmpty ? null : text,
      );
      return null;
    } on ChatFailure catch (failure) {
      return failure.isConflict
          ? ChatTexts.reportAlready
          : ChatTexts.actionFailed;
    }
  }

  /// 계약 전 협의를 그만둔다. 성공하면 null, 서버가 문구와 함께 거절하면 그 문구, 그 밖의 실패는 일반 문구를
  /// 돌려준다. 이유는 서버에만 남고 상대에게는 `이번에는 함께하기 어렵대요.` 줄만 간다.
  Future<String?> drop(DropReason reason) async {
    final collaborationId = state.value?.detail.collaborationId;
    if (collaborationId == null) return ChatTexts.actionFailed;
    try {
      await ref
          .read(negotiationRepositoryProvider)
          .drop(collaborationId, reason);
    } on NegotiationRejected catch (rejected) {
      return rejected.message ?? ChatTexts.actionFailed;
    } on NegotiationFailure {
      return ChatTexts.actionFailed;
    }
    final current = state.value;
    if (!ref.mounted || current == null) return null;
    state = AsyncData(
      current.copyWith(
        detail: current.detail.copyWith(
          stage: ConversationStage.dropped,
          canDrop: false,
        ),
        clearNotice: true,
      ),
    );
    _refreshList();
    unawaited(_refreshDetail());
    return null;
  }

  /// `관심 보내기`(서로 관심 전, 크리에이터만). 캠페인 번호는 협업에서 읽어 4번의 관심으로 보낸다.
  /// 서로 관심이 되면 머리를 다시 읽어 조건 요약으로 바꾼다.
  Future<void> likeCampaign() async {
    final current = state.value;
    if (current == null || current.liking || current.likeSent) return;
    state = AsyncData(current.copyWith(liking: true, clearNotice: true));
    try {
      final collaboration = await ref
          .read(collaborationRepositoryProvider)
          .fetch(current.detail.collaborationId);
      final campaignId = collaboration.campaign?.id;
      if (campaignId == null) throw const DiscoveryFailure();
      final result = await ref
          .read(discoveryRepositoryProvider)
          .decide(DiscoveryTarget.campaign(campaignId), SwipeOutcome.like);
      if (!ref.mounted) return;
      if (result.matched) await _refreshDetail();
      final latest = state.value;
      if (!ref.mounted || latest == null) return;
      state = AsyncData(latest.copyWith(liking: false, likeSent: true));
      _refreshList();
    } on CollaborationFailure {
      _likeFailed();
    } on DiscoveryFailure {
      _likeFailed();
    } on Exception {
      // 예상 밖의 오류여도 알약이 계속 흐린 채 남지 않게 한다.
      _likeFailed();
    }
  }

  void _likeFailed() {
    final latest = state.value;
    if (!ref.mounted || latest == null) return;
    state = AsyncData(
      latest.copyWith(liking: false, notice: ChatTexts.likeFailed),
    );
  }

  /// 화면이 보이는 동안(앱이 앞에 있을 때)만 true. 보이는 동안 새 메시지는 곧바로 읽음으로 알린다.
  void setVisible(bool visible) {
    _visible = visible;
    if (visible) _maybeMarkRead();
  }

  void _maybeMarkRead() {
    final current = state.value;
    if (!_visible || current == null || current.messages.isEmpty) return;
    // 아직 받지 못한 번호(구멍 뒤)까지 읽음으로 알리지 않도록 이어진 마지막 번호까지만 알린다.
    final last = contiguousLastSeq(current.messages);
    if (last <= _markedSeq) return;
    final previous = _markedSeq;
    // 알리는 동안 같은 번호를 또 보내지 않게 먼저 올려 둔다.
    _markedSeq = last;
    unawaited(_markRead(last, previous));
  }

  Future<void> _markRead(int seq, int previous) async {
    try {
      await _repo.markRead(_id, seq);
      if (ref.mounted) _refreshList();
    } on ChatFailure {
      // 못 알렸으면 다음 메시지나 다음 화면에서 다시 알린다.
      if (ref.mounted && _markedSeq == seq) _markedSeq = previous;
    }
  }

  /// 목록은 읽음·알림 끄기·관심으로 바뀐 줄을 다시 읽는다. 목록이 열려 있지 않으면 건드리지 않는다.
  void _refreshList() {
    if (!ref.read(conversationListViewModelProvider.exists)) return;
    unawaited(ref.read(conversationListViewModelProvider.notifier).refresh());
  }

  /// 입력란 위의 실패 문구를 지운다.
  void clearNotice() {
    final current = state.value;
    if (current == null || current.notice == null) return;
    state = AsyncData(current.copyWith(clearNotice: true));
  }
}
