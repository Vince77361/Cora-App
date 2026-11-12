import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/collaboration_repository.dart';
import '../collaboration_text.dart';
import 'collaboration_list_view_model.dart';
import 'collaboration_view_model.dart';

class SubmitLinkState {
  const SubmitLinkState({this.busy = false, this.error});

  final bool busy;

  /// 서버가 보낸 문구(`링크 형식을 확인해 주세요.` 등) 또는 일반 실패 문구.
  final String? error;
}

/// 링크 제출. 제출하면 서버가 집계를 시작한 협업을 돌려주고, A7이 그것으로 바로 바뀐다.
final submitLinkViewModelProvider = NotifierProvider.autoDispose
    .family<SubmitLinkViewModel, SubmitLinkState, String>(
      SubmitLinkViewModel.new,
    );

class SubmitLinkViewModel extends Notifier<SubmitLinkState> {
  SubmitLinkViewModel(this.collaborationId);

  final String collaborationId;

  @override
  SubmitLinkState build() => const SubmitLinkState();

  /// 성공하면 true. 실패하면 [SubmitLinkState.error]에 이유가 남고 화면에 머문다.
  Future<bool> submit(String url) async {
    if (state.busy) return false;
    state = const SubmitLinkState(busy: true);
    try {
      final next = await ref
          .read(collaborationRepositoryProvider)
          .submitLink(collaborationId, url.trim());
      if (!ref.mounted) return true;
      ref
          .read(collaborationViewModelProvider(collaborationId).notifier)
          .apply(next);
      ref.invalidate(collaborationListViewModelProvider);
      state = const SubmitLinkState();
      return true;
    } catch (error) {
      if (!ref.mounted) return false;
      state = SubmitLinkState(error: failureText(error, submitFailedMessage));
      return false;
    }
  }
}
