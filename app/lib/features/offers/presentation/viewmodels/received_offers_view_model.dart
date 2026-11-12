import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../collaboration/presentation/viewmodels/collaboration_list_view_model.dart';
import '../../domain/offer_view.dart';
import '../../domain/received_offer.dart';
import '../../domain/received_offers_repository.dart';

/// 거절한 뒤 되돌릴 수 있는 시간. 서버도 30초 동안만 되돌려 준다. 테스트가 짧게 바꿔 끼운다.
final undoDeclineWindowProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 30),
);

final receivedOffersViewModelProvider =
    AsyncNotifierProvider.autoDispose<
      ReceivedOffersViewModel,
      ReceivedOffersState
    >(ReceivedOffersViewModel.new, retry: (_, _) => null);

enum ReceivedOffersTab { newOffers, active }

/// 화면에 알릴 일. 문구는 화면이 정한다.
enum ReceivedOffersNotice {
  /// 그사이 상대나 다른 기기에서 이미 처리됐다(409).
  alreadyHandled,

  /// 수락·거절·되돌리기가 실패했다.
  failed,
}

class ReceivedOffersState {
  const ReceivedOffersState({
    required this.newOffers,
    this.tab = ReceivedOffersTab.newOffers,
    this.busy = false,
    this.accepted = false,
    this.notice,
  });

  /// 새 오퍼. 도착한 순서이고 맨 앞이 지금 보이는 카드다. 방금 거절한 오퍼는 되돌릴 수 있는 동안
  /// 맨 앞에 `declined`로 남는다.
  final List<ReceivedOffer> newOffers;
  final ReceivedOffersTab tab;

  /// 수락·거절·되돌리기를 서버에 보내는 중. 그동안은 다시 누르지 못한다.
  final bool busy;

  /// 방금 수락했다: `수락했어요.` 안내를 보여 주는 중.
  final bool accepted;
  final ReceivedOffersNotice? notice;

  ReceivedOffer? get current => newOffers.isEmpty ? null : newOffers.first;

  /// 탭에 보이는 새 오퍼 수. 방금 거절한 오퍼는 세지 않는다.
  int get waitingCount =>
      newOffers.where((o) => o.view == OfferView.waiting).length;

  ReceivedOffersState copyWith({
    List<ReceivedOffer>? newOffers,
    ReceivedOffersTab? tab,
    bool? busy,
    bool? accepted,
    ReceivedOffersNotice? notice,
    bool clearNotice = false,
  }) => ReceivedOffersState(
    newOffers: newOffers ?? this.newOffers,
    tab: tab ?? this.tab,
    busy: busy ?? this.busy,
    accepted: accepted ?? this.accepted,
    notice: clearNotice ? null : (notice ?? this.notice),
  );
}

class ReceivedOffersViewModel extends AsyncNotifier<ReceivedOffersState> {
  Timer? _undoTimer;

  @override
  Future<ReceivedOffersState> build() async {
    ref.onDispose(() => _undoTimer?.cancel());
    final loaded = await _load();
    _armIfDeclined(loaded);
    return loaded;
  }

  Future<ReceivedOffersState> _load() async {
    final repo = ref.read(receivedOffersRepositoryProvider);
    return ReceivedOffersState(newOffers: await repo.fetchNew());
  }

  /// 맨 앞 카드가 방금 거절한 오퍼이면 되돌리기 시간을 센다.
  void _armIfDeclined(ReceivedOffersState s) {
    _undoTimer?.cancel();
    final head = s.current;
    if (head == null || head.view != OfferView.declined) return;
    _undoTimer = Timer(
      ref.read(undoDeclineWindowProvider),
      () => _dismiss(head.id),
    );
  }

  /// 되돌리기 시간이 지났거나 `다음 오퍼 보기`를 눌렀다: 거절한 카드를 걷어 내고 다음 카드로.
  void _dismiss(String id) {
    final s = state.value;
    final head = s?.current;
    if (!ref.mounted || s == null || head == null || head.id != id) return;
    if (head.view != OfferView.declined) return;
    _undoTimer?.cancel();
    final next = s.copyWith(newOffers: s.newOffers.skip(1).toList());
    state = AsyncData(next);
    _armIfDeclined(next);
  }

  void nextOffer() {
    final head = state.value?.current;
    if (head != null) _dismiss(head.id);
  }

  void selectTab(ReceivedOffersTab tab) {
    final s = state.value;
    if (s == null || s.tab == tab) return;
    state = AsyncData(s.copyWith(tab: tab, clearNotice: true));
  }

