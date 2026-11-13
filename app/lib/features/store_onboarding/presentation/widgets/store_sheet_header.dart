import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_step_header.dart';

/// 시트 맨 위 줄(NEditProfile 머리글): 뒤로 가기, 가운데 제목 16/500.
class StoreSheetHeader extends StatelessWidget {
  const StoreSheetHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: CoraStepHeader.rowHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: Align(
                alignment: Alignment.centerLeft,
                child: CoraBackButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CoraTextStyles.bodyLarge.copyWith(color: c.text),
              ),
            ),
            const SizedBox(width: 60),
          ],
        ),
      ),
    );
  }
}
