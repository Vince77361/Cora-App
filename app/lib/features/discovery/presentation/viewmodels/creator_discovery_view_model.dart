import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/swipe_deck/swipe_physics.dart' show SwipeOutcome;
import '../../../principles/domain/principles_repository.dart';
import '../../../store_browse/domain/store_browse_repository.dart';
import '../../domain/discovery_card.dart';
import '../../domain/discovery_repository.dart';
import '../../domain/discovery_target.dart';
import '../../domain/pass_reason.dart';
import '../../domain/undo_result.dart';

export '../../domain/undo_result.dart';

/// 크리에이터의 발견(08). 화면을 떠나면 버리고 다시 열 때 오늘 목록을 새로 읽는다.
final creatorDiscoveryViewModelProvider =
    AsyncNotifierProvider.autoDispose<
      CreatorDiscoveryViewModel,
      CreatorDiscoveryState
    >(CreatorDiscoveryViewModel.new);

enum CreatorToastKind { pass, like, hold, match, applied, notice }

/// 카드 위에 3초 뜨는 알림 문구 하나. [serial]이 바뀌면 새 알림이다(3초를 다시 센다).
class CreatorToast {
  const CreatorToast({
    required this.kind,
    required this.serial,
    this.brandName,
    this.collaborationId,
    this.target,
    this.message,
  });

  final CreatorToastKind kind;
  final int serial;

  /// 서로 관심이 닿은 브랜드의 이름(`match`).
  final String? brandName;

  /// 서로 관심이 닿아 생긴 협업(`match`).
  final String? collaborationId;

  /// 넘긴 대상(`pass`). `이유 남기기`가 이 대상에 이유를 남긴다. 캠페인과 가게 모두 올 수 있다.
  final DiscoveryTarget? target;

  /// 안내 문구(`notice`).
  final String? message;
}

class CreatorDiscoveryState {
  const CreatorDiscoveryState({
    required this.total,
    required this.loaded,
    this.principlesMissing = false,
    this.done = const {},
    this.toast,
  });

  /// 오늘 목록 전체(이미 결정한 카드 포함).
  final int total;

  /// 불러온 카드를 추천 순서대로. 이 세션에서 결정한 카드도 남아 있다.
  final List<DiscoveryCard> loaded;

  /// 협업 원칙을 아직 정하지 않았다(화면 위 띠를 보인다). 원칙을 읽지 못한 경우는 false다.
  final bool principlesMissing;

  /// 이 세션에서 결정해 덱에서 빠진 카드의 대상.
  final Set<DiscoveryTarget> done;
  final CreatorToast? toast;

  /// 아직 결정하지 않은 카드(덱에 넘기는 목록).
  List<DiscoveryCard> get remaining => [
    for (final c in loaded)
      if (!done.contains(c.target)) c,
  ];

  /// 오늘 이미 결정한 카드 수(되돌리기가 있을 수 있다는 뜻).
  int get decided => total - remaining.length;

  bool get canUndo => decided > 0;

  /// [card]의 `{n} / {total}`에서 n. 불러오기 전에 이미 결정한 카드 수를 앞에 더한다.
  int positionOf(DiscoveryCard card) =>
      (total - loaded.length) + loaded.indexOf(card) + 1;

  CreatorDiscoveryState copyWith({
    int? total,
    List<DiscoveryCard>? loaded,
    bool? principlesMissing,
    Set<DiscoveryTarget>? done,
    CreatorToast? toast,
    bool clearToast = false,
  }) => CreatorDiscoveryState(
    total: total ?? this.total,
    loaded: loaded ?? this.loaded,
    principlesMissing: principlesMissing ?? this.principlesMissing,
    done: done ?? this.done,
    toast: clearToast ? null : (toast ?? this.toast),
  );
}

class CreatorDiscoveryViewModel extends AsyncNotifier<CreatorDiscoveryState> {
  int _serial = 0;

  @override
  Future<CreatorDiscoveryState> build() async {
    final listing = ref.read(discoveryRepositoryProvider).fetchCampaignCards();
    final missing = _principlesMissing();
    final list = await listing;
    return CreatorDiscoveryState(
      total: list.total,
      loaded: list.cards,
      principlesMissing: await missing,
    );
  }

