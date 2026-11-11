import 'package:flutter/material.dart';

import '../theme/cora_colors.dart';
import '../theme/cora_motion.dart';
import '../theme/cora_shapes.dart';
import '../theme/cora_text_styles.dart';
import 'cora_pressable.dart';

/// 목록 위의 알약 탭(캔버스 NStoreHome `role="tablist"`). 높이 38, 좌우 안쪽 14, 사이 6.
/// 선택된 탭은 `surfaceSelected` 바탕, 나머지는 `surface` 바탕이다. 좌우 여백은 화면이 정한다.
///
/// 탭이 화면 너비보다 길어지면(글자 크게 보기) 옆으로 밀어서 본다.
class CoraSegmentedTabs extends StatelessWidget {
  const CoraSegmentedTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  static const double height = 38;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final (i, label) in labels.indexed) ...[
            if (i > 0) const SizedBox(width: 6),
            _Tab(
              label: label,
              selected: i == selected,
              onTap: () => onChanged(i),
            ),
          ],
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onTap,
          child: AnimatedContainer(
            duration: CoraMotion.resolve(context, CoraMotion.stateDuration),
            curve: CoraMotion.standardCurve,
            height: CoraSegmentedTabs.height,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? c.surfaceSelected : c.surface,
              borderRadius: BorderRadius.circular(CoraRadius.pill),
            ),
            child: Text(
              label,
              maxLines: 1,
              style: CoraTextStyles.label.copyWith(
                color: selected ? c.onSurfaceSelected : c.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
