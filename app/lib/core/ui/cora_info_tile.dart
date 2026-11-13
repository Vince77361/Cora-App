import 'package:flutter/material.dart';

import '../theme/cora_colors.dart';
import '../theme/cora_shapes.dart';
import '../theme/cora_text_styles.dart';
import 'cora_pressable.dart';

/// 이름과 값을 한 칸에 담는 정보 칸(캔버스 NStorePage `<dl>`의 칸). 모서리 18, `surface` 바탕,
/// 안쪽 12/14. 이름은 12px 보조색, 값은 15px 500이고 그 사이 4다. 너비는 부모가 정한다.
///
/// [value]가 null이거나 비어 있으면 `아직 없어요`를 보조색으로 보여 준다(캔버스에 없는 상태).
/// [onTap]이 있으면 칸 전체를 눌러 고칠 수 있다(A3).
class CoraInfoTile extends StatelessWidget {
  const CoraInfoTile({
    super.key,
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final String? value;
  final VoidCallback? onTap;

  static const emptyValue = '아직 없어요';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = value;
    final empty = text == null || text.trim().isEmpty;
    final tile = DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(CoraRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: CoraTextStyles.fieldLabel.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              empty ? emptyValue : text,
              style: CoraTextStyles.buttonMedium.copyWith(
                color: empty ? c.textSecondary : c.text,
              ),
            ),
          ],
        ),
      ),
    );
    return Semantics(
      container: true,
      button: onTap != null,
      label: label,
      value: empty ? emptyValue : text,
      onTap: onTap,
      child: ExcludeSemantics(
        child: onTap == null ? tile : CoraPressable(onTap: onTap, child: tile),
      ),
    );
  }
}
