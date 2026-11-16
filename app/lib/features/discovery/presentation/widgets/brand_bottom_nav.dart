import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/ui/cora_bottom_nav.dart';

/// 브랜드 화면의 하단 메뉴. 항목은 크리에이터 메뉴와 같은 다섯 개(발견, 관심, 대화, 협업, 프로필)이고
/// 캔버스 아이콘도 같다. 발견은 제자리에서 바뀐다.
///
/// 발견·관심(03)·협업(브랜드의 협업 탭, 하나면 07)은 제자리에서 바뀐다. 대화는 뒤 계획의 몫이라
/// `준비 중이에요.`이고, 프로필은 역할 다시 고르기와 로그아웃만 있는 자리 화면이다(계정을 바꿔 가며 확인할
/// 수 있게).
class BrandBottomNav extends StatelessWidget {
  const BrandBottomNav({
    super.key,
    this.currentIndex = CoraCreatorNavItems.discover,
  });

  final int currentIndex;

  void _onTap(BuildContext context, int index) {
    // 협업 탭은 지금 탭이어도 누르면 그 탭의 바닥으로 돌아간다(07이 쌓여 열렸거나 링크로 열렸을 때).
    if (index == currentIndex && index != CoraCreatorNavItems.collab) return;
    if (index == CoraCreatorNavItems.discover) {
      context.go(AppRoutes.brand);
      return;
    }
    if (index == CoraCreatorNavItems.likes) {
      context.go(AppRoutes.brandInterests);
      return;
    }
    if (index == CoraCreatorNavItems.collab) {
      context.go(AppRoutes.brandCollaborations);
      return;
    }
    context.push(
      index == CoraCreatorNavItems.profile
          ? AppRoutes.brandProfile
          : AppRoutes.brandComingSoon(CoraCreatorNavItems.items[index].label),
      extra: AppRoutes.stacked,
    );
  }

  @override
  Widget build(BuildContext context) => CoraBottomNav(
    items: CoraCreatorNavItems.items,
    currentIndex: currentIndex,
    onTap: (index) => _onTap(context, index),
  );
}
