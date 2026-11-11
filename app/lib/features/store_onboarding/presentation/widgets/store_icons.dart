import 'package:flutter/material.dart';

/// 캔버스의 SVG 아이콘을 같은 경로로 그린다(viewBox 24를 크기에 맞춰 늘린다).
class StoreIconPainter extends CustomPainter {
  const StoreIconPainter._(this._draw, this.color, this.width);

  /// 링크를 찾았다는 체크(NStoreLink): `M5 12l5 5 9-10`, 두께 3.
  const StoreIconPainter.check(Color color) : this._(_check, color, 3);

  /// 자동으로 만들었다는 반짝임(NStorePage): `M12 3l2 5 5 2-5 2-2 5-2-5-5-2 5-2z`, 두께 2.2.
  const StoreIconPainter.sparkle(Color color) : this._(_sparkle, color, 2.2);

  /// 사진 바꾸기 카메라(NEditProfile): `M4 8h3l2-3h6l2 3h3v11H4z`와 원, 두께 2.
  const StoreIconPainter.camera(Color color) : this._(_camera, color, 2);

  /// 고르기 칸의 아래 화살표.
  const StoreIconPainter.chevronDown(Color color)
    : this._(_chevronDown, color, 2);

  /// 고른 항목 표시(NStoreLink 체크와 같은 모양, 두께 2.4).
  const StoreIconPainter.selected(Color color) : this._(_check, color, 2.4);

  final void Function(Canvas canvas, double k, Paint paint) _draw;
  final Color color;
  final double width;

  static void _check(Canvas canvas, double k, Paint paint) {
    canvas.drawPath(
      Path()
        ..moveTo(5 * k, 12 * k)
        ..relativeLineTo(5 * k, 5 * k)
        ..relativeLineTo(9 * k, -10 * k),
      paint,
    );
  }

  static void _sparkle(Canvas canvas, double k, Paint paint) {
    canvas.drawPath(
      Path()
        ..moveTo(12 * k, 3 * k)
        ..relativeLineTo(2 * k, 5 * k)
        ..relativeLineTo(5 * k, 2 * k)
        ..relativeLineTo(-5 * k, 2 * k)
        ..relativeLineTo(-2 * k, 5 * k)
        ..relativeLineTo(-2 * k, -5 * k)
        ..relativeLineTo(-5 * k, -2 * k)
        ..relativeLineTo(5 * k, -2 * k)
        ..close(),
      paint,
    );
  }

  static void _camera(Canvas canvas, double k, Paint paint) {
    canvas.drawPath(
      Path()
        ..moveTo(4 * k, 8 * k)
        ..relativeLineTo(3 * k, 0)
        ..relativeLineTo(2 * k, -3 * k)
        ..relativeLineTo(6 * k, 0)
        ..relativeLineTo(2 * k, 3 * k)
        ..relativeLineTo(3 * k, 0)
        ..lineTo(23 * k, 19 * k)
        ..lineTo(4 * k, 19 * k)
        ..close(),
      paint,
    );
    canvas.drawCircle(Offset(12 * k, 13 * k), 3.5 * k, paint);
  }

  static void _chevronDown(Canvas canvas, double k, Paint paint) {
    canvas.drawPath(
      Path()
        ..moveTo(6 * k, 9 * k)
        ..lineTo(12 * k, 15 * k)
        ..lineTo(18 * k, 9 * k),
      paint,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width * k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    _draw(canvas, k, paint);
  }

  @override
  bool shouldRepaint(StoreIconPainter old) =>
      old.color != color || old.width != width || old._draw != _draw;
}

/// [painter]로 그린 [size] 크기의 아이콘.
class StoreIcon extends StatelessWidget {
  const StoreIcon(this.painter, {super.key, this.size = 14});

  final StoreIconPainter painter;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(size: Size.square(size), painter: painter),
  );
}
