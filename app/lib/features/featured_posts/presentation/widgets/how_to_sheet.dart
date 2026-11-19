import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../featured_posts_text.dart';
import 'featured_post_buttons.dart';
import 'featured_post_sheet_frame.dart';

/// `프로페셔널 계정으로 바꾸는 방법` 안내(캔버스 밖, 설계 7.4).
Future<void> showHowToSheet(BuildContext context) =>
    showFeaturedPostSheet<void>(
      context,
      builder: (context) => const HowToSheet(),
    );

class HowToSheet extends StatelessWidget {
  const HowToSheet({super.key});

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    FeaturedPostsText.howToTitle,
                    style: CoraTextStyles.heading.copyWith(color: c.text),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  FeaturedPostsText.howToSteps,
                  style: CoraTextStyles.bodySmall.copyWith(
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FeaturedPostButton(
            label: FeaturedPostsText.howToClose,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
