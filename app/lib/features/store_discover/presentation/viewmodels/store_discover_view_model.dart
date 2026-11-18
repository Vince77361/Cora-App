import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/swipe_deck/swipe_physics.dart' show SwipeOutcome;
import '../../../discovery/domain/discovery_target.dart';
import '../../../discovery/domain/pass_reason.dart';
import '../../../discovery/domain/undo_result.dart';
import '../../../discovery/presentation/viewmodels/brand_discovery_view_model.dart'
    show DiscoveryToast, DiscoveryToastKind;
import '../../domain/store_creator_card.dart';
import '../../domain/store_discover_repository.dart';

export '../../../discovery/domain/undo_result.dart';

/// 머리 북마크의 저장 수 배지. 사장님 저장함이 생기기 전에는 늘 0이고(0이면 배지를 숨긴다), 저장함 작업이
/// 서버의 저장 수로 바꿔 끼운다.
final storeSavedCountProvider = Provider<int>((ref) => 0);

/// 사장님의 전체 둘러보기. 화면을 떠나면 버리고 다시 열 때 오늘 목록을 새로 읽는다.
final storeDiscoverViewModelProvider =
    AsyncNotifierProvider.autoDispose<
      StoreDiscoverViewModel,
      StoreDiscoverState
    >(StoreDiscoverViewModel.new);

class StoreDiscoverState {
  const StoreDiscoverState({
    required this.total,
    required this.loaded,
    this.done = const {},
    this.toast,
  });

  /// 서버가 센 오늘의 수. 이미 결정한 카드를 포함하므로 "다 봤는지"에는 쓰지 않는다([remaining]).
  final int total;

  /// 불러온 카드를 추천 순서대로. 이 세션에서 결정한 카드도 남아 있다.
  final List<StoreCreatorCard> loaded;

  /// 이 세션에서 결정해 덱에서 빠진 카드의 크리에이터 id.
  final Set<String> done;
  final DiscoveryToast? toast;

  /// 아직 결정하지 않은 카드(덱에 넘기는 목록).
  List<StoreCreatorCard> get remaining => [
    for (final c in loaded)
      if (!done.contains(c.creatorId)) c,
  ];

  /// 오늘 아예 카드가 없다(다 본 것과 다르다).
  bool get nothingToday => loaded.isEmpty && total == 0;

  /// 오늘 이미 결정한 카드가 있을 수 있다는 뜻(되돌릴 수 있다).
  bool get canUndo => total - remaining.length > 0;

  StoreDiscoverState copyWith({
    int? total,
    List<StoreCreatorCard>? loaded,
    Set<String>? done,
    DiscoveryToast? toast,
    bool clearToast = false,
  }) => StoreDiscoverState(
    total: total ?? this.total,
    loaded: loaded ?? this.loaded,
    done: done ?? this.done,
    toast: clearToast ? null : (toast ?? this.toast),
  );
}

class StoreDiscoverViewModel extends AsyncNotifier<StoreDiscoverState> {
  int _serial = 0;

  @override
  Future<StoreDiscoverState> build() async {
    final result = await ref.read(storeDiscoverRepositoryProvider).fetchCards();
    return StoreDiscoverState(total: result.total, loaded: result.cards);
  }

  DiscoveryToast _toast(
    DiscoveryToastKind kind, {
    DiscoveryTarget? target,
    String? message,
  }) => DiscoveryToast(
    kind: kind,
    serial: ++_serial,
    target: target,
    message: message,
  );

  /// [card]에 결정을 보낸다. 성공하면 그 카드는 덱에서 빠지고 알림 문구가 뜬다. 실패하면 던지고
  /// 아무것도 바꾸지 않는다(덱이 카드를 제자리로 돌려놓는다). 안내는 부른 쪽이 한다. 사장님의 하트는
  /// 서로 관심을 바로 알리지 않으므로 하트 알림만 있다.
  Future<void> decide(StoreCreatorCard card, SwipeOutcome outcome) async {
    final current = state.value;
    if (current == null || current.done.contains(card.creatorId)) return;
    await ref
        .read(storeDiscoverRepositoryProvider)
        .decide(card.creatorId, outcome);
    if (!ref.mounted) return;
    final latest = state.value ?? current;
    final toast = switch (outcome) {
      SwipeOutcome.pass => _toast(
        DiscoveryToastKind.pass,
        target: DiscoveryTarget.creator(card.creatorId),
      ),
      SwipeOutcome.like => _toast(DiscoveryToastKind.like),
      SwipeOutcome.hold => _toast(DiscoveryToastKind.hold),
    };
    state = AsyncData(
      latest.copyWith(done: {...latest.done, card.creatorId}, toast: toast),
    );
  }

  /// 넘긴 [creatorId]에 이유를 남긴다. 실패하면 던진다.
  Future<void> setPassReason(String creatorId, PassReason reason) => ref
      .read(storeDiscoverRepositoryProvider)
      .setPassReason(creatorId, reason);

  /// 마지막 결정을 되돌린다. 되돌린 카드는 덱 맨 앞에 다시 놓인다.
  Future<UndoResult> undoLast() async {
    final current = state.value;
    if (current == null) return UndoResult.failed;
    final String? creatorId;
    try {
      creatorId = await ref.read(storeDiscoverRepositoryProvider).undoLast();
    } catch (_) {
      return UndoResult.failed;
    }
    if (!ref.mounted) return UndoResult.undone;
    if (creatorId == null) return UndoResult.nothing;
    final latest = state.value ?? current;
    if (latest.done.contains(creatorId)) {
      state = AsyncData(
        latest.copyWith(
          done: {...latest.done}..remove(creatorId),
          clearToast: true,
        ),
      );
      return UndoResult.undone;
    }
    // 이 세션에서 결정하지 않은 카드(앱을 다시 켠 뒤의 되돌리기)면 오늘 목록을 새로 읽는다.
    try {
      final result = await ref
          .read(storeDiscoverRepositoryProvider)
          .fetchCards();
      if (!ref.mounted) return UndoResult.undone;
      state = AsyncData(
        StoreDiscoverState(total: result.total, loaded: result.cards),
      );
    } catch (_) {
      return UndoResult.failed;
    }
    return UndoResult.undone;
  }

  /// 안내 문구를 띄운다(되돌릴 수 없음, 저장 실패).
  void showNotice(String message) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        toast: _toast(DiscoveryToastKind.notice, message: message),
      ),
    );
  }

  /// 3초가 지났거나 닫을 때. 그 사이 새 알림이 떴으면([serial]이 다르면) 건드리지 않는다.
  void dismissToast(int serial) {
    final current = state.value;
    if (current == null || current.toast?.serial != serial) return;
    state = AsyncData(current.copyWith(clearToast: true));
  }

  /// 오늘 목록을 다시 읽는다(불러오기 실패 뒤 `다시 시도`).
  void reload() => ref.invalidateSelf();
}
