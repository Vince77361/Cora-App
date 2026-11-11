import 'package:flutter/material.dart';

import '../theme/cora_colors.dart';
import '../theme/cora_motion.dart';
import '../theme/cora_shapes.dart';
import '../theme/cora_text_styles.dart';
import 'cora_pressable.dart';

/// 화면 아래의 알약 모양 기본 버튼(캔버스 A1 `가게 링크로 시작하기`, Principles `다음`).
///
/// 부모 너비를 가득 채운다. 캔버스의 기본 버튼은 모두 좌우 16 여백 안에서 꽉 찬다.
/// [onPressed]가 null이면 꺼진 모양(`line` 바탕, `textSecondary` 글자)이 되고 누르지 못한다.
class CoraPrimaryButton extends StatelessWidget {
  const CoraPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  static const double height = 58;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onPressed != null;
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      onTap: onPressed,
      child: CoraPressable(
        onTap: onPressed,
        // 켜짐과 꺼짐 사이를 색으로 이어서 바꾼다. 테마가 바뀌는 중에도 토큰 값을 매번
        // 새로 읽으므로 라이트·다크 전환과 겹쳐도 맞는 색이 나온다.
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: enabled ? 1 : 0),
          duration: CoraMotion.resolve(context, CoraMotion.stateDuration),
          curve: CoraMotion.standardCurve,
          builder: (context, t, _) {
            final background = Color.lerp(c.line, c.primaryAction, t)!;
            final foreground = Color.lerp(
              c.textSecondary,
              c.onPrimaryAction,
              t,
            )!;
            return SizedBox(
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
                      textAlign: TextAlign.center,
                      style: CoraTextStyles.button.copyWith(color: foreground),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
