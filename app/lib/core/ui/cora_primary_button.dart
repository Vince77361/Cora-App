import 'package:flutter/material.dart';

import '../theme/cora_colors.dart';
import '../theme/cora_motion.dart';
import '../theme/cora_shapes.dart';
import '../theme/cora_text_styles.dart';
import 'cora_pressable.dart';

/// 기본 버튼의 색 모양.
enum CoraPrimaryButtonLook {
  /// 테마의 `primaryAction`(라이트 라임, 다크 밝은 회색). 꺼지면 `line` 바탕.
  standard,

  /// 라이트·다크 모두 라임(`accent`/`onAccent`). 꺼지면 `surface` 바탕에 보통 굵기(500) 글자.
  /// 로그인(E1)과 휴대폰 인증(E2)이 이 모양이다(NLogin, NVerify).
  accent,
}

/// 화면 아래의 알약 모양 기본 버튼(캔버스 A1 `가게 링크로 시작하기`, Principles `다음`).
///
/// 부모 너비를 가득 채운다. 캔버스의 기본 버튼은 모두 좌우 16 여백 안에서 꽉 찬다.
/// [onPressed]가 null이면 꺼진 모양(`line` 바탕, `textSecondary` 글자)이 되고 누르지 못한다.
class CoraPrimaryButton extends StatelessWidget {
  const CoraPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.look = CoraPrimaryButtonLook.standard,
  });

  final String label;
  final VoidCallback? onPressed;
  final CoraPrimaryButtonLook look;

  static const double height = 58;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onPressed != null;
    final accent = look == CoraPrimaryButtonLook.accent;
    final onColor = accent ? c.accent : c.primaryAction;
    final onForeground = accent ? c.onAccent : c.onPrimaryAction;
    final offColor = accent ? c.surface : c.line;
    final textStyle = accent && !enabled
        ? CoraTextStyles.bodyLarge
        : CoraTextStyles.button;
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
            final background = Color.lerp(offColor, onColor, t)!;
            final foreground = Color.lerp(c.textSecondary, onForeground, t)!;
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
                      style: textStyle.copyWith(color: foreground),
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
