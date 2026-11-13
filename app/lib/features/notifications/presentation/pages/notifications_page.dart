import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/navigation/role_entry.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/time/clock.dart';
import '../../../../core/ui/cora_network_photo.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../../../../core/ui/cora_step_header.dart';
import '../../../onboarding/presentation/viewmodels/me_view_model.dart';
import '../../domain/app_notification.dart';
import '../notification_routes.dart';
import '../notification_text.dart';
import '../viewmodels/notifications_view_model.dart';

/// E3 알림(NNotify / DarkNNotify). 머리, 탭, 알림 줄, 아래 `모두 읽음으로 표시`.
/// 줄을 누르면 그 줄만 읽음으로 바꾸고 가리키는 화면으로 간다.
class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  /// 탭의 이름과 서버에 보내는 분류(`전체`, `매칭`, `협업`, `정산`).
  static const tabs = [
    ('전체', NotificationTabFilter.all),
    ('매칭', NotificationTabFilter.matching),
    ('협업', NotificationTabFilter.collaboration),
    ('정산', NotificationTabFilter.settlement),
  ];

  /// 안내를 보여 주는 시간.
  static const noticeFor = Duration(milliseconds: 2500);

  /// 목록 끝에서 이만큼 남으면 다음 쪽을 부른다.
  static const _loadMoreExtent = 320.0;

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  final _scroll = ScrollController();
  Timer? _noticeTimer;

  @override
  void dispose() {
    _noticeTimer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _onNotice(String? message) {
    _noticeTimer?.cancel();
    if (message == null) return;
    _noticeTimer = Timer(NotificationsPage.noticeFor, () {
      if (mounted) {
        ref.read(notificationsViewModelProvider.notifier).clearNotice();
      }
    });
  }

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.extentAfter < NotificationsPage._loadMoreExtent) {
      unawaited(ref.read(notificationsViewModelProvider.notifier).loadMore());
    }
    return false;
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    final role = ref.read(meViewModelProvider).value?.role;
    context.go(role == null ? AppRoutes.splash : roleHomePath(role));
  }

  /// 아직 라우터에 없는 경로(13D가 만드는 화면)는 열지 않는다. 열면 라우터가 첫 화면으로 돌려보낸다.
  bool _routable(String location) => !GoRouter.of(
    context,
  ).configuration.findMatch(Uri.parse(location)).isError;

  void _openSettings() {
    if (_routable(NotificationRoutes.settings)) {
      context.push(NotificationRoutes.settings);
    }
  }

  void _open(AppNotification n) {
    ref.read(notificationsViewModelProvider.notifier).markRead(n.id);
    final role = ref.read(meViewModelProvider).value?.role;
    final location = role == null
        ? null
        : locationFor(n.targetKind, n.targetId, role);
    if (location == null || !_routable(location)) return;
    // 사장님 홈은 이미 아래에 있으므로 닫고 돌아가면서 열 탭(경로)을 홈에 넘긴다. 아래에 홈이 없을
    // 때(알림함이 첫 화면)만 이동한다.
    if (Uri.parse(location).path == AppRoutes.store) {
      if (context.canPop()) {
        context.pop(location);
      } else {
        context.go(location);
      }
    } else {
      context.push(location, extra: AppRoutes.stacked);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      notificationsViewModelProvider.select((a) => a.value?.notice),
      (_, next) => _onNotice(next),
    );
    final tab = ref.watch(notificationTabProvider);
    final async = ref.watch(notificationsViewModelProvider);
    final notice = async.value?.notice;
    final now = ref.watch(clockProvider).now();
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                _Header(onBack: _back, onSettings: _openSettings),
                _Tabs(
                  selected: tab,
                  onChanged: ref
                      .read(notificationsViewModelProvider.notifier)
                      .selectTab,
                ),
                Expanded(
                  child: switch (async) {
                    // 탭을 바꿔 다시 읽는 동안에는 이전 탭의 줄을 보이지 않는다.
                    AsyncData(:final value, isLoading: false) => RefreshIndicator(
                      onRefresh: ref
                          .read(notificationsViewModelProvider.notifier)
                          .refresh,
                      color: context.colors.text,
                      backgroundColor: context.colors.background,
                      child: value.items.isEmpty
                          // 비어 있어도 당길 수 있게 화면 높이의 목록 하나로 감싼다.
                          ? LayoutBuilder(
                              builder: (context, box) => ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(
                                    height: box.maxHeight,
                                    child: const _Empty(),
                                  ),
                                ],
                              ),
                            )
                          : NotificationListener<ScrollNotification>(
                              onNotification: _onScroll,
                              child: ListView.builder(
                                controller: _scroll,
                                physics: const AlwaysScrollableScrollPhysics(),
                                // 위 12, 좌우 8(NNotify `ul`). 아래는 고정 버튼 높이만큼 비운다.
                                padding: EdgeInsets.fromLTRB(
                                  8,
                                  12,
                                  8,
                                  56 + bottom + 12,
                                ),
                                itemCount: value.items.length,
                                itemBuilder: (context, i) {
                                  final n = value.items[i];
                                  return _Row(
                                    notification: n,
                                    now: now,
                                    onTap: () => _open(n),
                                  );
                                },
                              ),
                            ),
                    ),
                    AsyncError(isLoading: false) => CoraStateView.loadFailed(
                      title: NotificationTexts.loadFailed,
                      onRetry: () =>
                          ref.invalidate(notificationsViewModelProvider),
                    ),
                    _ => const CoraStateView.loading(),
                  },
                ),
              ],
            ),
            if (notice != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottom + 56 + 12),
                  child: _Notice(message: notice),
                ),
              ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
                child: _ReadAllButton(
                  onTap: ref
                      .read(notificationsViewModelProvider.notifier)
                      .readAll,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 머리(높이 64, 좌우 8, 60 / 1fr / 60): 뒤로, 가운데 `알림` 16/500, 오른쪽 `알림 설정` 아이콘.
class _Header extends StatelessWidget {
  const _Header({required this.onBack, required this.onSettings});

  final VoidCallback onBack;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: Align(
                alignment: Alignment.centerLeft,
                child: CoraBackButton(onPressed: onBack),
              ),
            ),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  NotificationTexts.title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CoraTextStyles.bodyLarge.copyWith(color: c.text),
                ),
              ),
            ),
            SizedBox(
              width: 60,
              child: Align(
                alignment: Alignment.centerRight,
                child: Semantics(
                  container: true,
                  button: true,
                  label: NotificationTexts.settings,
                  onTap: onSettings,
                  child: ExcludeSemantics(
                    child: CoraPressable(
                      onTap: onSettings,
                      child: SizedBox.square(
                        dimension: 44,
                        child: Center(
                          child: CustomPaint(
                            size: const Size.square(22),
                            painter: _SlidersPainter(c.text),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 설정 아이콘: viewBox 24를 22로 줄여 그린다(선 2). `M4 7h10M18 7h2M4 17h4M12 17h8` + 원 둘.
class _SlidersPainter extends CustomPainter {
  const _SlidersPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(const Offset(4, 7), const Offset(14, 7), paint)
      ..drawLine(const Offset(18, 7), const Offset(20, 7), paint)
      ..drawLine(const Offset(4, 17), const Offset(8, 17), paint)
      ..drawLine(const Offset(12, 17), const Offset(20, 17), paint)
      ..drawCircle(const Offset(16, 7), 2, paint)
      ..drawCircle(const Offset(10, 17), 2, paint);
  }

  @override
  bool shouldRepaint(_SlidersPainter old) => old.color != color;
}

/// 탭(높이 36, 좌우 14, 알약, 13/500, 간격 6, 바깥 위 4·좌우 16). 고른 탭은 `notifyTabSelected`,
/// 나머지는 `surface`다.
class _Tabs extends StatelessWidget {
  const _Tabs({required this.selected, required this.onChanged});

  final NotificationTabFilter selected;
  final ValueChanged<NotificationTabFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: NotificationTexts.tabList,
      // 캔버스의 탭 줄은 `display: flex`라 왼쪽부터 놓인다. 전체 폭을 차지하게 해 가운데로 모이지 않게 한다.
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          // 글자를 크게 보면 탭이 화면보다 길어지므로 옆으로 민다.
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              spacing: 6,
              children: [
                for (final (label, filter) in NotificationsPage.tabs)
                  _Tab(
                    label: label,
                    selected: filter == selected,
                    onTap: () => onChanged(filter),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
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
            key: ValueKey('notification-tab-$label'),
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? c.notifyTabSelected : c.surface,
              borderRadius: BorderRadius.circular(CoraRadius.pill),
            ),
            child: Text(
              label,
              maxLines: 1,
              style: CoraTextStyles.label.copyWith(color: c.text),
            ),
          ),
        ),
      ),
    );
  }
}

/// 알림 줄(둥근 모서리 20, 안쪽 12, 간격 12). 왼쪽 원 44, 가운데 문구 14(줄 높이 1.5)와 시각 12,
/// 읽지 않은 줄은 `surface` 바탕에 오른쪽 점 8.
class _Row extends StatelessWidget {
  const _Row({
    required this.notification,
    required this.now,
    required this.onTap,
  });

  final AppNotification notification;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final n = notification;
    final time = relativeTimeLabel(now, n.createdAt);
    final unread = !n.read;
    return Semantics(
      container: true,
      button: true,
      label: '${n.text}, $time${unread ? ', ${NotificationTexts.unread}' : ''}',
      onTap: onTap,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onTap,
          child: DecoratedBox(
            key: ValueKey('notification-row-${n.id}'),
            decoration: BoxDecoration(
              color: unread ? c.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(CoraRadius.field),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: [
                  _Avatar(notification: n),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          n.text,
                          style: CoraTextStyles.bodySmall.copyWith(
                            height: 1.5,
                            color: c.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          time,
                          style: CoraTextStyles.fieldLabel.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (unread)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: DecoratedBox(
                        key: ValueKey('notification-dot-${n.id}'),
                        decoration: BoxDecoration(
                          color: c.unreadDot,
                          shape: BoxShape.circle,
                        ),
                        child: const SizedBox.square(dimension: 8),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 왼쪽 원 44. 정산은 `₩`, 기획·초안은 `✎`(둘 다 `surface` 바탕), 나머지는 상대 사진이고 사진이 없으면
/// 이름 첫 글자다. 글자는 15/500.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.notification});

  final AppNotification notification;

  /// 캔버스 `object-position: 50% 30%`(사람 사진은 얼굴이 위쪽에 있다).
  static const _face = Alignment(0, -0.4);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final n = notification;
    final glyph = switch (n.glyph) {
      NotificationGlyph.won => '₩',
      NotificationGlyph.pen => '✎',
      null => null,
    };
    final photo = n.actorPhotoUrl;
    final Widget child;
    if (glyph == null && photo != null && photo.isNotEmpty) {
      child = CoraNetworkPhoto(url: photo, alignment: _face);
    } else {
      final text = glyph ?? _initial(n.actorName);
      child = ColoredBox(
        color: c.surface,
        child: Center(
          child: Text(
            text,
            style: CoraTextStyles.buttonMedium.copyWith(color: c.text),
          ),
        ),
      );
    }
    return SizedBox.square(dimension: 44, child: ClipOval(child: child));
  }

  static String _initial(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '' : String.fromCharCode(trimmed.runes.first);
  }
}

/// 아래 고정 `모두 읽음으로 표시`(높이 56, 알약, 15/500, `subtleAction`).
class _ReadAllButton extends StatelessWidget {
  const _ReadAllButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      label: NotificationTexts.readAll,
      onTap: onTap,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onTap,
          child: Container(
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.subtleAction,
              borderRadius: BorderRadius.circular(CoraRadius.pill),
            ),
            child: Text(
              NotificationTexts.readAll,
              style: CoraTextStyles.buttonMedium.copyWith(
                color: c.onSubtleAction,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 알림이 하나도 없을 때. F8의 빈 상태 카드를 탭 줄 아래에 둔다(놓는 자리는 캔버스에 없다).
class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 12),
      child: CoraStateView.empty(title: NotificationTexts.empty),
    );
  }
}

/// 아래 버튼 위에 잠깐 뜨는 안내(캔버스에 없다). 본문색 바탕에 배경색 글자라 라이트·다크 모두 읽힌다.
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
