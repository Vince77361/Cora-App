import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_pressable.dart';
import 'featured_post_icon.dart';

/// 대표 게시물 화면 아래의 알약 버튼(캔버스 `.btn`). [hot]은 라임 바탕(높이 58, 16/700), 아니면 보조 버튼(높이 [height],
/// 15/500, 라이트 #F2F3F5·다크 #2A2D33). 아이콘이 있으면 글자 앞에 20으로 놓인다.
class FeaturedPostButton extends StatelessWidget {
  const FeaturedPostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.glyph,
    this.hot = false,
    this.height,
    this.iconStroke = 2,
  });

  final String label;
  final VoidCallback? onPressed;
  final FeaturedPostGlyph? glyph;
  final bool hot;
  final double? height;
  final double iconStroke;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final foreground = hot ? c.onAccent : c.onSubtleAction;
    final style = hot ? CoraTextStyles.button : CoraTextStyles.buttonMedium;
    return Semantics(
      container: true,
      button: true,
      enabled: onPressed != null,
      label: label,
      onTap: onPressed,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onPressed,
          child: SizedBox(
            height: height ?? (hot ? 58 : 52),
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: hot ? c.accent : c.subtleAction,
                borderRadius: BorderRadius.circular(CoraRadius.pill),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  // 좁은 자리(버튼이 둘 나란히)와 글자 키우기에서 줄바꿈 대신 줄여서 한 줄에 맞춘다.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 8,
                      children: [
                        if (glyph != null)
                          FeaturedPostIcon(
                            glyph!,
                            size: 20,
                            color: foreground,
                            strokeWidth: iconStroke,
                          ),
                        Text(
                          label,
                          maxLines: 1,
                          style: style.copyWith(color: foreground),
                        ),
                      ],
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
