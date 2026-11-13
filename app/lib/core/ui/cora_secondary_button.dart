import 'package:flutter/material.dart';

import '../theme/cora_colors.dart';
import '../theme/cora_shapes.dart';
import '../theme/cora_text_styles.dart';
import 'cora_pressable.dart';

/// 보조 버튼의 색 모양.
enum CoraSecondaryTone {
  /// `surface` 바탕(NStorePage `정보 고치기`: 라이트 #F8F9FA, 다크 #1C1E22).
  surface,

  /// `surfaceMuted` 바탕(NStoreAI `다시 만들기`: 라이트·다크 모두 #F2F3F5에 #17181C 글자).
  muted,

  /// `subtleAction` 바탕(NReviewSend `고치기`: 라이트 #F2F3F5에 #17181C, 다크 #2A2D33에 #F2F3F5).
  subtle,
}

/// 기본 버튼 옆에 두는 알약 보조 버튼(캔버스 NStorePage `정보 고치기`). 높이 58, 글자 15px 500.
/// 부모 너비를 가득 채운다(캔버스는 `flex: 1`). [onPressed]가 null이면 누르지 못하고 글자가
/// 보조색이 된다.
class CoraSecondaryButton extends StatelessWidget {
  const CoraSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.tone = CoraSecondaryTone.surface,
  });

  final String label;
  final VoidCallback? onPressed;
  final CoraSecondaryTone tone;

  static const double height = 58;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onPressed != null;
    final background = switch (tone) {
      CoraSecondaryTone.surface => c.surface,
      CoraSecondaryTone.muted => c.surfaceMuted,
      CoraSecondaryTone.subtle => c.subtleAction,
    };
    final foreground = !enabled
        ? c.textSecondary
        : switch (tone) {
            CoraSecondaryTone.surface => c.text,
            CoraSecondaryTone.muted => c.onSurfaceMuted,
            CoraSecondaryTone.subtle => c.onSubtleAction,
          };
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      onTap: onPressed,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onPressed,
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(CoraRadius.pill),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Center(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CoraTextStyles.buttonMedium.copyWith(
                      color: foreground,
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
