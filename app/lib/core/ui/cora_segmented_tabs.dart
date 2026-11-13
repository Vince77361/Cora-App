import 'package:flutter/material.dart';

import '../theme/cora_colors.dart';
import '../theme/cora_motion.dart';
import '../theme/cora_shapes.dart';
import '../theme/cora_text_styles.dart';
import 'cora_pressable.dart';

/// 목록 위의 알약 탭(캔버스 NStoreHome `role="tablist"`). 높이 38, 좌우 안쪽 14, 사이 6.
/// 선택된 탭은 `notifyTabSelected` 바탕(라이트 #E3E5E9, 다크 #33363D), 나머지는 `surface` 바탕이고
/// 글자는 둘 다 `text`다(NStoreHome·NStoreAI·NNotify와 다크 판이 같다). 좌우 여백은 화면이 정한다.
///
/// 탭이 화면 너비보다 길어지면(글자 크게 보기) 옆으로 밀어서 본다.
class CoraSegmentedTabs extends StatelessWidget {
  const CoraSegmentedTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.horizontalPadding = 14,
    this.textStyle = CoraTextStyles.label,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  /// 탭 안쪽 좌우 여백. 기본 14(NStoreHome). NStoreAI의 탭은 16이다.
  final double horizontalPadding;

  /// 탭 글자 모양(색은 탭이 입힌다). 기본 13/500, NStoreAI의 탭은 14/500이다.
  final TextStyle textStyle;

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
              horizontalPadding: horizontalPadding,
              textStyle: textStyle,
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
    required this.horizontalPadding,
    required this.textStyle,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final double horizontalPadding;
  final TextStyle textStyle;
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
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? c.notifyTabSelected : c.surface,
              borderRadius: BorderRadius.circular(CoraRadius.pill),
            ),
            child: Text(
              label,
              maxLines: 1,
              style: textStyle.copyWith(color: c.text),
            ),
          ),
        ),
      ),
    );
  }
}
