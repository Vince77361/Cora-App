import 'package:flutter/widgets.dart';

import '../theme/cora_motion.dart';

/// 누를 수 있는 Cora 표면의 공통 반응. 잉크 번짐 대신 누르는 동안 살짝 줄어든다.
///
/// 의미 정보(버튼, 선택됨, 누르기 동작)는 감싸는 위젯이 [Semantics]로 직접 단다.
/// 여기서 한 번 더 달면 스크린 리더가 같은 동작을 두 번 읽는다.
class CoraPressable extends StatefulWidget {
  const CoraPressable({super.key, required this.onTap, required this.child});

  /// null이면 누를 수 없고 줄어들지도 않는다.
  final VoidCallback? onTap;
  final Widget child;

  @override
  State<CoraPressable> createState() => _CoraPressableState();
}

class _CoraPressableState extends State<CoraPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  void didUpdateWidget(CoraPressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 누르는 도중에 꺼지면 줄어든 채로 남지 않게 한다.
    if (widget.onTap == null) _pressed = false;
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: widget.onTap,
      onTapDown: enabled ? (_) => _setPressed(true) : null,
      onTapUp: enabled ? (_) => _setPressed(false) : null,
      onTapCancel: enabled ? () => _setPressed(false) : null,
      child: AnimatedScale(
        scale: _pressed ? CoraMotion.pressedScale : 1,
        duration: CoraMotion.resolve(context, CoraMotion.pressDuration),
        curve: CoraMotion.standardCurve,
        child: widget.child,
      ),
    );
  }
}
