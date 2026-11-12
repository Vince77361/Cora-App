import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../notification_routes.dart';
import '../notification_text.dart';
import '../viewmodels/unread_count_view_model.dart';

/// 홈 머리의 종 아이콘. 누르면 알림함(`/notifications`)을 연다. 읽지 않은 알림이 있으면 오른쪽 위에
/// 점이 뜬다. 사장님 홈(A9)과 4번 계획의 브랜드 발견 머리가 같이 쓴다.
///
/// 캔버스에 없는 위젯이다(설계 E3 "입구"): 44 버튼, 종 22(선 2, `text`), 점 8(`accent`, 바깥 2 고리는
/// `background`, 오른쪽 10 위 10).
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key, this.onReturn});

  /// 알림함에서 돌아왔을 때 부른다. [result]는 알림함이 닫히며 넘긴 값이다(홈으로 가는 알림이면 그 경로).
  /// 종이 이미 사라졌으면(홈이 바뀌었으면) 부르지 않는다.
  final void Function(Object? result)? onReturn;

  static const double size = 44;
  static const dotKey = ValueKey('notification-bell-dot');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final unread = ref.watch(unreadCountViewModelProvider).value ?? 0;

    void open() {
      context.push<Object?>(NotificationRoutes.notifications).then((result) {
        // 알림함이 열려 있는 사이 홈이 바뀌어 종이 사라졌으면 ref도 context도 쓸 수 없다.
        if (!context.mounted) return;
        // 알림함에서 읽은 것이 점에 바로 반영되도록 서버 값을 다시 읽는다.
        ref.invalidate(unreadCountViewModelProvider);
        onReturn?.call(result);
      });
    }

    return Semantics(
      container: true,
      button: true,
      label: NotificationTexts.bell(unread),
      onTap: open,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: open,
          child: SizedBox.square(
            dimension: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size.square(22),
                  painter: _BellPainter(c.text),
                ),
                if (unread > 0)
                  // 점 8의 바깥 고리 2가 점 바깥으로 나가므로 상자(12)는 고리만큼 더 바깥에 둔다.
                  Positioned(
                    right: 10 - 2,
                    top: 10 - 2,
                    child: Container(
                      key: dotKey,
                      decoration: BoxDecoration(
                        color: c.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: c.background, width: 2),
                      ),
                      child: const SizedBox.square(dimension: 8),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 종: viewBox 24를 22로 줄여 그린다(선 2).
class _BellPainter extends CustomPainter {
  const _BellPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // M18 8a6 6 0 0 0-12 0c0 7-3 9-3 9h18s-3-2-3-9
    final body = Path()
      ..moveTo(18, 8)
      ..arcToPoint(
        const Offset(6, 8),
        radius: const Radius.circular(6),
        clockwise: false,
      )
      ..cubicTo(6, 15, 3, 17, 3, 17)
      ..lineTo(21, 17)
      ..cubicTo(21, 17, 18, 15, 18, 8);
    // M13.73 21a2 2 0 0 1-3.46 0
    final clapper = Path()
      ..moveTo(13.73, 21)
      ..arcToPoint(const Offset(10.27, 21), radius: const Radius.circular(2));
    canvas
      ..drawPath(body, paint)
      ..drawPath(clapper, paint);
  }

  @override
  bool shouldRepaint(_BellPainter old) => old.color != color;
}
