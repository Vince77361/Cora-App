import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../../../../core/ui/cora_secondary_button.dart';
import '../../../../core/ui/swipe_deck/swipe_physics.dart' show SwipeOutcome;
import '../interests_text.dart';

/// 보류한 카드를 눌렀을 때 아래에서 올라오는 시트(캔버스에 없는 화면). 보류를 `관심 보내기`나 `넘기기`로
/// 바꾼다. 고르지 않고 내려 닫으면 null이다.
Future<SwipeOutcome?> showHoldSheet(BuildContext context) {
  return showModalBottomSheet<SwipeOutcome>(
    context: context,
    // 바탕은 시트 안에서 칠한다. 시트가 열린 채 밝기가 바뀌어도 따라가게 한다.
    backgroundColor: Colors.transparent,
    // 캔버스 Pass의 뒤 덮개 rgba(15,16,18,0.45). 두 모드가 같다.
    barrierColor: const Color(0x730F1012),
    elevation: 0,
    showDragHandle: false,
    builder: (context) => DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          30,
          24,
          math.max(32, MediaQuery.viewPaddingOf(context).bottom),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            CoraPrimaryButton(
              label: InterestsTexts.holdLike,
              look: CoraPrimaryButtonLook.accent,
              onPressed: () => Navigator.of(context).pop(SwipeOutcome.like),
            ),
            CoraSecondaryButton(
              label: InterestsTexts.holdPass,
              onPressed: () => Navigator.of(context).pop(SwipeOutcome.pass),
            ),
          ],
        ),
      ),
    ),
  );
}
