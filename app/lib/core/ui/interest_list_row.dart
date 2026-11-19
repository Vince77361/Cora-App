import 'package:flutter/material.dart';

import '../theme/cora_colors.dart';
import '../theme/cora_store_interests_tokens.dart';
import '../theme/cora_text_styles.dart';
import 'cora_network_photo.dart';
import 'cora_pressable.dart';
import 'interest_icons.dart';

/// 이름 옆 표지.
enum InterestRowChip { none, mutual, waiting }

/// 저장함의 줄 하나(캔버스 M19G2TabsB `.row`). 사장님 저장함과 브랜드 03의 보낸 제안 탭이 함께 쓴다: 안쪽 위아래 9·좌우 12, 사진 46 원 + 이름(15/500)과 표지 + 설명(12 보조색,
/// 줄 높이 1.4) + 오른쪽 단추(높이 38, 13/500). 단추가 형광이면 `highlightAction`, 아니면 `surface`다. 줄 전체를 누르면
/// [onTap], 단추는 따로 [onAction]이다. 사진이 없으면 이름 첫 글자를 사진 바탕 위에 보인다.
class InterestListRow extends StatelessWidget {
  const InterestListRow({
    super.key,
    required this.name,
    required this.meta,
    required this.actionLabel,
    this.photoUrl,
    this.chip = InterestRowChip.none,
    this.actionHot = false,
    this.onAction,
    this.onTap,
  });

  final String name;
  final String? photoUrl;

  /// 이름 아래 설명. 비어 있으면 줄을 두지 않는다.
  final String meta;
  final InterestRowChip chip;
  final String actionLabel;
  final bool actionHot;
  final VoidCallback? onAction;
  final VoidCallback? onTap;

  /// 이름 옆 표지 글자.
  static const chipMutual = '서로 관심';
  static const chipWaiting = '응답 대기';

  static const double photoSize = 46;
  static const double actionHeight = 38;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(
        spacing: 12,
        children: [
          _Avatar(name: name, photoUrl: photoUrl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  spacing: 6,
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CoraTextStyles.buttonMedium.copyWith(
                          color: c.text,
                        ),
                      ),
                    ),
                    if (chip != InterestRowChip.none) _Chip(kind: chip),
                  ],
                ),
                if (meta.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      meta,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: CoraTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                        color: c.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _Action(label: actionLabel, hot: actionHot, onPressed: onAction),
        ],
      ),
    );
    if (onTap == null) return row;
    return Semantics(
      container: true,
      button: true,
      onTap: onTap,
      child: CoraPressable(onTap: onTap, child: row),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.photoUrl});

  final String name;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: InterestListRow.photoSize,
        child: ClipOval(
          child: hasPhoto
              ? CoraNetworkPhoto(
                  url: photoUrl,
                  alignment: const Alignment(0, -0.5),
                  background: c.photoPlaceholder,
                )
              : ColoredBox(
                  color: c.photoPlaceholder,
                  child: Center(
                    child: Text(
                      name.isEmpty
                          ? ''
                          : String.fromCharCodes(name.runes.take(1)),
                      style: CoraTextStyles.bodyLarge.copyWith(
                        color: CoraStoreInterestsTokens.avatarInitial,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

/// 이름 옆 표지: 11/500, 안쪽 3·8. `서로 관심`은 하트가 앞에 붙은 `interestChipMutual` 바탕에 흰 글자, `응답 대기`는
/// `notifyTabSelected` 바탕이다.
class _Chip extends StatelessWidget {
  const _Chip({required this.kind});

  final InterestRowChip kind;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final mutual = kind == InterestRowChip.mutual;
    final foreground = mutual ? c.onPhoto : c.text;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: mutual ? c.interestChipMutual : c.notifyTabSelected,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 3,
          children: [
            if (mutual) InterestIcon(HeartFillPainter(foreground), size: 11),
            Text(
              mutual ? InterestListRow.chipMutual : InterestListRow.chipWaiting,
              maxLines: 1,
              style: CoraTextStyles.caption.copyWith(
                fontSize: 11,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.label,
    required this.hot,
    required this.onPressed,
  });

  final String label;
  final bool hot;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      enabled: onPressed != null,
      onTap: onPressed,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onPressed,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: hot ? c.highlightAction : c.surface,
              borderRadius: BorderRadius.circular(999),
            ),
            child: SizedBox(
              height: InterestListRow.actionHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: CoraTextStyles.label.copyWith(
                      color: hot ? c.onHighlightAction : c.text,
                    ),
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
