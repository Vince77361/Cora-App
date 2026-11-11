import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/ui/cora_bottom_nav.dart';

/// 크리에이터 화면의 하단 메뉴. 발견·협업은 탭처럼 제자리에서 바뀌고, 아직 만들지 않은
/// 관심·대화·프로필은 `준비 중이에요.` 화면을 위에 쌓는다.
class CreatorBottomNav extends StatelessWidget {
  const CreatorBottomNav({super.key, required this.currentIndex});

  final int currentIndex;

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;
    switch (index) {
      case CoraCreatorNavItems.discover:
        context.go(AppRoutes.creator);
      case CoraCreatorNavItems.collab:
        context.go(AppRoutes.creatorOffers);
      default:
        context.push(
          AppRoutes.creatorComingSoon(CoraCreatorNavItems.items[index].label),
          extra: AppRoutes.stacked,
        );
    }
  }

  @override
  Widget build(BuildContext context) => CoraBottomNav(
    items: CoraCreatorNavItems.items,
    currentIndex: currentIndex,
    onTap: (index) => _onTap(context, index),
  );
}