  /// 협업 원칙을 정하지 않았으면 true. 원칙을 읽지 못하면 띠로 막지 않고 false다.
  Future<bool> _principlesMissing() async {
    try {
      return await ref.read(principlesRepositoryProvider).fetchMine() == null;
    } catch (_) {
      return false;
    }
  }

  CreatorToast _toast(
    CreatorToastKind kind, {
    String? brandName,
    String? collaborationId,
    DiscoveryTarget? target,
    String? message,
  }) => CreatorToast(
    kind: kind,
    serial: ++_serial,
    brandName: brandName,
    collaborationId: collaborationId,
    target: target,
    message: message,
  );

  /// [card]에 결정을 보낸다. 성공하면 그 카드는 덱에서 빠지고 알림 문구가 뜬다. 실패하면 던지고
  /// 아무것도 바꾸지 않는다(덱이 카드를 제자리로 돌려놓는다). 안내는 부른 쪽이 한다.
  ///
  /// 가게 카드는 오른쪽(지원)과 넘김만 있다. 오른쪽은 가게 흐름의 `조건 그대로 지원`과 같은 호출이고,
  /// 이미 지원했거나 오퍼가 온 가게(서버 409)는 이미 된 일로 보고 카드를 치운다.
  /// 가게에는 보류가 없어서 보내지 않고 아무것도 하지 않는다.
  Future<void> decide(DiscoveryCard card, SwipeOutcome outcome) async {
    // D1이 목록을 읽기 전에 결정을 보낼 수 있다(03에서 D1로 온 경우).
    final current = state.value ?? await future;
    if (current.done.contains(card.target)) return;
    final repo = ref.read(discoveryRepositoryProvider);
    final target = card.target;
    final CreatorToast toast;
    String? collaborationId;
    switch (card) {
      case StoreCard():
        switch (outcome) {
          case SwipeOutcome.hold:
            return;
          case SwipeOutcome.like:
            try {
              await ref
                  .read(storeBrowseRepositoryProvider)
                  .apply(card.store.id);
            } on StoreBrowseFailure catch (error) {
              if (!error.conflict) rethrow;
            }
            toast = _toast(CreatorToastKind.applied);
          case SwipeOutcome.pass:
            await repo.decide(target, outcome);
            toast = _toast(CreatorToastKind.pass, target: target);
        }
      case CampaignCard():
        final result = await repo.decide(target, outcome);
        collaborationId = result.collaborationId;
        toast = result.matched && outcome == SwipeOutcome.like
            ? _toast(
                CreatorToastKind.match,
                brandName: card.brandName,
                collaborationId: collaborationId,
              )
            : switch (outcome) {
                SwipeOutcome.pass => _toast(
                  CreatorToastKind.pass,
                  target: target,
                ),
                SwipeOutcome.like => _toast(CreatorToastKind.like),
                SwipeOutcome.hold => _toast(CreatorToastKind.hold),
              };
    }
    if (!ref.mounted) return;
    final latest = state.value ?? current;
    state = AsyncData(
      latest.copyWith(done: {...latest.done, target}, toast: toast),
    );
  }

  /// 넘긴 [target]에 이유를 남긴다. 실패하면 던진다.
  Future<void> setPassReason(DiscoveryTarget target, PassReason reason) =>
      ref.read(discoveryRepositoryProvider).setPassReason(target, reason);

  /// 마지막 결정을 되돌린다. 되돌린 카드는 덱 맨 앞에 다시 놓인다. 지원(가게 카드의 오른쪽)은
  /// 서버의 결정 기록에 없어서 되돌리지 못한다(지원 취소는 D2에서 한다).
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
    if (latest.done.contains(target)) {
      // 이 세션에서 넘긴 카드면 그대로 다시 놓는다.
      state = AsyncData(
        latest.copyWith(
          done: {...latest.done}..remove(target),
          clearToast: true,
        ),
      );
      return UndoResult.undone;
    }
    // 이 세션에서 결정하지 않은 카드(앱을 다시 켠 뒤의 되돌리기)면 오늘 목록을 새로 읽는다.
    try {
      final list = await ref
          .read(discoveryRepositoryProvider)
          .fetchCampaignCards();
      if (!ref.mounted) return UndoResult.undone;
      state = AsyncData(
        latest.copyWith(
          total: list.total,
          loaded: list.cards,
          done: const {},
          clearToast: true,
        ),
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
        toast: _toast(CreatorToastKind.notice, message: message),
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
