import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../domain/view_report.dart';
import '../view_report_text.dart';

/// A7과 사장님 진행 화면의 `조회 자료와 보상 계산 확인` 줄(NEscrow `<a>`): 모서리 18, `surface`, 안쪽
/// 12/16, 글자 14, 왼쪽에 문구와 오른쪽에 표지. 누르면 F4가 열린다. 줄 밖 여백은 화면이 정한다.
class ViewReportEntryRow extends StatelessWidget {
  const ViewReportEntryRow({
    super.key,
    required this.status,
    required this.onTap,
  });

  final ViewReportStatus status;
  final VoidCallback onTap;

  static const label = '조회 자료와 보상 계산 확인';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final badge = statusLabel(status);
    final style = CoraTextStyles.bodySmall;
    return Semantics(
      container: true,
      button: true,
      label: '$label, $badge',
      onTap: onTap,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(CoraRadius.lg),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                spacing: 8,
                children: [
                  Flexible(
                    child: Text(label, style: style.copyWith(color: c.text)),
                  ),
                  Text(badge, style: style.copyWith(color: c.textSecondary)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
