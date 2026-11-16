import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../../../../core/ui/cora_secondary_button.dart';
import '../brand_onboarding_text.dart';

/// `캠페인 마감`을 누르면 아래에서 올라오는 확인 시트(캔버스에 없는 화면). `마감하기`를 누르면 true,
/// `취소`나 시트 밖을 누르면 null을 돌려준다. 마감 자체는 부른 쪽이 한다.
Future<bool?> showCloseCampaignSheet(BuildContext context) {
  final c = context.colors;
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // 바탕은 시트 안에서 칠한다. 시트가 열린 채 밝기가 바뀌어도 따라가게 한다.
    backgroundColor: Colors.transparent,
    barrierColor: c.scrim.withValues(alpha: 0.4),
    elevation: 0,
    showDragHandle: false,
    builder: (context) => DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(CoraRadius.xxl),
        ),
      ),
      child: const CloseCampaignSheet(),
    ),
  );
}

class CloseCampaignSheet extends StatelessWidget {
  const CloseCampaignSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 28, 16, bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Semantics(
              header: true,
              child: Text(
                BrandOnboardingTexts.closeConfirm,
                style: CoraTextStyles.heading.copyWith(color: c.text),
              ),
            ),
          ),
          const SizedBox(height: 20),
          CoraPrimaryButton(
            label: BrandOnboardingTexts.closeAction,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: 8),
          CoraSecondaryButton(
            label: BrandOnboardingTexts.closeKeep,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
