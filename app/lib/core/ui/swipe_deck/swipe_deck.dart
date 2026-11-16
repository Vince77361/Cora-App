import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import '../../theme/cora_motion.dart';
import '../../theme/cora_swipe_tokens.dart';
import 'swipe_deck_controller.dart';
import 'swipe_physics.dart';
import 'swipe_stamp.dart';

export 'swipe_deck_controller.dart';
export 'swipe_physics.dart' show SwipeOutcome;

/// 카드를 끌어서 넘기는 덱(캔버스 01 발견, 08 크리에이터의 발견, 9A 둘러보기).
///
/// 맨 위 카드만 움직인다. 오른쪽으로 밀면 관심, 왼쪽은 넘김, 위쪽은 보류다(기준은
/// [resolveSwipe]). 다음 카드는 뒤에서 96% 크기로 보이다가 앞 카드가 나가면 100%가 된다.
///
/// 한 번에 한 장만 넘어간다. 카드가 날아가는 동안과 [onSwiped]가 끝나기 전에는 끌기와
/// [SwipeDeckController.swipe]를 받지 않아서 결정이 두 번 저장되거나 카드가 겹치지 않는다.
/// [onSwiped]가 예외를 던지면 카드는 제자리로 돌아온다. 오류를 보여 주는 일은 [onSwiped]를
/// 만든 쪽이 한다(여기서는 삼킨다).
///
/// [accepts]가 어떤 방향을 받지 않는다고 하면(예: 읽기만 하는 둘러보기의 관심) 그 방향으로는 카드가
/// 날아가지 않는다. 놓으면 스프링으로 제자리에 돌아오고, 다 멈춘 뒤에 [onRejected]가 불린다.
///
/// 이 덱은 자기가 넘긴 카드를 기억해 [items]에서 숨긴다. 부모가 넘긴 카드를 목록에서 지워도,
/// 그대로 두고 새 목록 객체로 다시 그려도 카드가 되살아나지 않는다. 지웠던 카드를 다시
/// 목록에 넣으면(되돌리기) 그 카드가 다시 보인다.
class SwipeDeck<T> extends StatefulWidget {
  const SwipeDeck({
    super.key,
    required this.items,
    required this.cardBuilder,
    required this.onSwiped,
    required this.empty,
    this.onTap,
    this.accepts,
    this.onRejected,
    this.controller,
  });

  /// 위에서부터 보여 줄 카드. 같은 카드는 `==`로 알아본다.
  final List<T> items;
  final Widget Function(BuildContext context, T item) cardBuilder;

  /// 카드가 화면 밖으로 나간 뒤 불린다. 끝나기 전에는 다음 카드를 넘길 수 없다.
  final Future<void> Function(T item, SwipeOutcome outcome) onSwiped;

  /// 맨 위 카드를 끌지 않고 눌렀을 때.
  final VoidCallback? onTap;

  /// 이 방향으로 넘기는 것을 받는지. null이면 모두 받는다. false이면 카드가 날아가지 않고 제자리로
  /// 돌아온다(버튼으로 넘길 때는 카드가 움직이지 않는다).
  final bool Function(SwipeOutcome outcome)? accepts;

  /// [accepts]가 받지 않은 넘김에서 카드가 제자리에 멈춘 뒤.
  final VoidCallback? onRejected;

  /// 넘길 카드가 하나도 없을 때 보여 줄 것.
  final Widget empty;

  final SwipeDeckController? controller;

  @override
  State<SwipeDeck<T>> createState() => _SwipeDeckState<T>();
}

