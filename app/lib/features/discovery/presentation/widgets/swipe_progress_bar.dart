import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_swipe_tokens.dart';

/// 카드 위쪽의 작은 진행 막대(캔버스 01은 세 칸, 08은 두 칸, 사장님 전체 둘러보기는 대표 게시물 수만큼).
/// [current]번째 칸까지 채우고(라이트 흰색, 다크 `#0F1012`) 나머지는 흰색 40%다. 캔버스의 left 10,
/// right 10, top 14, 칸 높이 3, 간격 4.
class SwipeProgressBar extends StatelessWidget {
  const SwipeProgressBar({super.key, required this.segments, this.current = 0});

  final int segments;

  /// 지금 보는 칸(0부터). 이 칸까지가 채워진다.
  final int current;

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
                color: i <= current
                    ? c.swipeProgressOn
                    : CoraSwipeTokens.progressIdle,
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
