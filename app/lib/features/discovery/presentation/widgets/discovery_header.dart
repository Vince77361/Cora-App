import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shadows.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_logo.dart';
import '../../../notifications/presentation/widgets/notification_bell.dart';
import '../discovery_text.dart';

/// 01 발견 머리(캔버스 Main): 높이 64, 좌우 16. 왼쪽 로고 `cora`, 오른쪽 종 아이콘과 역할 알약
/// (`브랜드`가 고른 쪽). 알약 안의 `크리에이터`는 보여 주기만 한다(역할은 바꿀 수 없다).
class DiscoveryHeader extends StatelessWidget {
  const DiscoveryHeader({super.key});

  static const double height = 64;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const CoraLogo(size: 26),
            Row(
              spacing: 6,
              children: [const NotificationBell(), const DiscoveryRolePill()],
            ),
          ],
        ),
      ),
    );
  }
}

/// 역할 알약: 안쪽 4, 칸 둘(`브랜드`가 고른 쪽). 고른 칸은 `stepPill` 바탕(라이트 흰색+그림자, 다크
/// `#F2F3F5`), 고르지 않은 칸은 보조 글자색이다.
class DiscoveryRolePill extends StatelessWidget {
  const DiscoveryRolePill({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget cell(String label, {required bool selected}) => DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? c.stepPill : null,
        borderRadius: BorderRadius.circular(999),
        boxShadow: selected ? CoraShadows.stepPill(c.stepPillShadow) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(
          label,
          style: CoraTextStyles.label.copyWith(
            height: 1.0,
            color: selected ? c.onStepPill : c.textSecondary,
          ),
        ),
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          spacing: 2,
          children: [
            cell(DiscoveryTexts.brandPill, selected: true),
            cell(DiscoveryTexts.creatorPill, selected: false),
          ],
        ),
      ),
    );
  }
}
