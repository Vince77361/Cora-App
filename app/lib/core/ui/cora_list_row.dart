import 'package:flutter/material.dart';

import '../theme/cora_colors.dart';
import '../theme/cora_shapes.dart';
import '../theme/cora_text_styles.dart';
import 'cora_network_photo.dart';
import 'cora_pressable.dart';

/// 목록의 한 줄(캔버스 NStoreHome `<li>`): 왼쪽 지름 46 사진, 가운데 이름과 보조 설명, 오른쪽
/// 알약 버튼. 안쪽 여백은 10/12, 사진·글자·버튼 사이는 12다. 줄 밖 여백(목록의 8)은 화면이 정한다.
///
/// 사진 주소가 없으면 제목의 첫 글자를 `surface` 원 안에 보여 준다. [actionHighlighted]이면
/// 버튼이 강조색(라이트·다크 모두 라임)이고 아니면 `surface`다.
class CoraListRow extends StatelessWidget {
  const CoraListRow({
    super.key,
    this.photoUrl,
    this.photoAlignment = Alignment.center,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.actionHighlighted = false,
    this.onAction,
    this.onTap,
  });

  final String? photoUrl;

  /// 캔버스 `object-position`(예: 50% 25%는 `Alignment(0, -0.5)`). 얼굴이 위쪽에 있는 사진용.
  final Alignment photoAlignment;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final bool actionHighlighted;
  final VoidCallback? onAction;

  /// 줄 전체를 눌렀을 때. 버튼은 따로 [onAction]이다.
  final VoidCallback? onTap;

  static const double photoSize = 46;
  static const double actionHeight = 38;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final sub = subtitle;
    final label = actionLabel;
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          _Avatar(
            photoUrl: photoUrl,
            photoAlignment: photoAlignment,
            title: title,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CoraTextStyles.buttonMedium.copyWith(color: c.text),
                ),
                if (sub != null)
                  Text(
                    sub,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: CoraTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w400,
                      color: c.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (label != null) ...[
            const SizedBox(width: 12),
            _ActionButton(
              label: label,
              highlighted: actionHighlighted,
              onPressed: onAction,
            ),
          ],
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
  const _Avatar({
    required this.photoUrl,
    required this.photoAlignment,
    required this.title,
  });

  final String? photoUrl;
  final Alignment photoAlignment;
  final String title;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: CoraListRow.photoSize,
        child: ClipOval(
          child: hasPhoto
              ? CoraNetworkPhoto(url: photoUrl, alignment: photoAlignment)
              : ColoredBox(
                  color: c.surface,
                  child: Center(
                    child: Text(
                      title.isEmpty
                          ? ''
                          : String.fromCharCodes(title.runes.take(1)),
                      style: CoraTextStyles.bodyLarge.copyWith(color: c.text),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.highlighted,
    required this.onPressed,
  });

  final String label;
  final bool highlighted;
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
              color: highlighted ? c.highlightAction : c.surface,
              borderRadius: BorderRadius.circular(CoraRadius.pill),
            ),
            child: SizedBox(
              height: CoraListRow.actionHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: CoraTextStyles.label.copyWith(
                      color: highlighted ? c.onHighlightAction : c.text,
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
