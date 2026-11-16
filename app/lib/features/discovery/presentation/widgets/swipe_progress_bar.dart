import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';

/// 카드 위쪽의 작은 진행 막대(캔버스 01은 세 칸, 08은 두 칸). 첫 칸만 채우고(라이트 흰색, 다크 `#0F1012`)
/// 나머지는 흰색 40%다. 캔버스의 left 10, right 10, top 14, 칸 높이 3, 간격 4.
class SwipeProgressBar extends StatelessWidget {
  const SwipeProgressBar({super.key, required this.segments});

  final int segments;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Positioned(
      left: 10,
      right: 10,
      top: 14,
      child: ExcludeSemantics(
        child: Row(
          spacing: 4,
          children: [
            for (var i = 0; i < segments; i++)
              _Segment(
                color: i == 0 ? c.swipeProgressOn : const Color(0x66FFFFFF),
              ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
      child: const SizedBox(height: 3),
    ),
  );
}
