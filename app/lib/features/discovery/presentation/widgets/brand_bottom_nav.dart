import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/ui/cora_bottom_nav.dart';

/// 브랜드 화면의 하단 메뉴. 항목은 크리에이터 메뉴와 같은 다섯 개(발견, 관심, 대화, 협업, 프로필)이고
/// 캔버스 아이콘도 같다. 발견은 제자리에서 바뀐다.
///
/// 관심(03)과 협업(07)은 10·11번 작업이 화면을 등록한다. 그때까지는 `준비 중이에요.` 화면을 위에 쌓고,
/// 그 작업이 이 두 줄을 [AppRoutes.brandInterests]·[AppRoutes.brandCollaborations]로 바꾼다. 대화와
/// 프로필은 뒤 계획의 몫이다. 대화는 `준비 중이에요.`이고, 프로필은 역할 다시 고르기와 로그아웃만 있는 자리
/// 화면이다(계정을 바꿔 가며 확인할 수 있게).
class BrandBottomNav extends StatelessWidget {
  const BrandBottomNav({
    super.key,
    this.currentIndex = CoraCreatorNavItems.discover,
  });

  final int currentIndex;

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;
    if (index == CoraCreatorNavItems.discover) {
      context.go(AppRoutes.brand);
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
