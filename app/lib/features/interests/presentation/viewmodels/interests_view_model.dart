import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/swipe_deck/swipe_physics.dart' show SwipeOutcome;
import '../../../discovery/domain/discovery_repository.dart';
import '../../domain/interest_card.dart';
import '../../domain/interests_repository.dart';
import '../../domain/match_info.dart';
import '../interests_text.dart';

/// 03의 탭. 저장은 관심과 보류를 합친 것이라 목록 하나에서 앱이 가른다.
enum InterestTab {
  saved,
  mutual,
  sent,
  held;

  /// `?tab=` 쿼리 값. 모르는 값은 저장 탭이다.
  static InterestTab fromQuery(String? value) => switch (value) {
    'mutual' => InterestTab.mutual,
    'sent' => InterestTab.sent,
    'held' => InterestTab.held,
    _ => InterestTab.saved,
  };

  bool includes(InterestState state) => switch (this) {
    InterestTab.saved => true,
    InterestTab.mutual => state == InterestState.mutual,
    InterestTab.sent => state == InterestState.waiting,
    InterestTab.held => state == InterestState.held,
  };
}

/// 카드 위에 3초 뜨는 알림 문구. [serial]이 바뀌면 새 알림이다(3초를 다시 센다).
class InterestsNotice {
  const InterestsNotice(this.serial, this.message);

  final int serial;
  final String message;
}

class InterestsState {
  const InterestsState({
    required this.cards,
    this.tab = InterestTab.saved,
    this.selected = const [],
    this.notice,
  });

  /// 내가 저장한 카드 전부(서버 순서).
  final List<InterestCard> cards;
  final InterestTab tab;

  /// 비교하려고 고른 후보의 id(고른 순서가 아니라 [cards] 순서로 둔다).
  final List<String> selected;
  final InterestsNotice? notice;

  int count(InterestTab tab) =>
      cards.where((c) => tab.includes(c.state)).length;

  /// 지금 탭에 보이는 카드.
  List<InterestCard> get visible => [
    for (final c in cards)
      if (tab.includes(c.state)) c,
  ];

  /// 비교 버튼이 켜진다: 정확히 두 장을 골랐다.
  bool get canCompare => selected.length == 2;

  InterestsState copyWith({
    List<InterestCard>? cards,
    InterestTab? tab,
    List<String>? selected,
    InterestsNotice? notice,
    bool clearNotice = false,
  }) => InterestsState(
    cards: cards ?? this.cards,
    tab: tab ?? this.tab,
    selected: selected ?? this.selected,
    notice: clearNotice ? null : (notice ?? this.notice),
  );
}

/// 03을 여는 방식. 브랜드만 비교를 하고, [tab]은 처음 고를 탭이다(`?tab=`).
typedef InterestsScope = ({bool isBrand, InterestTab tab});

/// 03 관심·보류의 상태. 화면을 떠나면 버리고 다시 열 때 목록을 새로 읽는다. 처음 열 때 브랜드는 저장 탭의
/// 위 두 장이 비교에 골라져 있다(크리에이터에게는 비교가 없어 [InterestsState.selected]를 쓰지 않는다).
final interestsViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<InterestsViewModel, InterestsState, InterestsScope>(
      InterestsViewModel.new,
      // 실패는 자동으로 다시 읽지 않고 `다시 시도`를 누를 때만 읽는다.
      retry: (_, _) => null,
    );

/// 비교에 고를 수 있는 최대 수.
const maxCompared = 2;

class InterestsViewModel extends AsyncNotifier<InterestsState> {
  InterestsViewModel(this.scope);

  final InterestsScope scope;
  int _serial = 0;

  @override
  Future<InterestsState> build() async {
    final cards = await ref.read(interestsRepositoryProvider).fetchSaved();
    return InterestsState(
      cards: cards,
      tab: scope.tab,
      selected: scope.isBrand
          ? [for (final c in cards.take(maxCompared)) c.id]
          : const [],
    );
  }

  InterestsNotice _notice(String message) =>
      InterestsNotice(++_serial, message);

  void selectTab(InterestTab tab) {
    final current = state.value;
    if (current == null || current.tab == tab) return;
    state = AsyncData(current.copyWith(tab: tab));
  }

  /// 비교 동그라미를 누른다. 세 번째는 고르지 않고 false를 돌려주며 안내 문구를 띄운다.
  bool togglePick(InterestCard card) {
    final current = state.value;
    if (current == null) return false;
    final picked = current.selected.contains(card.id);
    if (!picked && current.selected.length >= maxCompared) {
      state = AsyncData(
        current.copyWith(notice: _notice(InterestsTexts.pickLimit)),
      );
      return false;
    }
    final next = {
      ...current.selected.where((id) => id != card.id),
      if (!picked) card.id,
    };
    state = AsyncData(
      current.copyWith(
        // 표의 왼쪽·오른쪽이 고른 순서가 아니라 목록 순서가 되게 한다.
        selected: [
          for (final c in current.cards)
            if (next.contains(c.id)) c.id,
        ],
      ),
    );
    return true;
  }

  /// 보류한 카드를 관심이나 넘김으로 바꾼다. 서로 관심이 닿았으면 그 협업 id를 돌려준다. 실패하면 던지고
  /// 아무것도 바꾸지 않는다(안내는 부른 쪽이 한다).
  Future<String?> decideHeld(
    InterestCard card,
    SwipeOutcome outcome, {
    required String message,
  }) async {
    final result = await ref
        .read(discoveryRepositoryProvider)
        .decide(card.target, outcome);
    if (!ref.mounted) return null;
    final fresh = await _reload();
    if (!ref.mounted) return null;
    final current = state.value;
    if (fresh != null && current != null) {
      state = AsyncData(
        _merge(current, fresh).copyWith(notice: _notice(message)),
      );
    }
    return result.matched ? result.collaborationId : null;
  }

  /// 목록을 다시 읽는다(제안을 보내고 돌아온 뒤). 고른 후보는 남아 있는 것만 유지한다.
  Future<void> refresh() async {
    final fresh = await _reload();
    final current = state.value;
    if (!ref.mounted || fresh == null || current == null) return;
    state = AsyncData(_merge(current, fresh));
  }

  Future<List<InterestCard>?> _reload() async {
    try {
      return await ref.read(interestsRepositoryProvider).fetchSaved();
    } catch (_) {
      return null;
    }
  }

  InterestsState _merge(InterestsState current, List<InterestCard> fresh) {
    final ids = {for (final c in fresh) c.id};
    return current.copyWith(
      cards: fresh,
      selected: [
        for (final id in current.selected)
          if (ids.contains(id)) id,
      ],
    );
  }

  /// 05에 필요한 정보를 읽는다. 실패하면 던진다.
  Future<MatchInfo> loadMatch(String collaborationId) =>
      ref.read(interestsRepositoryProvider).fetchMatch(collaborationId);

  /// 안내 문구를 띄운다.
  void showNotice(String message) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(notice: _notice(message)));
  }

  /// 3초가 지났을 때. 그 사이 새 알림이 떴으면([serial]이 다르면) 건드리지 않는다.
  void dismissNotice(int serial) {
    final current = state.value;
    if (current == null || current.notice?.serial != serial) return;
    state = AsyncData(current.copyWith(clearNotice: true));
  }

  void reload() => ref.invalidateSelf();
}
