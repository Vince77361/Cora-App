import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shadows.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_logo.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../notifications/presentation/widgets/notification_bell.dart';
import '../discovery_text.dart';

/// 01 발견 머리(캔버스 Main): 높이 64, 좌우 16. 왼쪽 로고 `cora`, 오른쪽 종 아이콘과 역할 알약
/// (`브랜드`가 고른 쪽). 알약 안의 `크리에이터`는 보여 주기만 한다(역할은 바꿀 수 없다).
///
/// [onChooseRole]을 주면 둘러보기(9A)의 머리다. 종 아이콘이 없고, 알약은 `둘러보는 중` 한 칸이며,
/// 오른쪽에 `역할 고르기`가 있다.
class DiscoveryHeader extends StatelessWidget {
  const DiscoveryHeader({super.key, this.onChooseRole});

  /// 둘러보기에서 `역할 고르기`를 눌렀을 때. null이면 01의 머리다.
  final VoidCallback? onChooseRole;

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
            if (onChooseRole case final choose?)
              Row(
                spacing: 6,
                children: [
                  const DiscoveryRolePill(cells: [DiscoveryTexts.previewPill]),
                  _ChooseRoleLink(onTap: choose),
                ],
              )
            else
              const Row(
                spacing: 6,
                children: [NotificationBell(), DiscoveryRolePill()],
              ),
          ],
        ),
      ),
    );
  }
}

/// 역할 알약: 안쪽 4, 칸 둘(`브랜드`가 고른 쪽). 고른 칸은 `stepPill` 바탕(라이트 흰색+그림자, 다크
/// `#F2F3F5`), 고르지 않은 칸은 보조 글자색이다. [cells]를 주면 그 칸들이 모두 고른 칸이다
/// (둘러보기의 `둘러보는 중` 한 칸).
class DiscoveryRolePill extends StatelessWidget {
  const DiscoveryRolePill({super.key, this.cells});

  final List<String>? cells;

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
            if (cells case final only?)
              for (final label in only) cell(label, selected: true)
            else ...[
              cell(DiscoveryTexts.brandPill, selected: true),
              cell(DiscoveryTexts.creatorPill, selected: false),
            ],
          ],
        ),
      ),
    );
  }
}

/// 둘러보기 머리 오른쪽의 `역할 고르기`. 글자는 보조 글자색, 누를 칸은 높이 44(A1의 둘러보기 줄과 같은 글자).
class _ChooseRoleLink extends StatelessWidget {
  const _ChooseRoleLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      label: DiscoveryTexts.chooseRole,
      onTap: onTap,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onTap,
          child: SizedBox(
            height: 44,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Center(
                child: Text(
                  DiscoveryTexts.chooseRole,
                  style: CoraTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                    color: c.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
