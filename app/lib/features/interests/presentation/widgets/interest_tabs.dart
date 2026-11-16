import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shadows.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../interests_text.dart';

/// 03의 탭(캔버스 Likes `role="tablist"`): 높이 36, 좌우 안쪽 14, 사이 6. 고른 탭은 `quietSelected` 바탕에
/// 작은 그림자(라이트 흰색, 다크 `#2A2D33`), 나머지는 `surface` 바탕이고 글자는 둘 다 `text` 13/500이다.
/// 글자를 크게 보면 옆으로 밀어서 본다.
class InterestTabs extends StatelessWidget {
  const InterestTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      label: InterestsTexts.tabListLabel,
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
                        color: i == selected ? c.quietSelected : c.surface,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: i == selected
                            ? CoraShadows.segmentSelected
                            : null,
                      ),
                      child: SizedBox(
                        height: 36,
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
