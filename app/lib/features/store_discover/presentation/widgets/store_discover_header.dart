import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../../core/ui/cora_step_header.dart';
import '../store_discover_text.dart';

/// 사장님 전체 둘러보기의 머리(캔버스 `.hdr3`): 높이 64, 좌우 8, 칸 60·1fr·60. 왼쪽 뒤로, 가운데
/// `전체 둘러보기`(16·500), 오른쪽 저장함 북마크(44 x 44)와 저장 수 배지. 저장 수가 0이면 배지를 숨긴다.
class StoreDiscoverHeader extends StatelessWidget {
  const StoreDiscoverHeader({
    super.key,
    required this.savedCount,
    required this.onBack,
    required this.onOpenSaved,
  });

  final int savedCount;
  final VoidCallback onBack;
  final VoidCallback onOpenSaved;

  static const double height = 64;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: Align(
                alignment: Alignment.centerLeft,
                child: CoraBackButton(onPressed: onBack),
              ),
            ),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  StoreDiscoverTexts.title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CoraTextStyles.bodyLarge.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.448,
                    color: c.text,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 60,
              child: Align(
                alignment: Alignment.centerRight,
                child: _SavedButton(count: savedCount, onTap: onOpenSaved),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedButton extends StatelessWidget {
  const _SavedButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      label: StoreDiscoverTexts.savedLabel(count),
      onTap: onTap,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size.square(22),
                  painter: _BookmarkPainter(c.text),
                ),
                if (count > 0)
                  Positioned(
                    right: 5,
                    top: 6,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: c.accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Center(
                            widthFactor: 1,
                            child: Text(
                              '$count',
                              style: CoraTextStyles.caption.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                height: 1.0,
                                color: c.onAccent,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 북마크 `M6 3h12v18l-6-4-6 4z`(선 2, 끝 둥글게).
class _BookmarkPainter extends CustomPainter {
  const _BookmarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    canvas.drawPath(
      Path()
        ..moveTo(6, 3)
        ..lineTo(18, 3)
        ..lineTo(18, 21)
        ..lineTo(12, 17)
        ..lineTo(6, 21)
        ..close(),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_BookmarkPainter old) => old.color != color;
}
