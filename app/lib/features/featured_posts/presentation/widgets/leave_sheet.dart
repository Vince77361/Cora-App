import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../featured_posts_text.dart';
import 'featured_post_buttons.dart';
import 'featured_post_sheet_frame.dart';

enum LeaveChoice { save, discard }

/// 바뀐 것이 있는 채로 나갈 때 묻는다(캔버스 밖, 설계 7.1). 시트 밖을 누르면 null이고 화면에 머문다.
Future<LeaveChoice?> showLeaveSheet(BuildContext context) =>
    showFeaturedPostSheet<LeaveChoice>(
      context,
      builder: (context) => const LeaveSheet(),
    );

class LeaveSheet extends StatelessWidget {
  const LeaveSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 28, 16, bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Semantics(
              header: true,
              child: Text(
                FeaturedPostsText.leaveAsk,
                style: CoraTextStyles.heading.copyWith(color: c.text),
              ),
            ),
          ),
          CoraPrimaryButton(
            label: FeaturedPostsText.save,
            look: CoraPrimaryButtonLook.accent,
            onPressed: () => Navigator.of(context).pop(LeaveChoice.save),
          ),
          FeaturedPostButton(
            label: FeaturedPostsText.leaveDiscard,
            onPressed: () => Navigator.of(context).pop(LeaveChoice.discard),
          ),
        ],
      ),
    );
  }
}
