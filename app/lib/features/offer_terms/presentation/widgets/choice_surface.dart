import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_motion.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/ui/cora_pressable.dart';

/// 형식 카드와 보상 카드가 함께 쓰는 선택 면(캔버스 NOffer `opt`).
///
/// 고르지 않으면 `surface` 바탕, 고르면 `notifyTabSelected` 바탕(라이트 #E3E5E9, 다크 #33363D)이고
/// 글자는 둘 다 `text`다(캔버스 NOffer·DarkNOffer의 `opt`). 라이트와 다크의 색 차이는 토큰이 가지고 있다. 그림자는 없다(A1 역할 카드와 다르다).
/// 꺼진 카드는 흐려지고 누를 수 없다.
class OfferChoiceSurface extends StatelessWidget {
  const OfferChoiceSurface({
    super.key,
    required this.selected,
    required this.onTap,
    required this.minHeight,
    required this.padding,
    required this.builder,
    this.semanticLabel,
  });

  final bool selected;

  /// null이면 꺼진 카드다.
  final VoidCallback? onTap;
  final double minHeight;
  final EdgeInsets padding;

  /// 안쪽 내용. 글자색과 선택 진행도(0 → 1)를 받는다.
  final Widget Function(BuildContext context, Color foreground, double t)
  builder;

  /// 읽어 줄 이름. 주지 않으면 안쪽 글자를 합쳐 읽는다.
  final String? semanticLabel;

  /// 꺼진 카드의 투명도. 캔버스에 없는 상태라 `surface` 위에서 구별될 만큼만 낮췄다.
  static const double disabledOpacity = 0.4;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onTap != null;
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      selected: selected,
      label: semanticLabel,
      onTap: onTap,
      child: CoraPressable(
        onTap: onTap,
        child: Opacity(
          opacity: enabled ? 1 : disabledOpacity,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: selected ? 1 : 0),
            duration: CoraMotion.resolve(context, CoraMotion.stateDuration),
            curve: CoraMotion.standardCurve,
            builder: (context, t, _) {
              final foreground = c.text;
              return ConstrainedBox(
                constraints: BoxConstraints(minHeight: minHeight),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color.lerp(c.surface, c.notifyTabSelected, t),
                    borderRadius: BorderRadius.circular(CoraRadius.xl),
                  ),
                  child: Padding(
                    padding: padding,
                    child: builder(context, foreground, t),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
