import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/current_user_provider.dart';
import '../../../onboarding/presentation/viewmodels/me_view_model.dart';
import '../../domain/app_notification.dart';
import '../../domain/notification_repository.dart';
import '../notification_text.dart';
import 'unread_count_view_model.dart';

/// 지금 고른 탭. 화면을 떠나면 `전체`로 돌아간다.
final notificationTabProvider =
    NotifierProvider.autoDispose<
      NotificationTabNotifier,
      NotificationTabFilter
    >(NotificationTabNotifier.new);

class NotificationTabNotifier extends Notifier<NotificationTabFilter> {
  @override
  NotificationTabFilter build() => NotificationTabFilter.all;

  void select(NotificationTabFilter tab) => state = tab;
}

class NotificationsState {
  const NotificationsState({
    required this.items,
    this.nextCursor,
    this.loadingMore = false,
    this.notice,
  });

  final List<AppNotification> items;

  /// 다음 쪽을 부르는 값. null이면 마지막 쪽이다.
  final String? nextCursor;
  final bool loadingMore;

  /// 화면에 잠깐 보일 안내(더 불러오기·읽음 처리 실패).
  final String? notice;

  NotificationsState copyWith({
    List<AppNotification>? items,
    String? nextCursor,
    bool? loadingMore,
    String? notice,
    bool clearNotice = false,
  }) => NotificationsState(
    items: items ?? this.items,
    nextCursor: nextCursor ?? this.nextCursor,
    loadingMore: loadingMore ?? this.loadingMore,
    notice: clearNotice ? null : (notice ?? this.notice),
  );
}

/// 알림함(E3). 고른 탭의 알림을 서버에서 읽고, 아래로 내리면 다음 쪽을 이어 붙인다. 탭을 바꾸면
/// 새로 읽는다.
///
/// Riverpod의 자동 재시도는 끈다(읽기 실패는 화면의 "다시 시도"가 다시 부른다).
final notificationsViewModelProvider =
    AsyncNotifierProvider.autoDispose<
      NotificationsViewModel,
      NotificationsState
    >(NotificationsViewModel.new, retry: (_, _) => null);

class NotificationsViewModel extends AsyncNotifier<NotificationsState> {
  NotificationRepository get _repo => ref.read(notificationRepositoryProvider);

  /// 읽음 처리를 서버에 보내는 중인 모두 읽음. 연달아 눌러도 한 번만 보낸다.
  bool _readingAll = false;

  @override
  Future<NotificationsState> build() async {
    ref.watch(currentUserIdProvider);
    ref.watch(meViewModelProvider.select((me) => me.value?.role));
    final tab = ref.watch(notificationTabProvider);
    final page = await _repo.fetch(tab);
    return NotificationsState(items: page.items, nextCursor: page.nextCursor);
  }

  void selectTab(NotificationTabFilter tab) =>
      ref.read(notificationTabProvider.notifier).select(tab);

  /// 다음 쪽을 이어 붙인다. 이미 불러오는 중이거나 마지막 쪽이면 아무것도 하지 않는다.
  Future<void> loadMore() async {
    final current = state.value;
    final cursor = current?.nextCursor;
    if (current == null || cursor == null || current.loadingMore) return;
    final tab = ref.read(notificationTabProvider);
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final page = await _repo.fetch(tab, cursor: cursor);
      // 기다리는 사이 탭이 바뀌었으면 이 쪽은 이전 탭의 것이라 버린다(탭이 바뀌면 build가 새로 읽는다).
      if (!ref.mounted || ref.read(notificationTabProvider) != tab) return;
      final latest = state.value ?? current;
      final known = {for (final n in latest.items) n.id};
      state = AsyncData(
        NotificationsState(
          items: [
            ...latest.items,
            for (final n in page.items)
              if (!known.contains(n.id)) n,
          ],
          nextCursor: page.nextCursor,
        ),
      );
    } on NotificationFailure {
      if (!ref.mounted || ref.read(notificationTabProvider) != tab) return;
      state = AsyncData(
        (state.value ?? current).copyWith(
          loadingMore: false,
          notice: NotificationTexts.moreFailed,
        ),
      );
    }
  }

  /// 줄 하나를 읽음으로 바꾼다. 화면은 바로 바꾸고 서버가 거절하면 되돌린다.
  Future<void> markRead(String id) async {
    final current = state.value;
    if (current == null) return;
    final index = current.items.indexWhere((n) => n.id == id);
    if (index < 0 || current.items[index].read) return;
    _setRead(id, true);
    try {
      await _repo.read(id);
    } on NotificationFailure {
      if (ref.mounted) _setRead(id, false);
    }
    // 종의 점과 숫자를 서버 값으로 다시 맞춘다.
    if (ref.mounted) ref.invalidate(unreadCountViewModelProvider);
  }

  /// 모든 줄을 읽음으로 바꾼다(고른 탭과 상관없이 서버가 지금 역할의 알림 전부를 바꾼다).
  Future<void> readAll() async {
    if (_readingAll || state.value == null) return;
    _readingAll = true;
    try {
      await _repo.readAll();
      if (!ref.mounted) return;
      final current = state.value;
      if (current != null) {
        state = AsyncData(
          current.copyWith(
            items: [for (final n in current.items) n.copyWith(read: true)],
          ),
        );
      }
    } on NotificationFailure {
      final current = state.value;
      if (ref.mounted && current != null) {
        state = AsyncData(
          current.copyWith(notice: NotificationTexts.readFailed),
        );
      }
    } finally {
      _readingAll = false;
    }
    if (ref.mounted) ref.invalidate(unreadCountViewModelProvider);
  }

  void clearNotice() {
    final current = state.value;
    if (current == null || current.notice == null) return;
    state = AsyncData(current.copyWith(clearNotice: true));
  }

  void _setRead(String id, bool read) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        items: [
          for (final n in current.items)
            if (n.id == id) n.copyWith(read: read) else n,
        ],
      ),
    );
  }
}
