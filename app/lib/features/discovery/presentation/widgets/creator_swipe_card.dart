import 'package:flutter/material.dart';

import '../../../../core/navigation/cora_hero_tag.dart';
import '../../../../core/ui/swipe_deck/swipe_card_frame.dart';
import '../../domain/discovery_card.dart';
import '../discovery_text.dart';
import 'swipe_progress_bar.dart';

/// 01의 크리에이터 카드 한 장. 카드 틀(사진, 이름, 콘텐츠 한 줄, 희망 제작비, 꼬리표)은 덱의
/// [SwipeCardFrame]이고, 캔버스에 있는 카드 위쪽 작은 진행 막대 세 칸(첫 칸만 채움)을 얹는다.
/// 사진은 상세로 갈 때 `Hero`(`creator:<id>`)로 이어진다.
class CreatorSwipeCard extends StatelessWidget {
  const CreatorSwipeCard({
    super.key,
    required this.card,
    required this.position,
    required this.total,
  });

  final CreatorCard card;

  /// 오늘 목록에서 이 카드의 순번(1부터)과 전체 수.
  final int position;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        SwipeCardFrame(
          photoUrl: card.photoUrl,
          badge: DiscoveryTexts.badge(position, total),
          name: card.displayName,
          title: card.headline ?? DiscoveryTexts.noHeadline,
          priceLine: DiscoveryTexts.feeBandLabel(card.feeBand),
          tags: card.tags,
          heroTag: CoraHeroTag.of('creator', card.creatorId),
        ),
        const SwipeProgressBar(segments: 3),
      ],
    );
  }
}
