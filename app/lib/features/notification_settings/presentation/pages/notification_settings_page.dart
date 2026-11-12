import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/navigation/role_entry.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shadows.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_error_view.dart';
import '../../../../core/ui/cora_page_header.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../onboarding/presentation/viewmodels/me_view_model.dart';
import '../../domain/notification_settings.dart';
import '../notification_settings_text.dart';
import '../viewmodels/notification_settings_view_model.dart';

/// E5 알림 설정(NNotifySettings / DarkNNotifySettings). 머리, 제목, 스위치 다섯, 방해 금지 시간.
/// 누르면 바로 저장한다(저장 버튼이 없다).
class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});

  /// 안내를 보여 주는 시간(설계 E5: 3초).
  static const noticeFor = Duration(seconds: 3);

  @override
  ConsumerState<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends ConsumerState<NotificationSettingsPage> {
  Timer? _noticeTimer;

  @override
  void dispose() {
    _noticeTimer?.cancel();
    super.dispose();
  }

  void _onNotice(String? message) {
    _noticeTimer?.cancel();
    if (message == null) return;
    _noticeTimer = Timer(NotificationSettingsPage.noticeFor, () {
      if (mounted) {
        ref.read(notificationSettingsViewModelProvider.notifier).clearNotice();
      }
    });
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    final role = ref.read(meViewModelProvider).value?.role;
    context.go(role == null ? AppRoutes.splash : roleHomePath(role));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      notificationSettingsViewModelProvider.select((a) => a.value?.notice),
      (_, next) => _onNotice(next),
    );
    final async = ref.watch(notificationSettingsViewModelProvider);
    final vm = ref.read(notificationSettingsViewModelProvider.notifier);
    final notice = async.value?.notice;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                CoraPageHeader(
                  title: NotificationSettingsTexts.title,
                  onBack: _back,
                  extent: 64,
                ),
                Expanded(
                  child: switch (async) {
                    AsyncData(:final value) => _Body(
                      settings: value.settings,
                      onToggle: vm.toggle,
                      onQuiet: vm.selectQuietHours,
                    ),
                    AsyncError(isLoading: false) => CoraErrorView(
                      message: NotificationSettingsTexts.loadFailed,
                      onRetry: () =>
                          ref.invalidate(notificationSettingsViewModelProvider),
                    ),
                    _ => const SizedBox.expand(),
                  },
                ),
              ],
            ),
            if (notice != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.viewPaddingOf(context).bottom + 32,
                  ),
                  child: _Notice(message: notice),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.settings,
    required this.onToggle,
    required this.onQuiet,
  });

  final NotificationSettings settings;
  final ValueChanged<NotificationSwitch> onToggle;
  final ValueChanged<QuietHours> onQuiet;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: 32 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 위 8, 좌우 24(NNotifySettings `h1` 상자).
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Semantics(
              header: true,
              child: Text(
                NotificationSettingsTexts.heading,
                style: CoraTextStyles.title.copyWith(color: c.text),
              ),
            ),
          ),
          // 위 20, 좌우 16, 안쪽 위아래 4, 둥근 22.
          Container(
            margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(CoraRadius.panel),
            ),
            child: Column(
              children: [
                for (final s in NotificationSwitch.values)
                  _SwitchRow(
                    which: s,
                    on: settings.isOn(s),
                    onTap: () => onToggle(s),
                  ),
              ],
            ),
          ),
          // 위 14, 좌우 16, 안쪽 14·16, 둥근 22.
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(CoraRadius.panel),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  NotificationSettingsTexts.quietTitle,
                  style: CoraTextStyles.listLabel.copyWith(color: c.text),
                ),
                const SizedBox(height: 10),
                // 같은 폭 셋, 간격 6. 글자가 길어져 줄이 바뀌어도 높이가 같게 맞춘다.
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 6,
                    children: [
                      for (final q in QuietHours.values)
                        Expanded(
                          child: _QuietOption(
                            which: q,
                            selected: settings.quietHours == q,
                            onTap: () => onQuiet(q),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 스위치 줄(최소 높이 64, 안쪽 8·16, 간격 12). 왼쪽 이름 15와 설명 12 보조, 오른쪽 스위치 48 x 28.
class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.which,
    required this.on,
    required this.onTap,
  });

  final NotificationSwitch which;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (label, sub) = NotificationSettingsTexts.switches[which]!;
    return Semantics(
      container: true,
      toggled: on,
      label: label,
      hint: sub,
      onTap: onTap,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onTap,
          child: ConstrainedBox(
            key: ValueKey('notification-switch-${which.name}'),
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: CoraTextStyles.listLabel.copyWith(
                            color: c.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          sub,
                          style: CoraTextStyles.fieldLabel.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _SwitchGraphic(on: on, which: which),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 스위치 그림 48 x 28(둥근 14). 켜짐은 `accent`, 꺼짐은 `switchTrackOff`. 손잡이 22는 위 3,
/// 켜짐 왼쪽 23 / 꺼짐 3이고 그림자 0 1 3 rgba(0,0,0,0.2).
class _SwitchGraphic extends StatelessWidget {
  const _SwitchGraphic({required this.on, required this.which});

  final bool on;
  final NotificationSwitch which;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      key: ValueKey('notification-switch-track-${which.name}'),
      decoration: BoxDecoration(
        color: on ? c.accent : c.switchTrackOff,
        borderRadius: BorderRadius.circular(14),
      ),
      child: SizedBox(
        width: 48,
        height: 28,
        child: Stack(
          children: [
            Positioned(
              top: 3,
              left: on ? 23 : 3,
              child: DecoratedBox(
                key: ValueKey('notification-switch-knob-${which.name}'),
                decoration: BoxDecoration(
                  color: c.switchKnob,
                  shape: BoxShape.circle,
                  boxShadow: CoraShadows.switchKnob,
                ),
                child: const SizedBox.square(dimension: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 방해 금지 버튼(최소 높이 40, 알약, 13/500). 고른 것은 `quietSelected` 바탕, 나머지는 투명.
class _QuietOption extends StatelessWidget {
  const _QuietOption({
    required this.which,
    required this.selected,
    required this.onTap,
  });

  final QuietHours which;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final label = NotificationSettingsTexts.quietOptions[which]!;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onTap,
          child: Container(
            key: ValueKey('notification-quiet-${which.name}'),
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? c.quietSelected : Colors.transparent,
              borderRadius: BorderRadius.circular(CoraRadius.pill),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: CoraTextStyles.label.copyWith(color: c.text),
            ),
          ),
        ),
      ),
    );
  }
}

/// 아래에 잠깐 뜨는 안내(캔버스에 없다). 본문색 바탕에 배경색 글자라 라이트·다크 모두 읽힌다.
class _Notice extends StatelessWidget {
  const _Notice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return IgnorePointer(
      child: Semantics(
        liveRegion: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.text,
            borderRadius: BorderRadius.circular(CoraRadius.pill),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Text(
              message,
              style: CoraTextStyles.label.copyWith(color: c.background),
            ),
          ),
        ),
      ),
    );
  }
}
