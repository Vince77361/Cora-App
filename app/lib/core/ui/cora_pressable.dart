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

class _CoraPressableState extends State<CoraPressable>
    with SingleTickerProviderStateMixin {
  // 0 = 원래 크기, 1 = 다 눌린 크기.
  late final AnimationController _press = AnimationController(vsync: this)
    ..addStatusListener(_handleStatus);
  late final Animation<double> _scale = _press.drive(
    Tween<double>(
      begin: 1,
      end: CoraMotion.pressedScale,
    ).chain(CurveTween(curve: CoraMotion.standardCurve)),
  );

  /// 손가락이 아직 눌려 있는지.
  bool _held = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 동작 줄이기를 켜면 길이가 0이 되어 눌림이 남지 않는다.
    _press.duration = CoraMotion.resolve(context, CoraMotion.pressDuration);
  }

  @override
  void didUpdateWidget(CoraPressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 누르는 도중에 꺼지면 줄어든 채로 남지 않게 한다.
    if (widget.onTap == null && (_held || !_press.isDismissed)) {
      _held = false;
      _press.value = 0;
    }
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _handleDown() {
    _held = true;
    _press.forward();
  }

  // 스크롤 안에서 짧게 탭하면 GestureDetector가 onTapDown과 onTapUp을 한 이벤트에서
  // 연달아 부른다. 상태 값만 바꾸면 그 사이에 프레임이 없어 눌림이 한 번도 그려지지
  // 않는다. 그래서 눌림은 끝까지 줄어든 뒤에야 되돌아가게 한다(동작은 기다리지 않는다).
  void _handleRelease() {
    _held = false;
    if (_press.status != AnimationStatus.forward) _press.reverse();
  }

  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_held) _press.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: widget.onTap,
      onTapDown: enabled ? (_) => _handleDown() : null,
      onTapUp: enabled ? (_) => _handleRelease() : null,
      onTapCancel: enabled ? _handleRelease : null,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
