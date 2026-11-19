import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/swipe_deck/swipe_physics.dart' show SwipeOutcome;
import '../../domain/discovery_card.dart';
import '../../domain/discovery_repository.dart';
import '../../domain/discovery_target.dart';
import '../../domain/discovery_toast.dart';
import '../../domain/pass_reason.dart';
import '../../domain/reward_proposal.dart';
import '../../domain/undo_result.dart';

// 옛 위치에서 가져다 쓰는 다른 화면들이 깨지지 않게 다시 내보낸다.
export '../../domain/discovery_toast.dart';
export '../../domain/undo_result.dart';

/// 브랜드의 발견(01). 화면을 떠나면 버리고 다시 열 때 오늘 목록을 새로 읽는다.
final brandDiscoveryViewModelProvider =
    AsyncNotifierProvider.autoDispose<
      BrandDiscoveryViewModel,
      BrandDiscoveryState
    >(BrandDiscoveryViewModel.new);

class BrandDiscoveryState {
  const BrandDiscoveryState({
    required this.total,
    required this.loaded,
    this.done = const {},
    this.toast,
  });

  /// 오늘 목록 전체(이미 결정한 카드 포함).
  final int total;

  /// 불러온 카드를 추천 순서대로. 이 세션에서 결정한 카드도 남아 있다.
  final List<CreatorCard> loaded;

  /// 이 세션에서 결정해 덱에서 빠진 카드의 크리에이터 id.
  final Set<String> done;
  final DiscoveryToast? toast;

  /// 아직 결정하지 않은 카드(덱에 넘기는 목록).
  List<CreatorCard> get remaining => [
    for (final c in loaded)
      if (!done.contains(c.creatorId)) c,
  ];

  /// 오늘 이미 결정한 카드 수(되돌리기가 있을 수 있다는 뜻).
  int get decided => total - remaining.length;

  bool get canUndo => decided > 0;

  /// [card]의 `{n}/{total}`에서 n. 불러오기 전에 이미 결정한 카드 수를 앞에 더한다.
  int positionOf(CreatorCard card) =>
      (total - loaded.length) + loaded.indexOf(card) + 1;

  BrandDiscoveryState copyWith({
    int? total,
    List<CreatorCard>? loaded,
    Set<String>? done,
    DiscoveryToast? toast,
    bool clearToast = false,
  }) => BrandDiscoveryState(
    total: total ?? this.total,
    loaded: loaded ?? this.loaded,
    done: done ?? this.done,
    toast: clearToast ? null : (toast ?? this.toast),
  );
}

class BrandDiscoveryViewModel extends AsyncNotifier<BrandDiscoveryState> {
  int _serial = 0;

  @override
  Future<BrandDiscoveryState> build() async {
    final result = await ref
        .read(discoveryRepositoryProvider)
        .fetchCreatorCards();
    return BrandDiscoveryState(total: result.total, loaded: result.cards);
  }

  DiscoveryToast _toast(
    DiscoveryToastKind kind, {
    String? name,
    String? collaborationId,
    DiscoveryTarget? target,
    String? message,
  }) => DiscoveryToast(
    kind: kind,
    serial: ++_serial,
    name: name,
    collaborationId: collaborationId,
    target: target,
    message: message,
  );

  /// [card]에 결정을 보낸다. 성공하면 그 카드는 덱에서 빠지고 알림 문구가 뜬다. 실패하면 던지고
  /// 아무것도 바꾸지 않는다(덱이 카드를 제자리로 돌려놓는다). 안내는 부른 쪽이 한다.
  Future<void> decide(
    CreatorCard card,
    SwipeOutcome outcome, {
    String? note,
    RewardProposal? proposal,
  }) async {
    final current = state.value;
    if (current == null || current.done.contains(card.creatorId)) return;
    final target = DiscoveryTarget.creator(card.creatorId);
    final result = await ref
        .read(discoveryRepositoryProvider)
        .decide(target, outcome, note: note, proposal: proposal);
    if (!ref.mounted) return;
    final latest = state.value ?? current;
    final toast = result.matched && outcome == SwipeOutcome.like
        ? _toast(
            DiscoveryToastKind.match,
            name: card.displayName,
            collaborationId: result.collaborationId,
          )
        : switch (outcome) {
            SwipeOutcome.pass => _toast(
              DiscoveryToastKind.pass,
              target: target,
            ),
            SwipeOutcome.like => _toast(DiscoveryToastKind.like),
            SwipeOutcome.hold => _toast(DiscoveryToastKind.hold),
          };
    state = AsyncData(
      latest.copyWith(done: {...latest.done, card.creatorId}, toast: toast),
    );
  }

  /// 넘긴 [target]에 이유를 남긴다. 실패하면 던진다.
  Future<void> setPassReason(DiscoveryTarget target, PassReason reason) =>
      ref.read(discoveryRepositoryProvider).setPassReason(target, reason);

  /// 마지막 결정을 되돌린다. 되돌린 카드는 덱 맨 앞에 다시 놓인다.
  Future<UndoResult> undoLast() async {
    final current = state.value;
    if (current == null) return UndoResult.failed;
    final DiscoveryTarget? target;
    try {
      target = await ref.read(discoveryRepositoryProvider).undoLast();
    } catch (_) {
      return UndoResult.failed;
    }
    if (!ref.mounted) return UndoResult.undone;
    if (target == null) return UndoResult.nothing;
    final latest = state.value ?? current;
    if (latest.done.contains(target.id)) {
      // 이 세션에서 넘긴 카드면 그대로 다시 놓는다.
      state = AsyncData(
        latest.copyWith(
          done: {...latest.done}..remove(target.id),
          clearToast: true,
        ),
      );
      return UndoResult.undone;
    }
    // 이 세션에서 결정하지 않은 카드(앱을 다시 켠 뒤의 되돌리기)면 오늘 목록을 새로 읽는다.
    try {
      final result = await ref
          .read(discoveryRepositoryProvider)
          .fetchCreatorCards();
      if (!ref.mounted) return UndoResult.undone;
      state = AsyncData(
        BrandDiscoveryState(total: result.total, loaded: result.cards),
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