  Future<void> decline() => _answer((repo, offer) async {
    await repo.decline(offer.id);
    return (ReceivedOffersState s) {
      final declined = offer.copyWith(
        view: OfferView.declined,
        canUndoDecline: true,
      );
      return s.copyWith(newOffers: [declined, ...s.newOffers.skip(1)]);
    };
  });

  Future<void> undoDecline() => _answer((repo, offer) async {
    await repo.undoDecline(offer.id);
    return (ReceivedOffersState s) {
      final restored = offer.copyWith(
        view: OfferView.waiting,
        canUndoDecline: false,
      );
      return s.copyWith(newOffers: [restored, ...s.newOffers.skip(1)]);
    };
  });

  Future<void> accept() => _answer((repo, offer) async {
    await repo.accept(offer.id);
    return (ReceivedOffersState s) =>
        s.copyWith(newOffers: s.newOffers.skip(1).toList(), accepted: true);
  });

  /// 맨 앞 카드에 답한다. 서버에 보낸 뒤 상태를 바꾸는 함수를 돌려받아 적용한다.
  Future<void> _answer(
    Future<ReceivedOffersState Function(ReceivedOffersState)> Function(
      ReceivedOffersRepository repo,
      ReceivedOffer offer,
    )
    send,
  ) async {
    final current = state.value;
    final offer = current?.current;
    if (current == null || offer == null || current.busy) return;
    _undoTimer?.cancel();
    state = AsyncData(current.copyWith(busy: true, clearNotice: true));
    try {
      final apply = await send(
        ref.read(receivedOffersRepositoryProvider),
        offer,
      );
      if (!ref.mounted) return;
      final latest = state.value ?? current;
      final next = apply(latest.copyWith(busy: false));
      state = AsyncData(next);
      _armIfDeclined(next);
      // 수락하면 서버가 협업을 만든다. 진행 중 탭은 열릴 때 새로 읽지만, 이미 열려 있던 목록이
      // 있으면 낡지 않게 무효화한다.
      if (next.accepted && !latest.accepted) {
        ref.invalidate(collaborationListViewModelProvider);
      }
    } on ReceivedOffersFailure catch (error) {
      if (!ref.mounted) return;
      if (error.conflict) {
        await _refreshWith(ReceivedOffersNotice.alreadyHandled);
      } else {
        final latest = state.value ?? current;
        state = AsyncData(
          latest.copyWith(busy: false, notice: ReceivedOffersNotice.failed),
        );
        _armIfDeclined(latest);
      }
    } catch (_) {
      if (!ref.mounted) return;
      final latest = state.value ?? current;
      state = AsyncData(
        latest.copyWith(busy: false, notice: ReceivedOffersNotice.failed),
      );
      _armIfDeclined(latest);
    }
  }

  /// 목록을 서버의 지금 상태로 맞추고 [notice]를 알린다(이미 처리된 오퍼를 눌렀을 때).
  Future<void> _refreshWith(ReceivedOffersNotice notice) async {
    final current = state.value;
    try {
      final loaded = await _load();
      if (!ref.mounted) return;
      final next = loaded.copyWith(tab: current?.tab, notice: notice);
      state = AsyncData(next);
      _armIfDeclined(next);
    } catch (_) {
      if (!ref.mounted || current == null) return;
      state = AsyncData(current.copyWith(busy: false, notice: notice));
    }
  }

  /// 연동하고 돌아온 뒤처럼 서버의 지금 상태로 새 오퍼 목록을 다시 맞춘다. 실패하면 보던 내용을 둔다.
  Future<void> refresh() async {
    final current = state.value;
    if (current == null) return;
    try {
      final fresh = await ref.read(receivedOffersRepositoryProvider).fetchNew();
      if (!ref.mounted) return;
      final latest = state.value ?? current;
      // 거절을 되돌릴 수 있는 동안의 맨 앞 카드는 서버 목록과 다르게 로컬에서만 들고 있다.
      final head = latest.current;
      final keepHead = head != null && head.view == OfferView.declined;
      final next = latest.copyWith(
        newOffers: keepHead
            ? [head, ...fresh.where((o) => o.id != head.id)]
            : fresh,
      );
      state = AsyncData(next);
      _armIfDeclined(next);
    } catch (_) {
      // 못 읽어도 보던 카드는 그대로다.
    }
  }

  /// `확인`: 수락 안내를 닫고 진행 중 탭으로 간다.
  void confirmAccepted() {
    final s = state.value;
    if (s == null) return;
    state = AsyncData(
      s.copyWith(
        accepted: false,
        tab: ReceivedOffersTab.active,
        clearNotice: true,
      ),
    );
  }
}
