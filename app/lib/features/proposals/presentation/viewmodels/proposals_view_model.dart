import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/current_user_provider.dart';
import '../../domain/proposal.dart';
import '../../domain/proposal_repository.dart';

class ProposalsState {
  const ProposalsState({
    required this.active,
    required this.ended,
    this.tab = ProposalTab.active,
  });

  final List<ProposalRow> active;
  final List<ProposalRow> ended;
  final ProposalTab tab;

  List<ProposalRow> get shown => tab == ProposalTab.active ? active : ended;

  /// 내가 응답할 차례인 제안 수. 크리에이터의 받은 오퍼 화면이 `제안함` 줄 오른쪽에 보인다.
  int get myTurnCount =>
      active.where((r) => r.group == ProposalGroup.myTurn).length;

  ProposalsState copyWith({ProposalTab? tab}) =>
      ProposalsState(active: active, ended: ended, tab: tab ?? this.tab);
}

/// 제안함(F3)의 두 탭 목록과 고른 탭. 로그인한 사용자가 바뀌면 다시 불러온다. 화면을 모두 떠나면 버려서
/// 다시 열 때 서버에서 새로 읽는다. Riverpod의 자동 재시도는 끈다.
final proposalsViewModelProvider =
    AsyncNotifierProvider.autoDispose<ProposalsViewModel, ProposalsState>(
      ProposalsViewModel.new,
      retry: (_, _) => null,
    );

class ProposalsViewModel extends AsyncNotifier<ProposalsState> {
  ProposalRepository get _repo => ref.read(proposalRepositoryProvider);

  @override
  Future<ProposalsState> build() async {
    ref.watch(currentUserIdProvider);
    return _load(ProposalTab.active);
  }

  Future<ProposalsState> _load(ProposalTab tab) async {
    // 레코드의 `.wait`는 실패를 ParallelWaitError로 감싸서 화면이 원래 예외를 알 수 없다.
    final lists = await Future.wait([
      _repo.fetch(ProposalTab.active),
      _repo.fetch(ProposalTab.ended),
    ]);
    return ProposalsState(active: lists[0], ended: lists[1], tab: tab);
  }

  void selectTab(ProposalTab tab) {
    final current = state.value;
    if (current == null || current.tab == tab) return;
    state = AsyncData(current.copyWith(tab: tab));
  }

  /// 아래로 당겨 새로 읽는다. 실패하면 보던 내용을 그대로 둔다.
  Future<void> refresh() async {
    final tab = state.value?.tab ?? ProposalTab.active;
    try {
      final fresh = await _load(tab);
      if (!ref.mounted) return;
      state = AsyncData(fresh.copyWith(tab: state.value?.tab ?? tab));
    } on ProposalFailure {
      // 보던 값 유지.
    }
  }
}

/// 제안함 아래쪽에 잠깐 보이는 안내(예: `오퍼를 보냈어요.`). 제안함이 보여 주고 스스로 지운다.
final proposalsNoticeProvider = NotifierProvider<ProposalsNotice, String?>(
  ProposalsNotice.new,
);

class ProposalsNotice extends Notifier<String?> {
  @override
  String? build() => null;

  void show(String message) => state = message;

  void clear() => state = null;
}
