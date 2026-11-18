import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/ui/cora_bottom_nav.dart';

/// 크리에이터 화면의 하단 메뉴. 발견·관심·대화·협업은 탭처럼 제자리에서 바뀌고, 프로필은 대표 게시물 화면을
/// 위에 쌓는다(내 프로필 화면은 계정·설정 계획이 만든다).
class CreatorBottomNav extends StatelessWidget {
  const CreatorBottomNav({super.key, required this.currentIndex});

  final int currentIndex;

  void _onTap(BuildContext context, int index) {
    // 협업 탭은 지금 탭이어도 누르면 그 탭의 바닥으로 돌아간다(07이 쌓여 열렸을 때).
    if (index == currentIndex && index != CoraCreatorNavItems.collab) return;
    switch (index) {
      case CoraCreatorNavItems.discover:
        context.go(AppRoutes.creator);
      case CoraCreatorNavItems.likes:
        context.go(AppRoutes.creatorInterests);
      case CoraCreatorNavItems.chat:
        context.go(AppRoutes.chats);
      case CoraCreatorNavItems.collab:
        context.go(AppRoutes.creatorOffers);
      default:
        context.push(AppRoutes.creatorFeaturedPosts);
    }
  }

  @override
  Widget build(BuildContext context) => CoraBottomNav(
    items: CoraCreatorNavItems.items,
    currentIndex: currentIndex,
    onTap: (index) => _onTap(context, index),
  );
}
