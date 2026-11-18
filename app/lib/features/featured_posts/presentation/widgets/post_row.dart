import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_featured_post_tokens.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_network_photo.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../domain/featured_post.dart';
import '../featured_posts_text.dart';
import 'featured_post_icon.dart';

/// 대표 게시물 칸 네 개(캔버스 M19G6Empty·Full·Sheet·Personal). 캔버스는 번호 1~4를 2열로 놓은 격자이고 게시물이 없는
/// 번호는 점선 빈 틀이다. 게시물 칸을 꾹 눌러 다른 칸에 놓으면 그 자리로 옮겨진다(나머지는 한 칸씩 밀린다).
///
/// [cellHeight]는 보통 232, 개인 계정 안내가 위에 있을 때 200이다. [selectedIndex] 칸에는 시트가 열린 동안 라임 고리가 둘린다.
class FeaturedPostGrid extends StatelessWidget {
  const FeaturedPostGrid({
    super.key,
    required this.items,
    required this.onTap,
    required this.onReorder,
    this.selectedIndex,
    this.cellHeight = defaultCellHeight,
  });

  final List<FeaturedPost> items;
  final int? selectedIndex;
  final double cellHeight;

  /// 게시물 칸을 눌렀다(시트를 연다).
  final ValueChanged<int> onTap;

  /// [from]번째 게시물을 [to]번째 자리로 옮긴다.
  final void Function(int from, int to) onReorder;

  static const double defaultCellHeight = 232;
  static const double personalCellHeight = 200;
  static const double gap = 10;

  @override
  Widget build(BuildContext context) {
    Widget cell(int i) => _GridCell(
      index: i,
      post: i < items.length ? items[i] : null,
      height: cellHeight,
      selected: selectedIndex == i,
      onTap: () => onTap(i),
      onDrop: (from) => onReorder(from, math.min(i, items.length - 1)),
    );
    return Column(
      children: [
        Row(
          spacing: gap,
          children: [
            Expanded(child: cell(0)),
            Expanded(child: cell(1)),
          ],
        ),
        const SizedBox(height: gap),
        Row(
          spacing: gap,
          children: [
            Expanded(child: cell(2)),
            Expanded(child: cell(3)),
          ],
        ),
      ],
    );
  }
}

class _GridCell extends StatelessWidget {
  const _GridCell({
    required this.index,
    required this.post,
    required this.height,
    required this.selected,
    required this.onTap,
    required this.onDrop,
  });

  final int index;
  final FeaturedPost? post;
  final double height;
  final bool selected;
  final VoidCallback onTap;
  final ValueChanged<int> onDrop;

  @override
  Widget build(BuildContext context) {
    final filled = post;
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != index,
      onAcceptWithDetails: (details) => onDrop(details.data),
      builder: (context, candidates, rejected) {
        final hovering = candidates.isNotEmpty;
        if (filled == null) {
          return _EmptySlot(
            number: index + 1,
            height: height,
            highlighted: hovering,
          );
        }
        return LayoutBuilder(
          builder: (context, box) {
            Widget card({bool ring = false}) => _PostCard(
              post: filled,
              number: index + 1,
              height: height,
              ring: ring,
            );
            return LongPressDraggable<int>(
              data: index,
              feedback: Material(
                color: Colors.transparent,
                child: SizedBox(
                  width: box.maxWidth,
                  height: height,
                  child: Opacity(opacity: 0.92, child: card(ring: true)),
                ),
              ),
              childWhenDragging: Opacity(opacity: 0.35, child: card()),
              child: Semantics(
                container: true,
                button: true,
                label:
                    '${FeaturedPostsText.postNumber(index + 1)}, '
                    '${filled.caption ?? ''}',
                onTap: onTap,
                child: ExcludeSemantics(
                  child: CoraPressable(
                    onTap: onTap,
                    child: card(ring: selected || hovering),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// 게시물이 있는 칸: 사진, 아래 그라데이션과 한 줄, 왼쪽 위 번호와 출처 표지, 오른쪽 위 점 셋.
class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.number,
    required this.height,
    required this.ring,
  });

  final FeaturedPost post;
  final int number;
  final double height;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bytes = post.previewBytes;
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(CoraRadius.lg),
          boxShadow: ring
              ? [BoxShadow(color: c.accent, spreadRadius: 3)]
              : const [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(CoraRadius.lg),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (bytes != null)
                ColoredBox(
                  color: c.avatarPlaceholder,
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    excludeFromSemantics: true,
                    errorBuilder: (context, error, stack) =>
                        const SizedBox.expand(),
                  ),
                )
              else
                CoraNetworkPhoto(
                  url: post.photoUrl,
                  background: c.avatarPlaceholder,
                ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 100,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x0017181C),
                        CoraFeaturedPostTokens.photoScrimEnd,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 8,
                top: 8,
                child: Row(
                  spacing: 5,
                  children: [
                    _NumberDot(number: number, filled: true),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: c.photoChip,
                        borderRadius: BorderRadius.circular(CoraRadius.pill),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Text(
                          post.source == FeaturedPostSource.instagram
                              ? FeaturedPostsText.badgeInstagram
                              : FeaturedPostsText.badgeGallery,
                          style: CoraTextStyles.caption.copyWith(
                            fontSize: 11,
                            color: c.onPhotoChip,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.photoScrim,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox.square(
                    dimension: 30,
                    child: Center(
                      child: FeaturedPostIcon(
                        FeaturedPostGlyph.dots,
                        size: 18,
                        color: c.onPhoto,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 8,
                child: Text(
                  post.caption ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: CoraTextStyles.label.copyWith(
                    color: c.onPhoto,
                    shadows: const [
                      Shadow(
                        color: Color(0x80000000),
                        offset: Offset(0, 1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 번호 동그라미 28. 채워진 것은 라임, 빈 틀의 것은 `notifyTabSelected` 바탕이다.
class _NumberDot extends StatelessWidget {
  const _NumberDot({required this.number, required this.filled});

  final int number;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: filled ? c.accent : c.notifyTabSelected,
        shape: BoxShape.circle,
      ),
      child: SizedBox.square(
        dimension: 28,
        child: Center(
          child: Text(
            '$number',
            style: CoraTextStyles.label.copyWith(
              fontWeight: FontWeight.w700,
              color: filled ? c.onAccent : c.text,
            ),
          ),
        ),
      ),
    );
  }
}

/// 게시물이 없는 번호 칸: 점선 틀, 왼쪽 위 번호, 가운데 더하기.
class _EmptySlot extends StatelessWidget {
  const _EmptySlot({
    required this.number,
    required this.height,
    required this.highlighted,
  });

  final int number;
  final double height;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: highlighted ? c.accent : c.line,
          fill: c.surface,
        ),
        child: Stack(
          children: [
            Positioned(
              left: 8,
              top: 8,
              child: _NumberDot(number: number, filled: false),
            ),
            Center(
              child: FeaturedPostIcon(
                FeaturedPostGlyph.plus,
                size: 26,
                color: c.textSecondary,
                strokeWidth: 2.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CSS `border: 2px dashed`와 같은 점선 틀: 바탕을 채우고, 안쪽 1 안에서 점선을 둥근 모서리 18로 그린다. 점선의 마디는
/// Chrome이 두께 2에 그리는 길이 6, 틈 4다.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.fill});

  final Color color;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(CoraRadius.lg),
    );
    canvas.drawRRect(outer, Paint()..color = fill);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()..addRRect(outer.deflate(1));
    for (final PathMetric metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 6), stroke);
        distance += 10;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.fill != fill;
}