class _SwipeDeckState<T> extends State<SwipeDeck<T>>
    with SingleTickerProviderStateMixin {
  /// 맨 위 카드가 기준 자리에서 얼마나 벗어났는지. 카드와 도장, 뒤 카드 크기가 이 값을 따른다.
  final _offset = ValueNotifier<Offset>(Offset.zero);

  /// 놓은 뒤의 움직임(날아가기·스프링)을 [_from]에서 [_to]로 잇는 진행값. 스프링이 살짝
  /// 넘치므로 범위를 두지 않는다.
  late final AnimationController _motion;
  Offset _from = Offset.zero;
  Offset _to = Offset.zero;

  /// 이 덱이 넘긴 카드.
  final _swiped = <T>[];

  /// 날아가는 중이거나 `onSwiped`를 기다리는 카드. 부모가 그 사이 목록에서 지워도 그 카드를 계속
  /// 맨 위로 그려서 다음 카드가 날아간 자리에서 나타나지 않게 한다.
  T? _leaving;
  bool _hasLeaving = false;

  bool _dragging = false;
  bool _busy = false;
  Size _size = Size.zero;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController.unbounded(vsync: this)
      ..addListener(_onMotionTick);
    widget.controller?.attach(_swipeFromController);
  }

  @override
  void didUpdateWidget(SwipeDeck<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.detach(_swipeFromController);
      widget.controller?.attach(_swipeFromController);
      widget.controller?.setBusy(_busy);
    }
    // 부모가 지운 카드는 잊는다. 그래야 되돌리기로 다시 넣은 카드가 보인다.
    _swiped.removeWhere((item) => !widget.items.contains(item));
  }

  @override
  void dispose() {
    widget.controller?.detach(_swipeFromController);
    _motion.dispose();
    _offset.dispose();
    super.dispose();
  }

  void _setBusy(bool value) {
    _busy = value;
    widget.controller?.setBusy(value);
  }

  /// 아직 넘기지 않은 카드(날아가는 카드는 뺀다).
  List<T> get _remaining => [
    for (final item in widget.items)
      if (!_swiped.contains(item) && !(_hasLeaving && item == _leaving)) item,
  ];

  // ---- 움직임 ----

  void _onMotionTick() {
    _offset.value = Offset.lerp(_from, _to, _motion.value)!;
  }

  Future<void> _animateTo(Offset target, {required bool fly}) async {
    _motion.stop();
    _from = _offset.value;
    _to = target;
    if (CoraMotion.reduceMotion(context)) {
      _offset.value = target;
      return;
    }
    _motion.value = 0;
    if (fly) {
      await _motion.animateTo(
        1,
        duration: CoraMotion.swipeFlyDuration,
        curve: CoraMotion.swipeFlyCurve,
      );
    } else {
      await _motion.animateWith(
        SpringSimulation(CoraMotion.swipeSpring, 0, 1, 0),
      );
    }
  }

  Future<void> _springBack() => _animateTo(Offset.zero, fly: false);

  /// 화면 밖의 도착점. 가로로 넘길 때는 놓은 높이를 그대로 두고, 보류는 똑바로 위로 간다.
  Offset _flyTarget(SwipeOutcome outcome) {
    final current = _offset.value;
    return switch (outcome) {
      SwipeOutcome.like => Offset(_size.width * 1.5, current.dy),
      SwipeOutcome.pass => Offset(-_size.width * 1.5, current.dy),
      SwipeOutcome.hold => Offset(0, -_size.height * 1.2),
    };
  }

  Future<void> _fling(SwipeOutcome outcome) async {
    if (_busy) return;
    final remaining = _remaining;
    if (remaining.isEmpty) return;
    final item = remaining.first;
    if (widget.accepts?.call(outcome) == false) {
      // 받지 않는 방향이다. 카드는 화면 밖으로 나가지 않고 스프링으로 제자리에 돌아온다.
      _setBusy(true);
      if (_offset.value != Offset.zero) await _springBack();
      if (!mounted) return;
      _setBusy(false);
      widget.onRejected?.call();
      return;
    }
    _setBusy(true);
    setState(() {
      _leaving = item;
      _hasLeaving = true;
    });

    await _animateTo(_flyTarget(outcome), fly: true);
    if (!mounted) return;

    try {
      await widget.onSwiped(item, outcome);
    } catch (error, stack) {
      // 저장하지 못한 결정이다. 카드를 돌려놓아 다시 고르게 한다. 오류 안내는 onSwiped 쪽 몫이지만,
      // 예상하지 못한 오류가 조용히 묻히지 않게 Flutter 오류로도 알린다.
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'swipe deck',
          context: ErrorDescription('while saving a swiped card'),
        ),
      );
      if (!mounted) return;
      await _springBack();
      if (!mounted) return;
      setState(() {
        _leaving = null;
        _hasLeaving = false;
      });
      _setBusy(false);
      return;
    }
    if (!mounted) return;

    // 다음 카드는 이미 100%로 뒤에 있다. 기준 자리를 되돌리고 넘긴 카드를 치운다.
    _offset.value = Offset.zero;
    setState(() {
      _swiped.add(item);
      _leaving = null;
      _hasLeaving = false;
    });
    _setBusy(false);
  }

  Future<void> _swipeFromController(SwipeOutcome outcome) {
    if (_dragging) return Future<void>.value();
    return _fling(outcome);
  }

  // ---- 끌기 ----

  void _onPanStart(DragStartDetails details) {
    if (_busy) return;
    _dragging = true;
    // 스프링으로 돌아오는 도중에 다시 잡으면 그 자리에서 이어서 끈다.
    _motion.stop();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_dragging) return;
    _offset.value += details.delta;
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_dragging) return;
    _dragging = false;
    final outcome = resolveSwipe(_offset.value);
    if (outcome == null) {
      _springBack();
    } else {
      _fling(outcome);
    }
  }

  void _onPanCancel() {
    if (!_dragging) return;
    _dragging = false;
    _springBack();
  }

  void _onTap() {
    if (_busy) return;
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = constraints.biggest;
        final remaining = _remaining;
        final T? top = _hasLeaving
            ? _leaving
            : (remaining.isEmpty ? null : remaining.first);
        final behindList = _hasLeaving ? remaining : remaining.skip(1).toList();
        final T? behind = behindList.isEmpty ? null : behindList.first;

        return Stack(
          fit: StackFit.expand,
          children: [
            if (top == null && !_hasLeaving) widget.empty,
            // 키가 `==`로 같은 카드를 알아봐서 뒤 카드가 맨 위로 올라올 때 상태가 이어진다.
            if (behind != null)
              _DeckLayer(
                key: ValueKey<T>(behind),
                offset: _offset,
                isTop: false,
                width: _size.width,
                child: widget.cardBuilder(context, behind),
              ),
            if (_hasLeaving || top != null)
              _DeckLayer(
                key: ValueKey<T>(top as T),
                offset: _offset,
                isTop: true,
                width: _size.width,
                onTap: widget.onTap == null ? null : _onTap,
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                onPanCancel: _onPanCancel,
                child: widget.cardBuilder(context, top),
              ),
          ],
        );
      },
    );
  }
}

