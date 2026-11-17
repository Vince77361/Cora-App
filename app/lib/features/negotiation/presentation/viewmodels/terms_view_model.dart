import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/current_user_provider.dart';
import '../../../collaboration/domain/collaboration.dart';
import '../../../collaboration/domain/collaboration_repository.dart';
import '../../../collaboration/presentation/viewmodels/collaboration_list_view_model.dart';
import '../../../collaboration/presentation/viewmodels/collaboration_view_model.dart';
import '../../domain/negotiation_repository.dart';
import '../../domain/terms_version.dart';
import '../terms_text.dart';
import 'brand_collaborations_view_model.dart';

/// 06이 그리는 것: 협업(상대 이름·사진, 내 쪽)과 그 최신 조건 판본.
class TermsState {
  const TermsState({
    required this.collaboration,
    required this.latest,
    this.busy = false,
    this.notice,
    this.staleVersion,
  });

  final Collaboration collaboration;
  final TermsLatest latest;

  /// 수락을 서버에 보내는 중. 그동안은 다시 누르지 못한다.
  final bool busy;

  /// 화면에 보일 안내(서버 문구 또는 일반 실패 문구).
  final String? notice;

  /// 수락하려는 사이 상대가 더 새 판본을 냈다. 값은 최신 판본 번호이고, 있으면 06은 F8 옛 판본 상태를 보인다(버튼은 12를 연다).
  final int? staleVersion;

  /// 내가 브랜드 쪽이다.
  bool get isBrand => collaboration.role == CollaborationRole.commissioner;

  TermsState copyWith({
    Collaboration? collaboration,
    TermsLatest? latest,
    bool? busy,
    String? notice,
    bool clearNotice = false,
    int? staleVersion,
    bool clearStale = false,
  }) => TermsState(
    collaboration: collaboration ?? this.collaboration,
    latest: latest ?? this.latest,
    busy: busy ?? this.busy,
    notice: clearNotice ? null : (notice ?? this.notice),
    staleVersion: clearStale ? null : (staleVersion ?? this.staleVersion),
  );
}

/// 협업 하나의 조건 판본(06). 협업마다 하나 만들고 화면을 떠나면 버린다. Riverpod의 자동 재시도는 끈다
/// (읽기 실패는 화면의 "다시 시도"가 다시 부른다).
final termsViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<TermsViewModel, TermsState, String>(
      TermsViewModel.new,
      retry: (_, _) => null,
    );

class TermsViewModel extends AsyncNotifier<TermsState> {
  TermsViewModel(this.collaborationId);

  final String collaborationId;

  NegotiationRepository get _repo => ref.read(negotiationRepositoryProvider);

  @override
  Future<TermsState> build() async {
    ref.watch(currentUserIdProvider);
    return _load();
  }

  Future<TermsState> _load() async {
    final results = await Future.wait<Object>([
      ref.read(collaborationRepositoryProvider).fetch(collaborationId),
      _repo.fetchLatest(collaborationId),
    ]);
    return TermsState(
      collaboration: results[0] as Collaboration,
      latest: results[1] as TermsLatest,
    );
  }

  /// 판본을 다시 읽는다(인스타그램을 연동하고 돌아온 뒤). 읽는 동안 화면은 그대로 두고,
  /// 못 읽으면 안내만 띄운다.
  Future<void> reload() async {
    final current = state.value;
    try {
      final fresh = await _load();
      if (!ref.mounted) return;
      state = AsyncData(fresh);
    } catch (_) {
      if (!ref.mounted || current == null) return;
      state = AsyncData(
        current.copyWith(busy: false, notice: TermsTexts.actionFailed),
      );
    }
  }

  /// `이 판본 수락`. 지금 화면의 판본 번호와 함께 보내고, 성공하면 true.
  Future<bool> confirm() async {
    final current = state.value;
    if (current == null || current.busy) return false;
    final version = current.latest.terms.version;
    state = AsyncData(current.copyWith(busy: true, clearNotice: true));
    try {
      await _repo.confirm(collaborationId, version);
    } on NegotiationStale catch (stale) {
      if (!ref.mounted) return false;
      // 서버가 최신 번호를 안 알려 주면 다시 읽어 그 번호를 쓴다.
      var latest = stale.latestVersion;
      if (latest == null) {
        try {
          latest = (await _repo.fetchLatest(collaborationId)).terms.version;
        } catch (_) {
          latest = null;
        }
        if (!ref.mounted) return false;
      }
      state = AsyncData(
        current.copyWith(busy: false, staleVersion: latest ?? version + 1),
      );
      return false;
    } catch (error) {
      if (!ref.mounted) return false;
      final message = error is NegotiationRejected ? error.message : null;
      state = AsyncData(
        current.copyWith(
          busy: false,
          notice: (message == null || message.trim().isEmpty)
              ? TermsTexts.actionFailed
              : message,
        ),
      );
      return false;
    }
    if (!ref.mounted) return true;
    // 07과 협업 목록이 새 판본 상태(내가 확인함)를 다시 읽는다.
    ref.invalidate(collaborationViewModelProvider(collaborationId));
    ref.invalidate(collaborationListViewModelProvider);
    ref.invalidate(brandCollaborationsViewModelProvider);
    final latest = state.value ?? current;
    state = AsyncData(latest.copyWith(busy: false));
    return true;
  }
}
