import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_featured_post_tokens.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../featured_posts_text.dart';
import 'featured_post_icon.dart';

/// 게시물을 눌러 나오는 시트에서 고른 것.
enum PostSheetAction {
  replaceFromInstagram,
  replaceFromGallery,
  moveToFront,
  remove,
}

/// 순서·교체 시트(캔버스 M19G6Sheet). 항목을 누르면 그 값으로 닫히고, 시트 밖을 누르면 null이다. `맨 앞으로 보내기`는
/// 1번이 아닌 게시물([canMoveToFront])에만 보인다(설계 7.1).
Future<PostSheetAction?> showPostSheet(
  BuildContext context, {
  required int number,
  required bool canMoveToFront,
}) {
  return showModalBottomSheet<PostSheetAction>(
    context: context,
    useSafeArea: true,
    // 바탕은 시트 안에서 칠한다. 시트가 열린 채 밝기가 바뀌어도 따라가게 한다.
    backgroundColor: Colors.transparent,
    barrierColor: CoraFeaturedPostTokens.sheetBarrier,
    elevation: 0,
    showDragHandle: false,
    builder: (context) => DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(CoraRadius.xxl),
        ),
      ),
      child: PostSheet(number: number, canMoveToFront: canMoveToFront),
    ),
  );
}

class PostSheet extends StatelessWidget {
  const PostSheet({
    super.key,
    required this.number,
    required this.canMoveToFront,
  });

  final int number;
  final bool canMoveToFront;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    return Semantics(
      container: true,
      label: FeaturedPostsText.postNumber(number),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(top: 12, bottom: bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ExcludeSemantics(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.line,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const SizedBox(width: 40, height: 5),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      FeaturedPostsText.postNumber(number),
                      style: CoraTextStyles.bodyLarge.copyWith(
                        fontSize: 20,
                        letterSpacing: -0.4,
                        color: c.text,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    FeaturedPostsText.sheetBody,
                    style: CoraTextStyles.bodySmall.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _SheetRow(
              glyph: FeaturedPostGlyph.instagram,
              label: FeaturedPostsText.replaceFromInstagram,
              onTap: () => Navigator.of(
                context,
              ).pop(PostSheetAction.replaceFromInstagram),
            ),
            _SheetRow(
              glyph: FeaturedPostGlyph.gallery,
              label: FeaturedPostsText.replaceFromGallery,
              onTap: () =>
                  Navigator.of(context).pop(PostSheetAction.replaceFromGallery),
            ),
            if (canMoveToFront)
              _SheetRow(
                glyph: FeaturedPostGlyph.upArrow,
                label: FeaturedPostsText.moveToFront,
                onTap: () =>
                    Navigator.of(context).pop(PostSheetAction.moveToFront),
              ),
            _SheetRow(
              glyph: FeaturedPostGlyph.trash,
              label: FeaturedPostsText.remove,
              onTap: () => Navigator.of(context).pop(PostSheetAction.remove),
            ),
          ],
        ),
      ),
    );
  }
}

/// 항목 한 줄: 높이 60, 좌우 24, 지름 40의 `surface` 동그라미 안 아이콘 18, 글자 16.
class _SheetRow extends StatelessWidget {
  const _SheetRow({
    required this.glyph,
    required this.label,
    required this.onTap,
  });

  final FeaturedPostGlyph glyph;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Row(
                spacing: 14,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.surface,
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox.square(
                      dimension: 40,
                      child: Center(
                        child: FeaturedPostIcon(
                          glyph,
                          size: 18,
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      label,
                      style: CoraTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w400,
                        color: c.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
