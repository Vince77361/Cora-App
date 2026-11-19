import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shadows.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/theme/cora_world_cup_tokens.dart';
import '../../../../core/ui/cora_network_photo.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../domain/world_cup_candidate.dart';
import '../world_cup_text.dart';

/// 월드컵의 사진 카드 한 장. 대결에서는 [onPick]을 주어 카드 전체가 고르는 버튼이고 오른쪽 아래에 `이거보다 좋아`가
/// 보인다(캔버스 M19G3Match). 결과의 큰 우승 카드는 [large]이고 누르지 않는다(M19G3Result).
///
/// 사진은 후보의 대표 게시물 1번이다. 한 줄이 없으면 활동 이름을 큰 글자로 쓰고 작은 이름 줄은 두지 않는다(캔버스 밖).
class WorldCupCard extends StatelessWidget {
  const WorldCupCard({
    super.key,
    required this.candidate,
    required this.chip,
    this.onPick,
    this.large = false,
  });

  final WorldCupCandidate candidate;

  /// 왼쪽 위 표지(`저장 2번째`, `이상형 1위`).
  final Widget chip;
  final VoidCallback? onPick;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final headline = candidate.headline?.trim() ?? '';
    final hasHeadline = headline.isNotEmpty;

    final card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(CoraRadius.xxl),
        boxShadow: CoraShadows.swipeCard,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(CoraRadius.xxl),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 사진 가운데 기준점은 캔버스 `object-position: 50% 25%`(결과는 50% 30%).
            CoraNetworkPhoto(
              url: candidate.photoUrl,
              alignment: Alignment(0, large ? -0.4 : -0.5),
              background: c.photoPlaceholder,
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: large
                  ? CoraWorldCupTokens.resultScrimHeight
                  : CoraWorldCupTokens.matchScrimHeight,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: CoraWorldCupTokens.scrim,
                    stops: CoraWorldCupTokens.scrimStops,
                  ),
                ),
              ),
            ),
            Positioned(left: 14, top: 14, child: chip),
            Positioned(
              left: 20,
              right: 20,
              bottom: large ? 20 : 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                spacing: large ? 8 : 6,
                children: [
                  if (hasHeadline)
                    Text(
                      candidate.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CoraTextStyles.label.copyWith(
                        fontSize: 14,
                        color: c.onPhotoSecondary,
                      ),
                    ),
                  Text(
                    hasHeadline ? headline : candidate.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: CoraTextStyles.display.copyWith(
                      fontSize: large ? 32 : 26,
                      letterSpacing: large ? -1.6 : -1.3,
                      height: 1.15,
                      color: c.onPhoto,
                    ),
                  ),
                  if (large)
                    _Meta(meta: candidate.meta, large: true)
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        spacing: 8,
                        children: [
                          Expanded(
                            child: _Meta(meta: candidate.meta, large: false),
                          ),
                          if (onPick != null) const _PickLabel(),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (onPick == null) return card;
    return Semantics(
      container: true,
      button: true,
      label: WorldCupText.pickLabel(candidate.name),
      onTap: onPick,
      child: ExcludeSemantics(
        child: CoraPressable(onTap: onPick, child: card),
      ),
    );
  }
}

/// 사진 위 형광색 줄(`리빙 릴스 · 팔로워 640`): 대결 15/900, 결과 18/900.
class _Meta extends StatelessWidget {
  const _Meta({required this.meta, required this.large});

  final String meta;
  final bool large;

  @override
  Widget build(BuildContext context) {
    if (meta.isEmpty) return const SizedBox.shrink();
    return Text(
      meta,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: CoraTextStyles.display.copyWith(
        fontSize: large ? 18 : 15,
        letterSpacing: 0,
        height: CoraTextStyles.label.height,
        color: context.colors.accent,
      ),
    );
  }
}

/// 카드 오른쪽 아래의 `이거보다 좋아`(높이 44, 안쪽 좌우 18, 14/700). 카드 전체가 버튼이라 모양만 낸다.
class _PickLabel extends StatelessWidget {
  const _PickLabel();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.accent,
        borderRadius: BorderRadius.circular(CoraRadius.pill),
      ),
      child: SizedBox(
        height: 44,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Center(
            widthFactor: 1,
            child: Text(
              WorldCupText.pick,
              maxLines: 1,
              style: CoraTextStyles.label.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: c.onAccent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 카드 왼쪽 위 표지: 안쪽 위아래 6·좌우 12, 알약, `photoChip` 바탕에 12/500. [leading]이 있으면 글자 앞에 놓는다.
class WorldCupCardChip extends StatelessWidget {
  const WorldCupCardChip({super.key, required this.label, this.leading});

  final String label;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.photoChip,
        borderRadius: BorderRadius.circular(CoraRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            ?leading,
            Text(
              label,
              maxLines: 1,
              style: CoraTextStyles.caption.copyWith(color: c.onPhotoChip),
            ),
          ],
        ),
      ),
    );
  }
}
