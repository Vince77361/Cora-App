import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_swipe_tokens.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../discovery_text.dart';

/// 카드 아래의 버튼 넷(캔버스 01): 되돌리기(52), 넘김(64), 보류(52), 관심(64). 아이콘만 있고 이름은
/// 스크린 리더가 읽는다. 아이콘 아래에 `drop-shadow(0 2px 6px rgba(0,0,0,0.55))`가 깔린다.
class SwipeActionButtons extends StatelessWidget {
  const SwipeActionButtons({
    super.key,
    required this.canUndo,
    required this.onUndo,
    required this.onPass,
    required this.onHold,
    required this.onLike,
    this.showUndo = true,
  });

  final bool canUndo;
  final VoidCallback onUndo;
  final VoidCallback onPass;
  final VoidCallback onHold;
  final VoidCallback onLike;

  /// 둘러보기(9A)에는 되돌릴 결정이 없어 되돌리기를 그리지 않는다.
  final bool showUndo;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 16,
      children: [
        if (showUndo)
          _ActionButton(
            label: DiscoveryTexts.undoLabel,
            box: 52,
            // 되돌릴 결정이 없으면 흐리게(캔버스 opacity 0.45).
            opacity: canUndo ? 1 : 0.45,
            onTap: onUndo,
            icon: const _IconSpec(size: 28, kind: _IconKind.undo),
            color: CoraSwipeTokens.actionIcon,
          ),
        _ActionButton(
          label: DiscoveryTexts.passLabel,
          box: 64,
          onTap: onPass,
          icon: const _IconSpec(size: 42, kind: _IconKind.pass),
          color: CoraSwipeTokens.actionIcon,
        ),
        _ActionButton(
          label: DiscoveryTexts.holdLabel,
          box: 52,
          onTap: onHold,
          icon: const _IconSpec(size: 32, kind: _IconKind.hold),
          color: CoraSwipeTokens.actionIcon,
        ),
        _ActionButton(
          label: DiscoveryTexts.likeLabel,
          box: 64,
          onTap: onLike,
          icon: const _IconSpec(size: 46, kind: _IconKind.like),
          color: c.accent,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.box,
    required this.onTap,
    required this.icon,
    required this.color,
    this.opacity = 1,
  });

  final String label;
  final double box;
  final VoidCallback onTap;
  final _IconSpec icon;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    button: true,
    label: label,
    onTap: onTap,
    child: ExcludeSemantics(
      child: CoraPressable(
        onTap: onTap,
        child: Opacity(
          opacity: opacity,
          child: SizedBox.square(
            dimension: box,
            child: Center(
              child: CustomPaint(
                size: Size.square(icon.size),
                painter: _IconPainter(icon.kind, color),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _IconSpec {
  const _IconSpec({required this.size, required this.kind});

  final double size;
  final _IconKind kind;
}

enum _IconKind { undo, pass, hold, like }

/// 24 x 24 선 그림. 같은 그림을 검정 55%로 흐리게 한 번 아래(0, 2)에 깔아 그림자로 쓴다.
class _IconPainter extends CustomPainter {
  const _IconPainter(this.kind, this.color);

  final _IconKind kind;
  final Color color;

  Path _path() {
    switch (kind) {
      case _IconKind.undo:
        return Path()
          ..moveTo(4, 12)
          ..arcToPoint(
            const Offset(6.4, 6.3),
            radius: const Radius.circular(8),
            largeArc: true,
            clockwise: false,
          )
          ..moveTo(4, 4)
          ..lineTo(4, 8.5)
          ..lineTo(8.5, 8.5);
      case _IconKind.pass:
        return Path()
          ..moveTo(6, 6)
          ..lineTo(18, 18)
          ..moveTo(18, 6)
          ..lineTo(6, 18);
      case _IconKind.hold:
        return Path()
          ..moveTo(12, 3)
          ..lineTo(14.7, 8.6)
          ..lineTo(20.8, 9.5)
          ..lineTo(16.4, 13.8)
          ..lineTo(17.4, 19.9)
          ..lineTo(12, 17)
          ..lineTo(6.6, 19.9)
          ..lineTo(7.6, 13.8)
          ..lineTo(3.2, 9.5)
          ..lineTo(9.3, 8.6)
          ..close();
      case _IconKind.like:
        return Path()
          ..moveTo(12, 20.5)
          ..cubicTo(12, 20.5, 4.5, 15.9, 4.5, 10.1)
          ..arcToPoint(
            const Offset(12, 7.4),
            radius: const Radius.circular(4.3),
          )
          ..arcToPoint(
            const Offset(19.5, 10.1),
            radius: const Radius.circular(4.3),
          )
          ..cubicTo(19.5, 15.9, 12, 20.5, 12, 20.5)
          ..close();
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final path = _path();
    final filled = kind == _IconKind.hold || kind == _IconKind.like;
    final width = switch (kind) {
      _IconKind.undo => 2.6,
      _IconKind.pass => 3.0,
      _ => 0.0,
    };
    Paint paint(Color c, {MaskFilter? blur}) {
      final p = Paint()
        ..color = c
        ..maskFilter = blur;
      if (filled) {
        p.style = PaintingStyle.fill;
      } else {
        p
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
      }
      return p;
    }

    // CSS의 blur 6px는 표준편차 3(그림 24칸 기준이 아니라 화면 픽셀)이라 칸 단위로 환산한다.
    final sigma = 3 * 24 / size.width;
    canvas.drawPath(
      path.shift(Offset(0, 2 * 24 / size.width)),
      paint(
        CoraSwipeTokens.actionIconShadow,
        blur: MaskFilter.blur(BlurStyle.normal, sigma),
      ),
    );
    canvas.drawPath(path, paint(color));
  }

  @override
  bool shouldRepaint(_IconPainter old) =>
      old.kind != kind || old.color != color;
}
