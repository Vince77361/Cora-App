import 'package:flutter/material.dart';

import '../../../discovery/domain/featured_post_ref.dart';
import '../../../discovery/presentation/widgets/featured_post_viewer.dart';
import '../../domain/store_creator_card.dart';
import '../store_discover_text.dart';

/// 사장님 전체 둘러보기의 카드 한 장(캔버스 M19G1Swipe). 대표 게시물 사진 위에 진행 막대와
/// `대표 게시물 {i} / {n}`, 아래에 활동 이름(작게)·한 줄(큰 글자, 최대 두 줄)·`{분야} · 팔로워 {n}`(형광)·
/// 꼬리표가 있다. 오른쪽 절반을 탭하면 다음, 왼쪽 절반은 이전 게시물이다([FeaturedPostViewer]).
class FeaturedPostCard extends StatelessWidget {
  const FeaturedPostCard({super.key, required this.card});

  final StoreCreatorCard card;

  @override
  Widget build(BuildContext context) {
    // 대표 게시물이 없는 크리에이터는 서버가 내려 주지 않지만, 혹시 오면 카드의 사진과 한 줄 하나로 보인다.
    final posts = card.posts.isNotEmpty
        ? card.posts
        : [FeaturedPostRef(photoUrl: card.photoUrl, caption: card.headline)];
    return FeaturedPostViewer(
      key: ValueKey(card.creatorId),
      posts: posts,
      badgeBuilder: StoreDiscoverTexts.badge,
      name: card.displayName,
      fallbackTitle: card.headline ?? StoreDiscoverTexts.noHeadline,
      priceLine: StoreDiscoverTexts.infoLine(card.contentFocus, card.followers),
      tags: card.tags,
      semanticLabel: StoreDiscoverTexts.cardLabel(card.displayName),
    );
  }
}
