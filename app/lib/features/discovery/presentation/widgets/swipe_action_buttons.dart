import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shadows.dart';
import '../../../../core/theme/cora_swipe_tokens.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../discovery_text.dart';

/// 카드 아래의 버튼 넷(캔버스 M19G1Swipe): 되돌리기(26), 넘기기(36), 저장(32), 하트(44). 아이콘 아래에
/// 11px 글자가 붙고, 버튼마다 너비 60에 서로 4 띄워 아래를 맞춘다(아이콘 크기가 달라 키가 다르다). 아이콘과
/// 글자 모두 `drop-shadow(0 2px 6px rgba(0,0,0,0.55))`가 깔린다. 글자 라벨은 화면에 보이는 이름이라
/// 스크린 리더는 버튼 하나에 이름 하나로 읽는다.
///
/// 저장은 서버 `HOLD`, 하트는 `LIKE`다(화면 이름만 바뀌었다).
class SwipeActionButtons extends StatelessWidget {
  const SwipeActionButtons({
    super.key,
    required this.canUndo,
    required this.onUndo,
    required this.onPass,
    required this.onHold,
    required this.onLike,
  });

  /// false이면 되돌리기가 흐린 모양이 된다(캔버스 opacity 0.45). 눌러도 [onUndo]는 불린다. 되돌릴 것이
  /// 없다는 안내는 호출한 쪽이 한다.
  final bool canUndo;
  final VoidCallback onUndo;
  final VoidCallback onPass;
  final VoidCallback onHold;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: 4,
      children: [
        _ActionButton(
          label: DiscoveryTexts.undoLabel,
          opacity: canUndo ? 1 : 0.45,
          onTap: onUndo,
          icon: const _IconSpec(size: 26, kind: _IconKind.undo),
          color: CoraSwipeTokens.actionIcon,
        ),
        _ActionButton(
          label: DiscoveryTexts.passLabel,
          onTap: onPass,
          icon: const _IconSpec(size: 36, kind: _IconKind.pass),
          color: CoraSwipeTokens.actionIcon,
        ),
        _ActionButton(
          label: DiscoveryTexts.holdLabel,
          onTap: onHold,
          icon: const _IconSpec(size: 32, kind: _IconKind.hold),
          color: CoraSwipeTokens.actionIcon,
        ),
        _ActionButton(
          label: DiscoveryTexts.likeLabel,
          onTap: onLike,
          icon: const _IconSpec(size: 44, kind: _IconKind.like),
          color: c.accent,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
    required this.icon,
    required this.color,
    this.opacity = 1,
  });

  /// 캔버스 `.act`의 너비. 글자가 커져도 이 안에서 줄어든다.
  static const double width = 60;

  /// 누르는 자리의 최소 높이. 가장 작은 아이콘(되돌리기 39)도 손가락이 닿게 위로만 늘린다.
  static const double minHit = 44;

  final String label;
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
          child: SizedBox(
            width: width,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: minHit),
              // 늘어난 높이는 위로만 간다. 글자 줄이 항상 같은 높이에 선다.
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 2,
                  children: [
                    CustomPaint(
                      size: Size.square(icon.size),
                      painter: _IconPainter(icon.kind, color),
                    ),
                    // 글자 크기를 키워도 넘치지 않게 한 줄로 줄인다.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        softWrap: false,
                        style: CoraTextStyles.caption.copyWith(
                          fontSize: 11,
                          height: 1,
                          color: CoraSwipeTokens.actionIcon,
                          shadows: [
                            Shadow(
                              color: CoraSwipeTokens.actionIconShadow,
                              offset: const Offset(0, 2),
                              blurRadius: CoraShadows.blurRadiusFor(6),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
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
        // 북마크 `M6 3h12v18l-6-4-6 4z`
        return Path()
          ..moveTo(6, 3)
          ..lineTo(18, 3)
          ..lineTo(18, 21)
          ..lineTo(12, 17)
          ..lineTo(6, 21)
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
    // 저장과 하트는 칠하고 같은 색으로 테두리도 두른다(캔버스 fill + stroke). 나머지는 선만 있다.
    final filled = kind == _IconKind.hold || kind == _IconKind.like;
    final width = switch (kind) {
      _IconKind.undo => 2.6,
      _IconKind.pass => 3.0,
      _IconKind.hold => 2.0,
      _IconKind.like => 1.0,
    };
    Paint stroke(Color c, MaskFilter? blur) => Paint()
      ..color = c
      ..maskFilter = blur
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    void draw(Path p, Color c, {MaskFilter? blur}) {
      if (filled) {
        canvas.drawPath(
          p,
          Paint()
            ..color = c
            ..maskFilter = blur
            ..style = PaintingStyle.fill,
        );
      }
      canvas.drawPath(p, stroke(c, blur));
    }

    // CSS의 blur 6px는 표준편차 3(그림 24칸 기준이 아니라 화면 픽셀)이라 칸 단위로 환산한다.
    final sigma = 3 * 24 / size.width;
    draw(
      path.shift(Offset(0, 2 * 24 / size.width)),
      CoraSwipeTokens.actionIconShadow,
      blur: MaskFilter.blur(BlurStyle.normal, sigma),
    );
    draw(path, color);
  }

  @override
  bool shouldRepaint(_IconPainter old) =>
      old.kind != kind || old.color != color;
}
