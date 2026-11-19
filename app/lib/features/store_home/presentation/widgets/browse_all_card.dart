import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_pressable.dart';

/// 추천 아래의 `마음에 드는 분이 없나요?` + `전체 둘러보기` 상자(캔버스 M19G4 `<a>`): 안쪽 14/16, 모서리 20,
/// `surface` 바탕, 왼쪽 지름 44 동그라미 아이콘, 오른쪽 `›`.
class BrowseAllCard extends StatelessWidget {
  const BrowseAllCard({super.key, required this.onTap});

  final VoidCallback onTap;

  static const question = '마음에 드는 분이 없나요?';
  static const action = '전체 둘러보기';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      label: '$question $action',
      onTap: onTap,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(CoraRadius.field),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                spacing: 12,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.notifyTabSelected,
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox.square(
                      dimension: 44,
                      child: Center(
                        child: CustomPaint(
                          size: const Size.square(22),
                          painter: _CardsPainter(c.text),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          question,
                          style: CoraTextStyles.fieldLabel.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                        Text(
                          action,
                          style: CoraTextStyles.amountSmall.copyWith(
                            color: c.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CustomPaint(
                    size: const Size.square(20),
                    painter: _ChevronPainter(c.textSecondary),
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

/// 캔버스의 카드 아이콘 `<rect x=7 y=4 width=13 height=16 rx=3/><path d="M4 8v9"/>`(24 x 24 칸, 선 2).
class _CardsPainter extends CustomPainter {
  const _CardsPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(7 * k, 4 * k, 13 * k, 16 * k),
        Radius.circular(3 * k),
      ),
      paint,
    );
    canvas.drawLine(Offset(4 * k, 8 * k), Offset(4 * k, 17 * k), paint);
  }

  @override
  bool shouldRepaint(_CardsPainter old) => old.color != color;
}

/// 캔버스의 `›` `M9 5l7 7-7 7`(24 x 24 칸, 선 2).
class _ChevronPainter extends CustomPainter {
  const _ChevronPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(9 * k, 5 * k)
      ..lineTo(16 * k, 12 * k)
      ..lineTo(9 * k, 19 * k);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ChevronPainter old) => old.color != color;
}
