import 'package:flutter/material.dart';

import '../../../../core/navigation/cora_hero_tag.dart';
import '../../../../core/ui/swipe_deck/swipe_card_frame.dart';
import '../../../store_browse/presentation/widgets/photo_overlays.dart';
import '../../domain/discovery_card.dart';
import '../creator_discovery_text.dart';
import 'swipe_progress_bar.dart';

/// 08의 카드 한 장(캠페인 카드 또는 가게 카드). 틀은 01과 같은 [SwipeCardFrame]이고 08 캔버스와 다른 점만
/// 바꾼다: 사진 기준점 62% 50%, 진행 막대 두 칸, 표지 `내 원칙과 맞는 캠페인 {n} / {total}`.
///
/// - 캠페인 카드: 브랜드 이름, 캠페인 한 줄, `{제작비}` 또는 `{제작비} + 제품`, 꼬리표. 사진은 `Hero`
///   (`campaign:<id>`)로 D1에 이어진다.
/// - 가게 카드: 가게 이름, 소개 첫 문장, 보상 줄(`식사권 + 조회수 수당`), 꼬리표(`#소상공인 #팔로워무관`).
///   내 지역이 아닌 가게면 사진 위 오른쪽에 시·도 표지(캔버스 밖)가 붙는다. 사진은 `Hero`(`store:<id>`)로 D2에 이어진다.
class DiscoverySwipeCard extends StatelessWidget {
  const DiscoverySwipeCard({
    super.key,
    required this.card,
    required this.position,
    required this.total,
  });

  final DiscoveryCard card;

  /// 오늘 목록에서 이 카드의 순번(1부터)과 전체 수.
  final int position;
  final int total;

  /// 캔버스 08의 `object-position: 62% 50%`.
  static const photoAlignment = Alignment(0.24, 0);

  @override
  Widget build(BuildContext context) {
    final card = this.card;
    final badge = CreatorDiscoveryTexts.badge(position, total);
    final frame = switch (card) {
      CampaignCard() => SwipeCardFrame(
        photoUrl: card.photoUrl,
        badge: badge,
        name: card.brandName,
        title: card.headline,
        priceLine: CreatorDiscoveryTexts.cardPrice(card),
        tags: card.tags,
        heroTag: CoraHeroTag.of('campaign', card.campaignId),
        photoAlignment: photoAlignment,
      ),
      StoreCard() => SwipeCardFrame(
        photoUrl: card.photoUrl,
        badge: badge,
        name: card.store.name,
        title: card.headline,
        priceLine: card.rewardLine ?? '',
        tags: card.tags,
        heroTag: CoraHeroTag.of('store', card.store.id),
        photoAlignment: photoAlignment,
      ),
    };
    final sido = card is StoreCard ? card.otherSido : null;
    return Stack(
      fit: StackFit.expand,
      children: [
        frame,
        const SwipeProgressBar(segments: 2),
        if (sido != null)
          Positioned(right: 14, top: 22, child: PhotoChip(sido)),
      ],
    );
  }
}
