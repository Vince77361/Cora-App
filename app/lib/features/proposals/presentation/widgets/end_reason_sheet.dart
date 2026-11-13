import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_secondary_button.dart';
import '../../domain/proposal.dart';
import '../proposal_text.dart';

/// 제안을 끝내는 이유를 고르는 시트(`제안 종료`·`거절`·`제안 취소`가 연다). 캔버스에 없는 화면이라 기존 시트와
/// 같은 모양(제목 19/700, 좌우 16)에 선택지 네 개를 세로로 놓았다. 하나를 고르면 시트가 닫히며 그 사유를
/// 돌려준다. 시트 밖을 눌러 닫으면 null이다.
Future<EndReason?> showEndReasonSheet(
  BuildContext context, {
  required String title,
}) {
  final c = context.colors;
  return showModalBottomSheet<EndReason>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: c.background,
    barrierColor: c.scrim.withValues(alpha: 0.4),
    elevation: 0,
    showDragHandle: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(CoraRadius.xxl)),
    ),
    builder: (_) => EndReasonSheet(title: title),
  );
}

class EndReasonSheet extends StatelessWidget {
  const EndReasonSheet({super.key, required this.title});

  final String title;

  static const description = '이유를 고르면 바로 끝나요. 끝난 제안은 되돌릴 수 없어요.';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 28, 16, bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: CoraTextStyles.heading.copyWith(color: c.text),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
              child: Text(
                description,
                style: CoraTextStyles.bodySmall.copyWith(
                  color: c.textSecondary,
                ),
              ),
            ),
            for (final reason in EndReason.values) ...[
              CoraSecondaryButton(
                label: endReasonLabel(reason),
                onPressed: () => Navigator.of(context).pop(reason),
              ),
              if (reason != EndReason.values.last) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}
