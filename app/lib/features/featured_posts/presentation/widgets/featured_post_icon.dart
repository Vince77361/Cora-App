import 'package:flutter/material.dart';

/// 대표 게시물 화면 캔버스(M19G6*)의 아이콘. 모두 viewBox 24에 둥근 끝·꺾임으로 그린 선이다.
enum FeaturedPostGlyph {
  plus,
  dots,
  grip,
  gallery,
  instagram,
  upArrow,
  trash,
  info,
  close,
}

class FeaturedPostIcon extends StatelessWidget {
  const FeaturedPostIcon(
    this.glyph, {
    super.key,
    required this.size,
    required this.color,
    this.strokeWidth = 2,
  });

  final FeaturedPostGlyph glyph;
  final double size;
  final Color color;

  /// viewBox 24 기준 선 두께(캔버스 `stroke-width`).
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(size),
      painter: _GlyphPainter(glyph, color, strokeWidth),
    ),
  );
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter(this.glyph, this.color, this.strokeWidth);

  final FeaturedPostGlyph glyph;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    Offset p(double x, double y) => Offset(x * k, y * k);

    switch (glyph) {
      case FeaturedPostGlyph.plus:
        canvas.drawLine(p(12, 5), p(12, 19), line);
        canvas.drawLine(p(5, 12), p(19, 12), line);
      case FeaturedPostGlyph.dots:
        // 채움과 선이 같은 색이라 점의 지름은 (1.5 + 두께/2) * 2다.
        for (final x in [5.0, 12.0, 19.0]) {
          canvas.drawCircle(p(x, 12), 1.5 * k, fill);
          canvas.drawCircle(p(x, 12), 1.5 * k, line);
        }
      case FeaturedPostGlyph.grip:
        // 길이 0인 선에 둥근 끝을 단 점(지름 3.2).
        for (final x in [9.0, 15.0]) {
          for (final y in [6.0, 12.0, 18.0]) {
            canvas.drawCircle(p(x, y), 1.6 * k, fill);
          }
        }
      case FeaturedPostGlyph.gallery:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(3 * k, 4 * k, 18 * k, 16 * k),
            Radius.circular(3 * k),
          ),
          line,
        );
        canvas.drawCircle(p(9, 10), 1.8 * k, line);
        canvas.drawPath(
          Path()
            ..moveTo(4 * k, 18 * k)
            ..relativeLineTo(5 * k, -5 * k)
            ..relativeLineTo(4 * k, 4 * k)
            ..relativeLineTo(3 * k, -3 * k)
            ..relativeLineTo(4 * k, 4 * k),
          line,
        );
      case FeaturedPostGlyph.instagram:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(4 * k, 4 * k, 16 * k, 16 * k),
            Radius.circular(5 * k),
          ),
          line,
        );
        canvas.drawCircle(p(12, 12), 3.5 * k, line);
      case FeaturedPostGlyph.upArrow:
        canvas.drawLine(p(12, 19), p(12, 6), line);
        canvas.drawPath(
          Path()
            ..moveTo(6 * k, 11 * k)
            ..relativeLineTo(6 * k, -6 * k)
            ..relativeLineTo(6 * k, 6 * k),
          line,
        );
      case FeaturedPostGlyph.trash:
        canvas.drawLine(p(5, 7), p(19, 7), line);
        canvas.drawPath(
          Path()
            ..moveTo(10 * k, 7 * k)
            ..lineTo(10 * k, 4 * k)
            ..lineTo(14 * k, 4 * k)
            ..lineTo(14 * k, 7 * k),
          line,
        );
        canvas.drawPath(
          Path()
            ..moveTo(7 * k, 7 * k)
            ..relativeLineTo(1 * k, 13 * k)
            ..relativeLineTo(8 * k, 0)
            ..relativeLineTo(1 * k, -13 * k),
          line,
        );
      case FeaturedPostGlyph.info:
        canvas.drawCircle(p(12, 12), 9 * k, line);
        canvas.drawLine(p(12, 11), p(12, 16), line);
        canvas.drawLine(p(12, 8), p(12.01, 8), line);
      case FeaturedPostGlyph.close:
        canvas.drawLine(p(6, 6), p(18, 18), line);
        canvas.drawLine(p(18, 6), p(6, 18), line);
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.glyph != glyph ||
      old.color != color ||
      old.strokeWidth != strokeWidth;
}
