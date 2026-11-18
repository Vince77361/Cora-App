import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../featured_posts_text.dart';
import 'featured_post_icon.dart';

/// 왼쪽 `닫기`(X 20, 굵기 2.4)와 가운데 제목이 있는 머리(캔버스 M19G6Pick·NUpload: 높이 56, 좌우 8, 60 / 1fr / 60).
class FeaturedPostCloseHeader extends StatelessWidget {
  const FeaturedPostCloseHeader({
    super.key,
    required this.title,
    required this.onClose,
  });

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Semantics(
                  container: true,
                  button: true,
                  label: FeaturedPostsText.pickClose,
                  onTap: onClose,
                  child: ExcludeSemantics(
                    child: CoraPressable(
                      onTap: onClose,
                      child: SizedBox.square(
                        dimension: 44,
                        child: Center(
                          child: FeaturedPostIcon(
                            FeaturedPostGlyph.close,
                            size: 20,
                            color: c.text,
                            strokeWidth: 2.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CoraTextStyles.bodyLarge.copyWith(color: c.text),
                ),
              ),
            ),
            const SizedBox(width: 60),
          ],
        ),
      ),
    );
  }
}
