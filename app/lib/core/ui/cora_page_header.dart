import 'package:flutter/material.dart';

import '../theme/cora_colors.dart';
import '../theme/cora_text_styles.dart';
import 'cora_step_header.dart';

/// 가운데 제목이 있는 화면 머리(캔버스 NEscrow·NPay `<header>`): 높이 56, 좌우 8, 60 / 1fr / 60.
/// 왼쪽은 뒤로 가기, 가운데는 16/500 제목, 오른쪽 60 칸에는 [trailing]이 들어간다.
class CoraPageHeader extends StatelessWidget {
  const CoraPageHeader({
    super.key,
    this.title,
    required this.onBack,
    this.trailing,
    this.extent,
  });

  final String? title;
  final VoidCallback onBack;

  /// 오른쪽 60 칸에 오른쪽 정렬로 놓인다(예: 더보기 버튼).
  final Widget? trailing;

  /// 머리 높이. 비우면 [height](56)다. E5·E7(NNotifySettings·NWallet)은 캔버스가 64로 그린다.
  final double? extent;

  static const double height = 56;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: extent ?? height,
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
              child: title == null
                  ? const SizedBox.shrink()
                  : Semantics(
                      header: true,
                      child: Text(
                        title!,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CoraTextStyles.bodyLarge.copyWith(color: c.text),
                      ),
                    ),
            ),
            SizedBox(
              width: 60,
              child: Align(alignment: Alignment.centerRight, child: trailing),
            ),
          ],
        ),
      ),
    );
  }
}