/// 덱의 한 장. 맨 위 카드는 [offset]만큼 움직이고 기울며 도장을 띄우고, 뒤 카드는 [offset]이
/// 커질수록 96%에서 100%로 커진다. 카드 내용은 한 번만 그리고 움직임은 그 위에 얹는다.
class _DeckLayer extends StatelessWidget {
  const _DeckLayer({
    super.key,
    required this.offset,
    required this.isTop,
    required this.width,
    required this.child,
    this.onTap,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onPanCancel,
  });

  final ValueListenable<Offset> offset;
  final bool isTop;
  final double width;
  final Widget child;
  final VoidCallback? onTap;
  final GestureDragStartCallback? onPanStart;
  final GestureDragUpdateCallback? onPanUpdate;
  final GestureDragEndCallback? onPanEnd;
  final GestureDragCancelCallback? onPanCancel;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Offset>(
      valueListenable: offset,
      child: child,
      builder: (context, value, card) {
        // 뒤 카드가 맨 위로 올라와도 카드 내용이 같은 자리에 남아 상태(불러온 사진 등)가 이어지도록,
        // 맨 위와 뒤 카드가 같은 위젯 구조(Transform > GestureDetector > Stack > 카드)를 쓴다. 다른 것은
        // 값뿐이다: 변환(맨 위는 이동·기울기, 뒤는 크기), 접근성·터치 무시 여부, 도장 불투명도.
        final Matrix4 transform;
        if (isTop) {
          final angle = tiltFor(value.dx, width) * math.pi / 180;
          transform = Matrix4.translationValues(value.dx, value.dy, 0)
            ..rotateZ(angle);
        } else {
          final scale =
              CoraMotion.swipeBehindScale +
              (1 - CoraMotion.swipeBehindScale) * swipeProgress(value);
          transform = Matrix4.diagonal3Values(scale, scale, 1);
        }
        return ExcludeSemantics(
          excluding: !isTop,
          child: IgnorePointer(
            ignoring: !isTop,
            child: Transform(
              alignment: Alignment.center,
              transform: transform,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                onPanStart: onPanStart,
                onPanUpdate: onPanUpdate,
                onPanEnd: onPanEnd,
                onPanCancel: onPanCancel,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    card!,
                    for (final outcome in SwipeOutcome.values)
                      _positionedStamp(
                        outcome,
                        isTop ? stampOpacity(value, outcome) : 0,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _positionedStamp(SwipeOutcome outcome, double opacity) {
    final stamp = IgnorePointer(
      child: Opacity(opacity: opacity, child: SwipeStamp(outcome)),
    );
    return switch (outcome) {
      SwipeOutcome.like => Positioned(
        left: CoraSwipeTokens.stampSideInset,
        top: CoraSwipeTokens.stampTop,
        child: stamp,
      ),
      SwipeOutcome.pass => Positioned(
        right: CoraSwipeTokens.stampSideInset,
        top: CoraSwipeTokens.stampTop,
        child: stamp,
      ),
      SwipeOutcome.hold => Positioned(
        top: CoraSwipeTokens.holdStampTop,
        left: 0,
        right: 0,
        child: Center(child: stamp),
      ),
    };
  }
}
