import 'package:flutter/material.dart';

import '../theme/cora_shapes.dart';
import 'cora_pressable.dart';

/// 색과 크기를 부르는 쪽이 정하는 알약 버튼. 캔버스 D2·A6의 버튼들(`지원하기`, `취소`, `거절`,
/// `수락하기`)이 높이·글자·색만 다르고 모양은 같아서 하나로 둔다. 색은 호출하는 쪽이 토큰에서 가져온다.
class CoraPillButton extends StatelessWidget {
  const CoraPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.background,
    required this.foreground,
    required this.textStyle,
    this.height = 56,
    this.horizontalPadding,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color background;
  final Color foreground;
  final TextStyle textStyle;
  final double height;

  /// 주면 내용 너비에 이 좌우 여백을 더한 크기가 된다(작은 버튼). 비우면 부모 너비를 채운다.
  final double? horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final pad = horizontalPadding;
    return Semantics(
      container: true,
      button: true,
      enabled: onPressed != null,
      label: label,
      onTap: onPressed,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onPressed,
          child: Container(
            height: height,
            padding: pad == null ? null : EdgeInsets.symmetric(horizontal: pad),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(CoraRadius.pill),
            ),
            alignment: Alignment.center,
            // 글자를 키운 폰에서 버튼 둘이 나란히 있어도 한 줄에 맞게 줄인다. 평소 크기에서는 그대로다.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: textStyle.copyWith(color: foreground),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
