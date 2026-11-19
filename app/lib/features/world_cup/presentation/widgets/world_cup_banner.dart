import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../world_cup_text.dart';
import 'world_cup_icons.dart';

/// 저장함 저장 탭 맨 위의 월드컵 배너(캔버스 M19G3Banner): 안쪽 14·16, 모서리 20, `surface` 바탕에 트로피 동그라미(44),
/// 제목 `이상형 월드컵`(15/700), 설명(12 보조색), 오른쪽 형광 알약 `월드컵 하기`(높이 38, 13/500).
///
/// 저장이 [minSaved]명 이상일 때만 둔다. 사장님과 브랜드의 저장함에만 있다(크리에이터는 제안할 수 없다).
class WorldCupBanner extends StatelessWidget {
  const WorldCupBanner({
    super.key,
    required this.savedCount,
    required this.onStart,
  });

  final int savedCount;
  final VoidCallback onStart;

  /// 이 수 이상 저장했을 때 배너가 나온다(4강을 할 수 있는 최소 인원).
  static const minSaved = 4;

  static bool shownFor(int savedCount) => savedCount >= minSaved;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          spacing: 12,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: c.highlightAction,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension: 44,
                child: Center(
                  child: WorldCupIcon(
                    TrophyPainter(c.onHighlightAction),
                    size: 22,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    WorldCupText.title,
                    style: CoraTextStyles.buttonMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: c.text,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      WorldCupText.bannerDescription(savedCount),
                      style: CoraTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w400,
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Semantics(
              container: true,
              button: true,
              onTap: onStart,
              child: ExcludeSemantics(
                child: CoraPressable(
                  onTap: onStart,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.highlightAction,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: SizedBox(
                      height: 38,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Center(
                          widthFactor: 1,
                          child: Text(
                            WorldCupText.bannerStart,
                            maxLines: 1,
                            style: CoraTextStyles.label.copyWith(
                              color: c.onHighlightAction,
                            ),
                          ),
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
    );
  }
}
