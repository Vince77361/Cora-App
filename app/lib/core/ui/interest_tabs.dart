import 'package:flutter/material.dart';

import '../theme/cora_colors.dart';
import '../theme/cora_shadows.dart';
import '../theme/cora_text_styles.dart';
import 'cora_pressable.dart';

/// 03의 탭(캔버스 Likes `role="tablist"`): 높이 36, 좌우 안쪽 14, 사이 6. 고른 탭은 `quietSelected` 바탕에
/// 작은 그림자(라이트 흰색, 다크 `#2A2D33`), 나머지는 `surface` 바탕이고 글자는 둘 다 `text` 13/500이다.
/// 글자를 크게 보면 옆으로 밀어서 본다.
///
/// 사장님 저장함(캔버스 M19G2TabsB `.tab`)은 같은 알약을 높이 38, 고른 탭 `notifyTabSelected` 바탕에 그림자 없이
/// 쓴다([height], [selectedColor], [selectedShadow], [semanticLabel]로 바꾼다).
class InterestTabs extends StatelessWidget {
  const InterestTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.height = 36,
    this.selectedColor,
    this.selectedShadow = true,
    required this.semanticLabel,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  final double height;

  /// 고른 탭의 바탕. 없으면 `quietSelected`다.
  final Color? selectedColor;
  final bool selectedShadow;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      label: semanticLabel,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Row(
          spacing: 6,
          children: [
            for (final (i, label) in labels.indexed)
              Semantics(
                container: true,
                button: true,
                label: label,
                selected: i == selected,
                onTap: () => onChanged(i),
                child: ExcludeSemantics(
                  child: CoraPressable(
                    onTap: () => onChanged(i),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: i == selected
                            ? (selectedColor ?? c.quietSelected)
                            : c.surface,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: i == selected && selectedShadow
                            ? CoraShadows.segmentSelected
                            : null,
                      ),
                      child: SizedBox(
                        height: height,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Center(
                            child: Text(
                              label,
                              style: CoraTextStyles.label.copyWith(
                                color: c.text,
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
