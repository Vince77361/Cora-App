import 'package:flutter/widgets.dart';

// 캔버스(M19G3*)의 SVG 선 그림을 옮긴 아이콘들. 모두 24 x 24 칸의 좌표를 쓰고 [WorldCupIcon]의 크기에 맞춰 늘린다.

abstract class _Painter24 extends CustomPainter {
  const _Painter24(this.color);

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
  bool shouldRepaint(covariant _Painter24 old) => old.color != color;
}

/// 트로피(선 2): 잔 모양과 두 손잡이, 받침.
class TrophyPainter extends _Painter24 {
  const TrophyPainter(super.color);

  @override
  void paintIn24(Canvas canvas) {
    final paint = stroke(2);
    const four = Radius.circular(4);
    const three = Radius.circular(3);
    canvas.drawPath(
      Path()
        ..moveTo(8, 4)
        ..lineTo(16, 4)
        ..lineTo(16, 9)
        ..arcToPoint(const Offset(8, 9), radius: four)
        ..close(),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(8, 6)
        ..lineTo(5, 6)
        ..lineTo(5, 7)
        ..arcToPoint(const Offset(8, 10), radius: three, clockwise: false)
        ..moveTo(16, 6)
        ..lineTo(19, 6)
        ..lineTo(19, 7)
        ..arcToPoint(const Offset(16, 10), radius: three)
        ..moveTo(12, 13)
        ..lineTo(12, 17)
        ..moveTo(8.5, 20)
        ..lineTo(15.5, 20)
        ..moveTo(10, 17)
        ..lineTo(14, 17),
      paint,
    );
  }
}

/// 체크(`M5 12l5 5 9-10`). 선 굵기는 캔버스가 3.4다.
class WorldCupCheckPainter extends _Painter24 {
  const WorldCupCheckPainter(super.color);

  @override
  void paintIn24(Canvas canvas) {
    canvas.drawPath(
      Path()
        ..moveTo(5, 12)
        ..lineTo(10, 17)
        ..lineTo(19, 7),
      stroke(3.4),
    );
  }
}

/// 왕관: [color]로 채우고 [outline]으로 선 2.2를 두른다(`이상형 1위` 표지).
class CrownPainter extends _Painter24 {
  const CrownPainter(super.color, this.outline);

  final Color outline;

  @override
  void paintIn24(Canvas canvas) {
    final path = Path()
      ..moveTo(4, 18)
      ..lineTo(3, 8)
      ..lineTo(8, 12)
      ..lineTo(12, 5)
      ..lineTo(16, 12)
      ..lineTo(21, 8)
      ..lineTo(20, 18)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CrownPainter old) =>
      old.color != color || old.outline != outline;
}

/// 크기가 정해진 아이콘 한 개. 읽어 주지 않는다.
class WorldCupIcon extends StatelessWidget {
  const WorldCupIcon(this.painter, {super.key, required this.size});

  final CustomPainter painter;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(size: Size.square(size), painter: painter),
  );
}
