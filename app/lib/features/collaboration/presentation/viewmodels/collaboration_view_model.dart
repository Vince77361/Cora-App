import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/current_user_provider.dart';
import '../../domain/collaboration.dart';
import '../../domain/collaboration_repository.dart';
import '../collaboration_text.dart';
import 'collaboration_list_view_model.dart';

class CollaborationDetailState {
  const CollaborationDetailState({
    required this.collaboration,
    this.busy = false,
    this.notice,
  });

  final Collaboration collaboration;

  /// 취소·동의를 서버에 보내는 중. 그동안은 다시 누르지 못한다.
  final bool busy;

  /// 화면에 보일 안내(서버 문구 또는 일반 실패 문구).
  final String? notice;

  CollaborationDetailState copyWith({
    Collaboration? collaboration,
    bool? busy,
    String? notice,
    bool clearNotice = false,
  }) => CollaborationDetailState(
    collaboration: collaboration ?? this.collaboration,
    busy: busy ?? this.busy,
    notice: clearNotice ? null : (notice ?? this.notice),
  );
}

/// 협업 하나의 진행(A7). 협업마다 하나 만들고 화면을 떠나면 버린다. 제출 화면이 [apply]로 새 협업을
/// 넘겨 주면 A7이 바로 바뀐다. 취소와 동의는 성공하면 true를 돌려줘 화면이 떠나게 한다.
///
/// Riverpod의 자동 재시도는 끈다(읽기 실패는 화면의 "다시 시도"가 다시 부른다).
final collaborationViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<CollaborationViewModel, CollaborationDetailState, String>(
      CollaborationViewModel.new,
      retry: (_, _) => null,
    );

class CollaborationViewModel extends AsyncNotifier<CollaborationDetailState> {
  CollaborationViewModel(this.collaborationId);

  final String collaborationId;

  CollaborationRepository get _repo =>
      ref.read(collaborationRepositoryProvider);

  @override
  Future<CollaborationDetailState> build() async {
    ref.watch(currentUserIdProvider);
    return CollaborationDetailState(
      collaboration: await _repo.fetch(collaborationId),
    );
  }

  /// 제출처럼 다른 화면이 서버에서 받은 최신 협업을 넘긴다.
  void apply(Collaboration next) {
    final current = state.value;
    state = AsyncData(
      current == null
          ? CollaborationDetailState(collaboration: next)
          : current.copyWith(collaboration: next, clearNotice: true),
    );
  }

  void showNotice(String text) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(notice: text));
  }

  /// `협업 그만두기`. 성공하면 true.
  Future<bool> cancel() => _act((repo) => repo.cancel(collaborationId));

  /// 사장님의 취소 요청에 `동의하기`. 성공하면 true.
  Future<bool> acceptCancel(String requestId) =>
      _act((repo) => repo.acceptCancel(collaborationId, requestId));

  /// 사장님의 `협업 취소 요청`. 성공하면 서버가 만든 요청을 받아 와 화면이 띠를 보이게 하고 true.
  Future<bool> requestCancel() async {
    final done = await _act((repo) => repo.requestCancel(collaborationId));
    if (done) await _refreshQuietly(null);
    return done;
  }

  Future<bool> _act(
    Future<void> Function(CollaborationRepository repo) call,
  ) async {
    final current = state.value;
    if (current == null || current.busy) return false;
    state = AsyncData(current.copyWith(busy: true, clearNotice: true));
    try {
      await call(_repo);
    } catch (error) {
      if (!ref.mounted) return false;
      // 409(그사이 바뀜)는 서버 문구를 보이고, 최신 상태로 맞춰 버튼이 낡지 않게 한다.
      final text = failureText(error, actionFailedMessage);
      final latest = state.value ?? current;
      state = AsyncData(latest.copyWith(busy: false, notice: text));
      if (error is CollaborationFailure && error.conflict) {
        await _refreshQuietly(text);
      }
      return false;
    }
    if (!ref.mounted) return true;
    // 목록은 협업이 끝났거나 바뀐 것을 다시 읽는다.
    ref.invalidate(collaborationListViewModelProvider);
    final latest = state.value ?? current;
    state = AsyncData(latest.copyWith(busy: false));
    return true;
  }

  Future<void> _refreshQuietly(String? notice) async {
    try {
      final fresh = await _repo.fetch(collaborationId);
      if (!ref.mounted) return;
      final latest = state.value;
      if (latest == null) return;
      state = AsyncData(
        latest.copyWith(collaboration: fresh, busy: false, notice: notice),
      );
    } catch (_) {
      // 못 읽어도 안내는 이미 떠 있다.
    }
  }
}
