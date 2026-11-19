import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../proposals/domain/proposal.dart';
import '../../../proposals/domain/proposal_repository.dart';
import '../../domain/store_interest.dart';
import '../../domain/store_interests_repository.dart';

/// 사장님 저장함의 탭. `offers`가 보낸 제안이다. 고른 탭은 화면이 쥔다.
enum StoreInterestTab {
  saved,
  sent,
  offers;

  /// `?tab=` 쿼리 값. 모르는 값은 저장 탭이다.
  static StoreInterestTab fromQuery(String? value) => switch (value) {
    'sent' => StoreInterestTab.sent,
    'offers' => StoreInterestTab.offers,
    _ => StoreInterestTab.saved,
  };
}

class StoreInterestsState {
  const StoreInterestsState({
    required this.saved,
    required this.sent,
    required this.offers,
  });

  final List<StoreInterest> saved;
  final List<StoreInterest> sent;

  /// 내가 보낸 제안 가운데 진행 중인 것(제안함 F3의 진행 중 탭). 내가 응답할 차례가 먼저다.
  final List<ProposalRow> offers;

  int count(StoreInterestTab tab) => switch (tab) {
    StoreInterestTab.saved => saved.length,
    StoreInterestTab.sent => sent.length,
    StoreInterestTab.offers => offers.length,
  };
}

/// 사장님 저장함의 세 목록. 화면을 모두 떠나면 버리고 다시 열 때 서버에서 새로 읽는다. 실패는 자동으로 다시 읽지
/// 않고 `다시 시도`를 누를 때만 읽는다.
final storeInterestsViewModelProvider =
    AsyncNotifierProvider.autoDispose<
      StoreInterestsViewModel,
      StoreInterestsState
    >(StoreInterestsViewModel.new, retry: (_, _) => null);

/// 저장한 크리에이터 목록. 둘러보기 머리 북마크의 저장 수만 필요한 곳이 세 목록을 다 읽지 않게 따로 둔다. 둘러보기가
/// 결정을 보내거나 되돌리면 이것을 무효로 해 수가 따라간다. 실패는 다시 읽지 않는다.
final storeSavedPeopleProvider =
    FutureProvider.autoDispose<List<StoreInterest>>(
      (ref) => ref.watch(storeInterestsRepositoryProvider).fetchSaved(),
      retry: (_, _) => null,
    );

/// 둘러보기 머리 북마크의 저장 수. 읽기 전이나 읽지 못했을 때는 0이라 배지가 숨는다.
final storeSavedCountProvider = Provider.autoDispose<int>(
  (ref) => ref.watch(storeSavedPeopleProvider).value?.length ?? 0,
);

class StoreInterestsViewModel extends AsyncNotifier<StoreInterestsState> {
  @override
  Future<StoreInterestsState> build() => _load();

  Future<StoreInterestsState> _load() async {
    final repo = ref.read(storeInterestsRepositoryProvider);
    final offersRepo = ref.read(proposalRepositoryProvider);
    // 하나라도 실패하면 첫 실패를 그대로 던진다(레코드의 `.wait`는 실패를 감싸서 쓰지 않는다).
    final results = await Future.wait<Object>([
      repo.fetchSaved(),
      repo.fetchSent(),
      offersRepo.fetch(ProposalTab.active),
    ]);
    return StoreInterestsState(
      saved: results[0] as List<StoreInterest>,
      sent: results[1] as List<StoreInterest>,
      offers: _myTurnFirst(results[2] as List<ProposalRow>),
    );
  }

  /// 제안이나 오퍼를 보내고 돌아온 뒤, 또는 이미 읽어 둔 목록이 있는 채 화면이 열릴 때 새로 읽는다. 실패하면
  /// 보던 내용을 그대로 둔다.
  Future<void> refresh() async {
    try {
      final fresh = await _load();
      if (!ref.mounted) return;
      state = AsyncData(fresh);
    } catch (_) {
      // 보던 값 유지.
    }
  }

  void reload() => ref.invalidateSelf();

  static List<ProposalRow> _myTurnFirst(List<ProposalRow> rows) => [
    for (final r in rows)
      if (r.group == ProposalGroup.myTurn) r,
    for (final r in rows)
      if (r.group != ProposalGroup.myTurn) r,
  ];
}
