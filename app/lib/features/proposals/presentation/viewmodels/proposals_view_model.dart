import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/current_user_provider.dart';
import '../../../negotiation/domain/negotiation_repository.dart';
import '../../domain/offer_version.dart';
import '../../domain/proposal.dart';
import '../../domain/proposal_repository.dart';

class ProposalsState {
  const ProposalsState({
    required this.active,
    required this.ended,
    this.tab = ProposalTab.active,
  });

  final List<InboxRow> active;
  final List<InboxRow> ended;
  final ProposalTab tab;

  List<InboxRow> get shown => tab == ProposalTab.active ? active : ended;

  /// 내가 응답할 차례인 제안 수. 크리에이터의 받은 오퍼 화면이 `제안함` 줄 오른쪽에 보인다.
  int get myTurnCount =>
      active.where((r) => r.group == ProposalGroup.myTurn).length;

  ProposalsState copyWith({ProposalTab? tab}) =>
      ProposalsState(active: active, ended: ended, tab: tab ?? this.tab);
}

/// 제안함(F3)의 두 탭 목록과 고른 탭. 로그인한 사용자가 바뀌면 다시 불러온다. 화면을 모두 떠나면 버려서
/// 다시 열 때 서버에서 새로 읽는다. Riverpod의 자동 재시도는 끈다.
///
/// 쓰는 쪽([ProposalParty])마다 하나다. 사장님은 가게 오퍼만, 브랜드는 브랜드 계약의 줄만, 크리에이터는 둘을 한
/// 목록으로 합쳐 본다. 패밀리째 `invalidate`하면 모두 다시 읽는다.
final proposalsViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<ProposalsViewModel, ProposalsState, ProposalParty>(
      ProposalsViewModel.new,
      retry: (_, _) => null,
    );

class ProposalsViewModel extends AsyncNotifier<ProposalsState> {
  ProposalsViewModel(this.party);

  final ProposalParty party;

  ProposalRepository get _repo => ref.read(proposalRepositoryProvider);
  NegotiationRepository get _negotiation =>
      ref.read(negotiationRepositoryProvider);

  @override
  Future<ProposalsState> build() async {
    ref.watch(currentUserIdProvider);
    return _load(ProposalTab.active);
  }

  Future<ProposalsState> _load(ProposalTab tab) async {
    // 브랜드는 가게 오퍼 목록을 부르지 않는다(서버가 브랜드에게는 403이다). 사장님은 브랜드 계약이 없다.
    final withOffers = party != ProposalParty.brand;
    final withContracts = party != ProposalParty.store;
    // 레코드의 `.wait`는 실패를 ParallelWaitError로 감싸서 화면이 원래 예외를 알 수 없다.
    final lists = await Future.wait<List<InboxRow>>([
      if (withOffers) _repo.fetch(ProposalTab.active),
      if (withOffers) _repo.fetch(ProposalTab.ended),
      if (withContracts) _negotiation.fetchProposalInbox(),
    ]);
    final offersActive = withOffers ? lists[0] : const <InboxRow>[];
    final offersEnded = withOffers ? lists[1] : const <InboxRow>[];
    final contracts = withContracts ? lists.last : const <InboxRow>[];
    // 브랜드 계약의 줄은 진행 중과 종료가 한 목록으로 온다. 오퍼의 줄은 받은 시각이 없어 오퍼 뒤에 이어 붙인다.
    return ProposalsState(
      active: [
        ...offersActive,
        for (final r in contracts)
          if (r.group != ProposalGroup.ended) r,
      ],
      ended: [
        ...offersEnded,
        for (final r in contracts)
          if (r.group == ProposalGroup.ended) r,
      ],
      tab: tab,
    );
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
    } on NegotiationFailure {
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
