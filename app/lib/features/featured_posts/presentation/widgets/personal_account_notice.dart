import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../featured_posts_text.dart';
import 'featured_post_icon.dart';

/// 개인 계정 안내(캔버스 M19G6Personal): `surface` 상자(모서리 20, 안쪽 14/16)에 정보 아이콘과 세 줄. 인스타그램 연동이
/// 거절된 개인 계정의 대표 게시물 화면 위에 놓인다.
class PersonalAccountNotice extends StatelessWidget {
  const PersonalAccountNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(CoraRadius.field),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: FeaturedPostIcon(
                  FeaturedPostGlyph.info,
                  size: 20,
                  color: c.textSecondary,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      FeaturedPostsText.personalTitle,
                      style: CoraTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w500,
                        height: 1.55,
                        color: c.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      FeaturedPostsText.personalBody,
                      style: CoraTextStyles.meta.copyWith(
                        height: 1.55,
                        color: c.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      FeaturedPostsText.personalNoPayout,
                      style: CoraTextStyles.meta.copyWith(
                        height: 1.55,
                        color: c.text,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
