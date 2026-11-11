import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_pressable.dart';

/// 사진 위의 알약 표지(캔버스 D2 `소상공인`, A6 `소상공인 · 오늘 도착`): 패딩 6/12, 12/500.
class PhotoChip extends StatelessWidget {
  const PhotoChip(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.photoChip,
        borderRadius: BorderRadius.circular(CoraRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          label,
          style: CoraTextStyles.caption.copyWith(color: c.onPhotoChip),
        ),
      ),
    );
  }
}

/// 사진 위 왼쪽 위의 뒤로 가기(D2): 44 x 44 원, 흰색 90%, 안에 두께 2.4의 `<`(22).
/// 사진은 모드와 상관없이 같아서 라이트·다크가 같다.
class PhotoBackButton extends StatelessWidget {
  const PhotoBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      label: '뒤로',
      onTap: onPressed,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onPressed,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.onPhoto.withValues(alpha: 0.9),
            ),
            alignment: Alignment.center,
            child: CustomPaint(
              size: const Size.square(22),
              painter: _ChevronPainter(c.onPhotoChip),
            ),
          ),
        ),
      ),
    );
  }
}

/// SVG `M15 5l-7 7 7 7`(viewBox 24, stroke 2.4, round)를 22로 줄여 그린다.
class _ChevronPainter extends CustomPainter {
  const _ChevronPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    canvas.drawPath(
      Path()
        ..moveTo(15, 5)
        ..lineTo(8, 12)
        ..lineTo(15, 19),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_ChevronPainter old) => old.color != color;
}
