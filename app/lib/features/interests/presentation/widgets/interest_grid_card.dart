import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_network_photo.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../negotiation/presentation/terms_text.dart';
import '../../domain/interest_card.dart';
import '../interests_text.dart';
import '../../../../core/ui/interest_icons.dart';

/// 03의 카드 한 장(캔버스 Likes): 높이 272, 모서리 14. 왼쪽 위 표지, 오른쪽 위 비교 동그라미(브랜드만),
/// 아래 이름·콘텐츠 한 줄·`{금액}, {가능한 날} 이후`가 어두운 그라데이션 위에 얹힌다.
class InterestGridCard extends StatelessWidget {
  const InterestGridCard({
    super.key,
    required this.card,
    required this.onTap,
    this.picked = false,
    this.onTogglePick,
  });

  final InterestCard card;

  /// 동그라미 밖을 눌렀을 때.
  final VoidCallback onTap;

  /// 비교에 골라져 있다.
  final bool picked;

  /// 비교 동그라미를 눌렀을 때. null이면 동그라미가 없다(크리에이터 쪽).
  final VoidCallback? onTogglePick;

  static const double height = 272;

  /// 카드 아래 글의 둘째 줄. 금액은 정해진 금액이 있으면 `30만 원`, 없으면 희망 제작비 구간(`30만 원대`)이고,
  /// 가능한 날이 없으면 `일정 협의`다.
  static String detailLine(InterestCard card) {
    final cash = cashLabel(card.fee, card.feeBand);
    final start = startFromLabel(card.startFrom);
    return cash.isEmpty ? start : '$cash, $start';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final headline = card.headline;
    final onPhotoSecondary = CoraTextStyles.caption.copyWith(
      fontWeight: FontWeight.w400,
      color: c.onPhotoSecondary,
    );
    return Semantics(
      container: true,
      button: true,
      onTap: onTap,
      child: CoraPressable(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CoraNetworkPhoto(
                url: card.photoUrl,
                background: c.photoPlaceholder,
                alignment: const Alignment(0, -0.4),
              ),
              // 저장한 카드에는 표지가 없다. 저장 탭이 이미 저장이라고 말한다.
              if (card.state != InterestState.held)
                Positioned(left: 8, top: 8, child: _Badge(state: card.state)),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        c.interestCardScrim.withAlpha(0),
                        c.interestCardScrim,
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 40, 10, 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        Text(
                          card.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CoraTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            color: c.onPhoto,
                          ),
                        ),
                        if (headline != null && headline.isNotEmpty)
                          Text(
                            headline,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: onPhotoSecondary,
                          ),
                        Text(
                          detailLine(card),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: onPhotoSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (onTogglePick != null)
                Positioned(
                  right: 0,
                  top: 0,
                  child: _PickCircle(picked: picked, onTap: onTogglePick!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 왼쪽 위 표지. `서로 관심`은 #5C7A00 바탕에 하트, `응답 대기`는 어두운 반투명 바탕이다.
class _Badge extends StatelessWidget {
  const _Badge({required this.state});

  final InterestState state;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final mutual = state == InterestState.mutual;
    final label = mutual
        ? InterestsTexts.badgeMutual
        : InterestsTexts.badgeWaiting;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: mutual ? c.interestChipMutual : c.interestChipWait,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            if (mutual) InterestIcon(HeartFillPainter(c.onPhoto), size: 12),
            Text(
              label,
              style: CoraTextStyles.caption.copyWith(
                fontSize: 11,
                color: c.onPhoto,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 비교 동그라미: 지름 26, 카드 모서리에서 8. 고른 카드는 체크가 든 `accent` 동그라미, 고르지 않은
/// 카드는 빈 동그라미다. 눌리는 칸은 44로 넓힌다.
class _PickCircle extends StatelessWidget {
  const _PickCircle({required this.picked, required this.onTap});

  final bool picked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      selected: picked,
      label: picked
          ? InterestsTexts.pickedLabel
          : InterestsTexts.notPickedLabel,
      onTap: onTap,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            // 동그라미(26)는 카드의 오른쪽·위에서 8 떨어진 자리에 둔다.
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 8, 10),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: picked ? c.accent : c.interestPickIdle,
                  border: picked
                      ? null
                      : Border.all(color: c.onPhoto, width: 1.5),
                ),
                child: SizedBox.square(
                  dimension: 26,
                  child: picked
                      ? Center(
                          child: InterestIcon(
                            CheckPainter(c.onAccent),
                            size: 14,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
