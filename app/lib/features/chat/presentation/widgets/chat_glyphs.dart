import 'package:flutter/widgets.dart';

/// 대화방(D3)에서 쓰는 선 그림. 캔버스 SVG(viewBox 24)의 경로를 그대로 옮겼다.
enum ChatGlyph {
  /// `M15 5l-7 7 7 7`, 두께 2.4.
  chevronBack(2.4),

  /// `M9 5l7 7-7 7`, 두께 2.4.
  chevronForward(2.4),

  /// `M9 4h6l-1 6 3 3H7l3-3z` + `M12 13v7`, 두께 2.2.
  pin(2.2),

  /// `M12 5v14M5 12h14`, 두께 2.4.
  plus(2.4),

  /// `M5 12h14M13 6l6 6-6 6`, 두께 2.6.
  arrow(2.6),

  /// 세로 점 셋(`r=2`, 채움).
  dots(0);

  const ChatGlyph(this.strokeWidth);

  final double strokeWidth;
}

class ChatGlyphIcon extends StatelessWidget {
  const ChatGlyphIcon(
    this.glyph, {
    super.key,
    required this.size,
    required this.color,
  });

  final ChatGlyph glyph;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(size),
      painter: _GlyphPainter(glyph, color),
    ),
  );
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter(this.glyph, this.color);

  final ChatGlyph glyph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    if (glyph == ChatGlyph.dots) {
      final fill = Paint()..color = color;
      for (final y in const [5.0, 12.0, 19.0]) {
        canvas.drawCircle(Offset(12 * s, y * s), 2 * s, fill);
      }
      return;
    }
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = glyph.strokeWidth * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    switch (glyph) {
      case ChatGlyph.chevronBack:
        path
          ..moveTo(15 * s, 5 * s)
          ..lineTo(8 * s, 12 * s)
          ..lineTo(15 * s, 19 * s);
      case ChatGlyph.chevronForward:
        path
          ..moveTo(9 * s, 5 * s)
          ..lineTo(16 * s, 12 * s)
          ..lineTo(9 * s, 19 * s);
      case ChatGlyph.pin:
        path
          ..moveTo(9 * s, 4 * s)
          ..lineTo(15 * s, 4 * s)
          ..lineTo(14 * s, 10 * s)
          ..lineTo(17 * s, 13 * s)
          ..lineTo(7 * s, 13 * s)
          ..lineTo(10 * s, 10 * s)
          ..close()
          ..moveTo(12 * s, 13 * s)
          ..lineTo(12 * s, 20 * s);
      case ChatGlyph.plus:
        path
          ..moveTo(12 * s, 5 * s)
          ..lineTo(12 * s, 19 * s)
          ..moveTo(5 * s, 12 * s)
          ..lineTo(19 * s, 12 * s);
      case ChatGlyph.arrow:
        path
          ..moveTo(5 * s, 12 * s)
          ..lineTo(19 * s, 12 * s)
          ..moveTo(13 * s, 6 * s)
          ..lineTo(19 * s, 12 * s)
          ..lineTo(13 * s, 18 * s);
      case ChatGlyph.dots:
        break;
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.glyph != glyph || old.color != color;
}
