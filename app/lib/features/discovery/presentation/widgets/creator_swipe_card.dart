import 'package:flutter/material.dart';

import '../../../../core/navigation/cora_hero_tag.dart';
import '../../../../core/ui/swipe_deck/swipe_card_frame.dart';
import '../../domain/discovery_card.dart';
import '../discovery_text.dart';
import 'featured_post_viewer.dart';
import 'swipe_progress_bar.dart';

/// 01의 크리에이터 카드 한 장. 카드 틀(사진, 이름, 콘텐츠 한 줄, 희망 제작비, 꼬리표)은 덱의
/// [SwipeCardFrame]이고, 캔버스에 있는 카드 위쪽 작은 진행 막대 세 칸(첫 칸만 채움)을 얹는다.
/// 사진은 상세로 갈 때 `Hero`(`creator:<id>`)로 이어진다.
///
/// 대표 게시물([CreatorCard.posts])이 있으면 [FeaturedPostViewer]로 게시물을 넘겨 보고(막대는 게시물
/// 수만큼), 카드 아래 글자 덮개를 탭하면 [onOpenDetail]로 상세를 연다. 없으면 지금처럼 사진 한 장이다.
class CreatorSwipeCard extends StatelessWidget {
  const CreatorSwipeCard({
    super.key,
    required this.card,
    required this.position,
    required this.total,
    this.onOpenDetail,
  });

  final CreatorCard card;

  /// 오늘 목록에서 이 카드의 순번(1부터)과 전체 수.
  final int position;
  final int total;

  /// 대표 게시물을 넘겨 보는 카드에서 상세를 여는 방법(글자 덮개 탭). 사진 한 장 카드는 덱의 탭이 연다.
  final VoidCallback? onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final heroTag = CoraHeroTag.of('creator', card.creatorId);
    final priceLine = DiscoveryTexts.feeBandLabel(card.feeBand);
    if (card.posts.isNotEmpty) {
      return FeaturedPostViewer(
        key: ValueKey(card.creatorId),
        posts: card.posts,
        badgeBuilder: (_, _) => DiscoveryTexts.badge(position, total),
        name: card.displayName,
        fallbackTitle: card.headline ?? DiscoveryTexts.noHeadline,
        priceLine: priceLine,
        tags: card.tags,
        heroTag: heroTag,
        onOpenDetail: onOpenDetail,
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        SwipeCardFrame(
          photoUrl: card.photoUrl,
          badge: DiscoveryTexts.badge(position, total),
          name: card.displayName,
          title: card.headline ?? DiscoveryTexts.noHeadline,
          priceLine: priceLine,
          tags: card.tags,
          heroTag: heroTag,
        ),
        const SwipeProgressBar(segments: 3),
      ],
    );
  }
}
