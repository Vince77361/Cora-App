import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_text_styles.dart';

/// 가운데 작은 글씨의 안내 줄(조건 확인, 협의 그만둠 같은 일). 날짜 구분선과 같은 12px `textSecondary`다.
/// 문구는 서버가 읽는 사람에 맞춰 만들어 보낸다.
class SystemLine extends StatelessWidget {
  const SystemLine({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: CoraTextStyles.caption.copyWith(
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: context.colors.textSecondary,
      ),
    ),
  );
}

/// 날짜가 바뀌는 곳의 구분선. 캔버스 `11월 10일`(12px, `textSecondary`, 가운데).
class DayDivider extends StatelessWidget {
  const DayDivider({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      text,
      style: CoraTextStyles.caption.copyWith(
        fontWeight: FontWeight.w400,
        color: context.colors.textSecondary,
      ),
    ),
  );
}
