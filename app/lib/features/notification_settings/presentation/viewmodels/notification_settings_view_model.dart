import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/current_user_provider.dart';
import '../../domain/notification_settings.dart';
import '../../domain/notification_settings_repository.dart';
import '../notification_settings_text.dart';

class NotificationSettingsState {
  const NotificationSettingsState({required this.settings, this.notice});

  /// 화면에 보이는 값. 아직 서버가 확인하지 않은 변경이 이미 들어 있다.
  final NotificationSettings settings;

  /// 화면에 3초 동안 보일 안내(저장 실패).
  final String? notice;
}

/// 알림 설정(E5). 스위치나 방해 금지를 누르면 화면을 바로 바꾸고 저장 요청을 보낸다. 실패하면 그
/// 칸만 서버가 마지막으로 확인해 준 값으로 되돌리고 안내를 띄운다.
///
/// 저장 요청은 한 줄로 차례대로 보낸다. 빠르게 두 칸을 누르면 두 요청이 겹쳐 나중 응답이 먼저
/// 도착한 값을 덮을 수 있고, 서버 API가 설정 전체를 교체하는 `PUT`이라서다. 각 요청은 "서버가 확인한
/// 값에 이번 변경만 더한 것"을 보낸다.
///
/// Riverpod의 자동 재시도는 끈다(읽기 실패는 화면의 "다시 시도"가 다시 부른다).
final notificationSettingsViewModelProvider =
    AsyncNotifierProvider.autoDispose<
      NotificationSettingsViewModel,
      NotificationSettingsState
    >(NotificationSettingsViewModel.new, retry: (_, _) => null);

class NotificationSettingsViewModel
    extends AsyncNotifier<NotificationSettingsState> {
  NotificationSettingsRepository get _repo =>
      ref.read(notificationSettingsRepositoryProvider);

  /// 서버가 마지막으로 확인해 준 값.
  late NotificationSettings _confirmed;

  Future<void> _queue = Future.value();

  @override
  Future<NotificationSettingsState> build() async {
    ref.watch(currentUserIdProvider);
    _queue = Future.value();
    _confirmed = await _repo.fetch();
    return NotificationSettingsState(settings: _confirmed);
  }

  void toggle(NotificationSwitch s) {
    final current = state.value?.settings;
    if (current == null) return;
    final next = !current.isOn(s);
    _apply(
      (base) => base.withSwitch(s, next),
      (shown) => shown.withSwitch(s, _confirmed.isOn(s)),
      (shown) => shown.isOn(s) == next,
    );
  }

  void selectQuietHours(QuietHours value) {
    final current = state.value?.settings;
    if (current == null || current.quietHours == value) return;
    _apply(
      (base) => base.withQuietHours(value),
      (shown) => shown.withQuietHours(_confirmed.quietHours),
      (shown) => shown.quietHours == value,
    );
  }

  void clearNotice() {
    final current = state.value;
    if (current == null || current.notice == null) return;
    state = AsyncData(NotificationSettingsState(settings: current.settings));
  }

  /// [change]를 화면에 바로 적용하고 저장 줄에 올린다. 실패하면 [revert]로 그 칸만 되돌리되, 그
  /// 사이 사용자가 그 칸을 다시 바꿨으면([stillMine]이 false) 건드리지 않는다.
  void _apply(
    NotificationSettings Function(NotificationSettings) change,
    NotificationSettings Function(NotificationSettings) revert,
    bool Function(NotificationSettings) stillMine,
  ) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      NotificationSettingsState(settings: change(current.settings)),
    );
    _queue = _queue.then((_) async {
      if (!ref.mounted) return;
      try {
        _confirmed = await _repo.save(change(_confirmed));
      } on NotificationSettingsFailure {
        if (!ref.mounted) return;
        final shown = state.value?.settings ?? _confirmed;
        state = AsyncData(
          NotificationSettingsState(
            settings: stillMine(shown) ? revert(shown) : shown,
            notice: NotificationSettingsTexts.saveFailed,
          ),
        );
      }
    });
  }
}
