import 'package:flutter/material.dart';

import '../theme/cora_colors.dart';
import '../theme/cora_text_styles.dart';

/// Cora 로고. 겹친 원 두 개(왼쪽 `text`, 오른쪽 `accent`)와 글자 "cora".
///
/// 캔버스 A1: 원 그림 28, 간격 6, 글자 26px 900 -0.05em. [size]는 원 그림의 한 변이고
/// 간격과 글자도 같은 비율로 커진다.
///
/// 로그인 화면(NLogin)의 큰 로고는 [CoraLogo.hero]다: 원 그림 34, 간격 8, 글자 32px.
/// 이 값은 28의 비례(34 → 간격 7.3, 글자 31.6)와 달라서 따로 정한다.
class CoraLogo extends StatelessWidget {
  const CoraLogo({super.key, this.size = 28}) : _gap = null, _wordSize = null;

  const CoraLogo.hero({super.key}) : size = 34, _gap = 8, _wordSize = 32;

  final double size;
  final double? _gap;
  final double? _wordSize;

  @visibleForTesting
  static const markKey = ValueKey<String>('CoraLogo.mark');

  static const double _canvasSize = 28;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final k = size / _canvasSize;
    final word = CoraTextStyles.wordmark;
    final wordSize = _wordSize ?? word.fontSize! * k;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          key: markKey,
          size: Size.square(size),
          painter: _MarkPainter(left: c.text, right: c.accent),
        ),
        SizedBox(width: _gap ?? 6 * k),
        Text(
          'cora',
          style: word.copyWith(
            fontSize: wordSize,
            // 자간은 글자 크기의 -0.05em이다.
            letterSpacing: -0.05 * wordSize,
            color: c.text,
          ),
        ),
      ],
    );
  }
}

/// 캔버스 SVG: viewBox 26, r 6.5 원 두 개(cx 9.5, 16.5), 선 굵기 3.
/// 오른쪽 원을 나중에 그려 겹친 부분에서 위에 온다.
class _MarkPainter extends CustomPainter {
  _MarkPainter({required this.left, required this.right});

  final Color left;
  final Color right;

  static const _viewBox = 26.0;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / _viewBox;
    Paint stroke(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * k
      ..isAntiAlias = true;
    canvas.drawCircle(Offset(9.5 * k, 13 * k), 6.5 * k, stroke(left));
    canvas.drawCircle(Offset(16.5 * k, 13 * k), 6.5 * k, stroke(right));
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.left != left || old.right != right;
}
