import 'package:flutter/widgets.dart';

// 캔버스(Likes, Compare, Match)의 SVG 선 그림을 그대로 옮긴 아이콘들. 모두 24 x 24 칸의 좌표를 쓰고
// [size]에 맞춰 늘린다.

abstract class _Icon24 extends CustomPainter {
  const _Icon24(this.color);

  final Color color;

  void paintIn24(Canvas canvas);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    paintIn24(canvas);
    canvas.restore();
  }

  Paint stroke(double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  bool shouldRepaint(covariant _Icon24 old) => old.color != color;
}

/// 체크(`M5 12l5 5 9-10`, 선 3).
class CheckPainter extends _Icon24 {
  const CheckPainter(super.color);

  @override
  void paintIn24(Canvas canvas) {
    canvas.drawPath(
      Path()
        ..moveTo(5, 12)
        ..lineTo(10, 17)
        ..lineTo(19, 7),
      stroke(3),
    );
  }
}

/// 채운 하트(표지의 12, 가운데 배지의 20).
class HeartFillPainter extends _Icon24 {
  const HeartFillPainter(super.color);

  @override
  void paintIn24(Canvas canvas) {
    final path = Path()
      ..moveTo(12, 20.5)
      ..cubicTo(12, 20.5, 4.5, 15.9, 4.5, 10.1)
      ..arcToPoint(const Offset(12, 7.4), radius: const Radius.circular(4.3))
      ..arcToPoint(const Offset(19.5, 10.1), radius: const Radius.circular(4.3))
      ..cubicTo(19.5, 15.9, 12, 20.5, 12, 20.5)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }
}

/// 비교 버튼의 아이콘: 나란한 두 칸(선 2.2).
class ComparePainter extends _Icon24 {
  const ComparePainter(super.color);

  @override
  void paintIn24(Canvas canvas) {
    final paint = stroke(2.2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(3, 4, 8, 16),
        const Radius.circular(2),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(13, 4, 8, 16),
        const Radius.circular(2),
      ),
      paint,
    );
  }
}

/// 닫기 X(선 2.4).
class ClosePainter extends _Icon24 {
  const ClosePainter(super.color);

  @override
  void paintIn24(Canvas canvas) {
    final paint = stroke(2.4);
    canvas.drawLine(const Offset(6, 6), const Offset(18, 18), paint);
    canvas.drawLine(const Offset(18, 6), const Offset(6, 18), paint);
  }
}

/// 크기가 정해진 아이콘 한 개.
class InterestIcon extends StatelessWidget {
  const InterestIcon(this.painter, {super.key, required this.size});

  final CustomPainter painter;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(size: Size.square(size), painter: painter),
  );
}
