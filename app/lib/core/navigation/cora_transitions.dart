import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/cora_colors.dart';
import '../theme/cora_motion.dart';
import '../theme/cora_shadows.dart';
import '../theme/cora_shapes.dart';

export '../theme/cora_motion.dart';
export 'cora_hero_tag.dart';

/// 앱의 화면 전환 규칙. go_router의 `pageBuilder`에서 쓴다.
///
/// ```dart
/// GoRoute(
///   path: '/creator/:id',
///   pageBuilder: (context, state) =>
///       CoraTransitions.push(CreatorPage(...), key: state.pageKey),
/// )
/// ```
///
/// `key`에는 `state.pageKey`를 넘긴다. 없으면 같은 자리의 페이지가 바뀔 때 Navigator가
/// 새 화면으로 보지 않아 전환 없이 내용만 바뀐다.
///
/// 들어오는 화면이 뒤 화면의 움직임도 정한다(`delegatedTransition`). 그래서 시트를 열면
/// 뒤 화면이 어떤 전환으로 들어왔든 96%로 줄어들고, push면 왼쪽으로 밀리며 어두워진다.
abstract final class CoraTransitions {
  /// 시트 위 끝과 상태 표시줄 사이 간격. 줄어든 뒤 화면의 윗부분이 이 틈으로 보인다.
  static const double sheetTopGap = 10;

  /// 다음 화면으로 들어가기. 오른쪽에서 24% 밀려 들어오며 나타나고, 밑의 화면은 왼쪽으로
  /// 8% 밀리며 어두워진다. iOS에서는 왼쪽 가장자리를 밀어 뒤로 갈 수 있다.
  static CustomTransitionPage<T> push<T>(
    Widget child, {
    LocalKey? key,
    String? name,
    Object? arguments,
    String? restorationId,
  }) {
    return CoraTransitionPage<T>(
      key: key,
      name: name,
      arguments: arguments,
      restorationId: restorationId,
      transitionDuration: CoraMotion.pushDuration,
      reverseTransitionDuration: CoraMotion.pushDuration,
      transitionsBuilder: _pushTransitions,
      delegatedTransition: _pushUnderlay,
      backSwipe: true,
      child: child,
    );
  }

  /// 아래에서 올라오는 화면. 위 모서리가 둥근 카드이고, 뒤 화면은 96%로 줄어들며 어두워진다.
  /// 시트 위의 어두운 틈을 누르면 닫힌다.
  static CustomTransitionPage<T> sheet<T>(
    Widget child, {
    LocalKey? key,
    String? name,
    Object? arguments,
    String? restorationId,
  }) {
    return CoraTransitionPage<T>(
      key: key,
      name: name,
      arguments: arguments,
      restorationId: restorationId,
      transitionDuration: CoraMotion.sheetDuration,
      reverseTransitionDuration: CoraMotion.sheetDuration,
      transitionsBuilder: _sheetTransitions,
      delegatedTransition: _sheetUnderlay,
      // 다 올라온 뒤에도 줄어든 뒤 화면이 위 틈으로 보여야 한다.
      opaque: false,
      barrierDismissible: true,
      barrierLabel: '닫기',
      child: _SheetFrame(child: child),
    );
  }

  /// 제자리에서 나타나기. 탭 전환과 로그인 전후에 쓴다. 밑의 화면은 움직이지 않는다.
  static CustomTransitionPage<T> fade<T>(
    Widget child, {
    LocalKey? key,
    String? name,
    Object? arguments,
    String? restorationId,
  }) {
    return CoraTransitionPage<T>(
      key: key,
      name: name,
      arguments: arguments,
      restorationId: restorationId,
      transitionDuration: CoraMotion.fadeDuration,
      reverseTransitionDuration: CoraMotion.fadeDuration,
      transitionsBuilder: _fadeTransitions,
      delegatedTransition: _stayStill,
      child: child,
    );
  }

  // 같은 종류의 화면이 위에 올라오면 Flutter는 위 화면의 delegatedTransition 대신
  // 이 화면 자신의 전환에 secondaryAnimation을 준다. 그래서 각 전환은 자기 종류가
  // 위에 올라왔을 때의 뒤 화면 움직임을 직접 품고, delegatedTransition도 같은 움직임이다.

  static Widget _pushTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => _PushUnderlay(
    animation: secondaryAnimation,
    child: _PushEnter(animation: animation, child: child),
  );

  static Widget? _pushUnderlay(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    bool allowSnapshotting,
    Widget? child,
  ) => child == null
      ? null
      : _PushUnderlay(animation: secondaryAnimation, child: child);

  static Widget _sheetTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => _SheetUnderlay(
    animation: secondaryAnimation,
    child: _SheetEnter(animation: animation, child: child),
  );

  static Widget? _sheetUnderlay(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    bool allowSnapshotting,
    Widget? child,
  ) => child == null
      ? null
      : _SheetUnderlay(animation: secondaryAnimation, child: child);

  static Widget _fadeTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => _FadeEnter(animation: animation, child: child);

  /// fade 화면이 올라올 때 밑의 화면은 제자리에 있는다. null이 아니라 child를 돌려줘야
  /// 밑의 화면(예: push)이 자기 secondaryAnimation으로 밀려나지 않는다.
  static Widget? _stayStill(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    bool allowSnapshotting,
    Widget? child,
  ) => child;
}

/// go_router의 [CustomTransitionPage]에 두 가지를 더한 페이지.
///
/// - [delegatedTransition]: 들어오는 화면이 나가는 화면의 움직임을 정한다. 시트 뒤 화면이
///   줄어드는 것은 뒤 화면이 아니라 시트가 알아야 하므로 이 경로가 필요하다.
///   `CustomTransitionPage`의 경로 클래스는 비공개라 이 값을 넘길 수 없어서 직접 만든다.
/// - [backSwipe]: iOS 왼쪽 가장자리 밀어서 뒤로 가기. `CustomTransitionPage`에는 없다
///   (Cupertino 전환에만 붙어 있다).
class CoraTransitionPage<T> extends CustomTransitionPage<T> {
  const CoraTransitionPage({
    required super.child,
    required super.transitionsBuilder,
    required super.transitionDuration,
    required super.reverseTransitionDuration,
    this.delegatedTransition,
    this.backSwipe = false,
    super.opaque,
    super.barrierDismissible,
    super.barrierLabel,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  final DelegatedTransitionBuilder? delegatedTransition;
  final bool backSwipe;

  @override
  Route<T> createRoute(BuildContext context) => _CoraPageRoute<T>(this);
}

class _CoraPageRoute<T> extends PageRoute<T> {
  _CoraPageRoute(CoraTransitionPage<T> page) : super(settings: page);

  CoraTransitionPage<T> get _page => settings as CoraTransitionPage<T>;

  @override
  bool get barrierDismissible => _page.barrierDismissible;

  @override
  Color? get barrierColor => _page.barrierColor;

  @override
  String? get barrierLabel => _page.barrierLabel;

  @override
  bool get maintainState => _page.maintainState;

  @override
  bool get fullscreenDialog => _page.fullscreenDialog;

  @override
  bool get opaque => _page.opaque;

  // 기기에서 '동작 줄이기'를 켜면 화면이 움직이지 않고 바로 바뀐다.
  @override
  Duration get transitionDuration =>
      _reduceMotion ? Duration.zero : _page.transitionDuration;

  @override
  Duration get reverseTransitionDuration =>
      _reduceMotion ? Duration.zero : _page.reverseTransitionDuration;

  bool get _reduceMotion {
    // 애니메이션 컨트롤러를 만들 때(build 밖) 읽히므로 의존성을 걸지 않고 값만 본다.
    final mediaQuery = navigator?.context
        .getInheritedWidgetOfExactType<MediaQuery>();
    return mediaQuery?.data.disableAnimations ?? false;
  }

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      _page.delegatedTransition;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => Semantics(
    scopesRoute: true,
    explicitChildNodes: true,
    child: _page.child,
  );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Android는 시스템 뒤로 가기 제스처가 따로 있으므로 iOS에서만 가장자리를 잡는다.
    final swipe =
        _page.backSwipe && Theme.of(context).platform == TargetPlatform.iOS;
    return _page.transitionsBuilder(
      context,
      animation,
      secondaryAnimation,
      swipe ? _BackSwipeDetector(route: this, child: child) : child,
    );
  }

  // controller는 보호 멤버라 이 클래스 안에서만 꺼낸다.
  AnimationController get _swipeController => controller!;
}

/// 전환 위젯의 바탕. 곡선 애니메이션을 만들고 정리한다.
///
/// 곡선은 들어올 때 easeOutCubic, 나갈 때는 뒤집은 곡선이라 닫힘도 빨리 출발한다.
/// iOS 뒤로 밀기처럼 손가락이 직접 움직이는 중에는 곡선 없이 손가락 위치를 그대로 따른다.
abstract class _CoraTransition extends StatefulWidget {
  const _CoraTransition({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  Widget buildTransition(
    BuildContext context,
    Animation<double> animation, {
    required bool following,
  });

  @override
  State<_CoraTransition> createState() => _CoraTransitionState();
}

class _CoraTransitionState extends State<_CoraTransition> {
  late CurvedAnimation _curved;

  static CurvedAnimation _curve(Animation<double> parent) => CurvedAnimation(
    parent: parent,
    curve: CoraMotion.standardCurve,
    reverseCurve: CoraMotion.standardCurve.flipped,
  );

  @override
  void initState() {
    super.initState();
    _curved = _curve(widget.animation);
  }

  @override
  void didUpdateWidget(_CoraTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      _curved.dispose();
      _curved = _curve(widget.animation);
    }
  }

  @override
  void dispose() {
    _curved.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 경로의 전환은 애니메이션이 움직일 때마다 다시 그려지므로 여기서 매번 읽어도 된다.
    final following =
        Navigator.maybeOf(context)?.userGestureInProgress ?? false;
    return widget.buildTransition(
      context,
      following ? widget.animation : _curved,
      following: following,
    );
  }
}

/// push로 들어오는 화면.
class _PushEnter extends _CoraTransition {
  const _PushEnter({required super.animation, required super.child});

  static final _enter = Tween<Offset>(
    begin: const Offset(CoraMotion.pushEnterOffset, 0),
    end: Offset.zero,
  );

  // 뒤로 밀기 중에는 화면이 손가락을 따라 너비 전체를 움직이고 흐려지지 않는다.
  // 24%만 움직이면 손가락보다 화면이 한참 뒤처진다.
  static final _follow = Tween<Offset>(
    begin: const Offset(1, 0),
    end: Offset.zero,
  );

  @override
  Widget buildTransition(
    BuildContext context,
    Animation<double> animation, {
    required bool following,
  }) {
    return SlideTransition(
      position: animation.drive(following ? _follow : _enter),
      textDirection: Directionality.of(context),
      child: FadeTransition(
        opacity: following ? kAlwaysCompleteAnimation : animation,
        child: child,
      ),
    );
  }
}

/// push 화면 밑에 깔리는 화면. 왼쪽으로 8% 밀리며 어두워진다.
class _PushUnderlay extends _CoraTransition {
  const _PushUnderlay({required super.animation, required super.child});

  static final _slide = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(-CoraMotion.pushUnderlayOffset, 0),
  );

  @override
  Widget buildTransition(
    BuildContext context,
    Animation<double> animation, {
    required bool following,
  }) {
    final c = context.colors;
    // 밀려난 만큼 오른쪽에 빈 틈이 생긴다. 들어오는 화면이 아직 반투명할 때 그 틈이
    // 검게 비치지 않도록 배경색으로 채운다. 시트처럼 투명한 화면은 채우면 뒤가 가려진다.
    final opaque = ModalRoute.opaqueOf(context) ?? true;
    return CustomPaint(
      painter: opaque
          ? _FillPainter(animation: animation, color: c.background)
          : null,
      foregroundPainter: _ScrimPainter(
        animation: animation,
        color: c.scrim,
        maxOpacity: CoraMotion.pushUnderlayDim,
      ),
      child: SlideTransition(
        position: animation.drive(_slide),
        textDirection: Directionality.of(context),
        child: child,
      ),
    );
  }
}

/// 아래에서 올라오는 시트.
class _SheetEnter extends _CoraTransition {
  const _SheetEnter({required super.animation, required super.child});

  static final _rise = Tween<Offset>(
    begin: const Offset(0, 1),
    end: Offset.zero,
  );

  @override
  Widget buildTransition(
    BuildContext context,
    Animation<double> animation, {
    required bool following,
  }) {
    return SlideTransition(position: animation.drive(_rise), child: child);
  }
}

/// 시트 뒤 화면. 96%로 줄어들며 모서리가 둥글어지고 어두워진다. 줄어든 둘레는 `scrim`.
class _SheetUnderlay extends _CoraTransition {
  const _SheetUnderlay({required super.animation, required super.child});

  static final _shrink = Tween<double>(
    begin: 1,
    end: CoraMotion.sheetUnderlayScale,
  );

  @override
  Widget buildTransition(
    BuildContext context,
    Animation<double> animation, {
    required bool following,
  }) {
    final c = context.colors;
    return CustomPaint(
      painter: _BackdropPainter(animation: animation, color: c.scrim),
      child: ScaleTransition(
        scale: animation.drive(_shrink),
        child: ClipRRect(
          clipper: _UnderlayClipper(animation),
          // 위에 시트가 없을 때는 자르지 않는다(쓸데없는 레이어를 만들지 않으려고).
          clipBehavior: animation.value > 0 ? Clip.antiAlias : Clip.none,
          child: CustomPaint(
            foregroundPainter: _ScrimPainter(
              animation: animation,
              color: c.scrim,
              maxOpacity: CoraMotion.sheetUnderlayDim,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// fade로 들어오는 화면.
class _FadeEnter extends _CoraTransition {
  const _FadeEnter({required super.animation, required super.child});

  @override
  Widget buildTransition(
    BuildContext context,
    Animation<double> animation, {
    required bool following,
  }) {
    return FadeTransition(opacity: animation, child: child);
  }
}

/// 시트의 모양: 상태 표시줄 아래 [CoraTransitions.sheetTopGap]부터 시작하는 위 모서리 28 카드.
class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.child});

  final Widget child;

  static const _radius = BorderRadius.vertical(
    top: Radius.circular(CoraRadius.xxl),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final top = MediaQuery.paddingOf(context).top + CoraTransitions.sheetTopGap;
    return Padding(
      padding: EdgeInsets.only(top: top),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.background,
          borderRadius: _radius,
          boxShadow: CoraShadows.sheet,
        ),
        // 다크에서는 그림자가 보이지 않고 시트와 뒤 화면이 둘 다 거의 검정이라 시트
        // 윗선이 사라진다. 위 둥근 테두리에만 `line` 실선을 그어 경계를 살린다.
        child: CustomPaint(
          foregroundPainter: _SheetEdgePainter(color: c.line),
          child: ClipRRect(
            borderRadius: _radius,
            // 시트 안 화면의 SafeArea가 상태 표시줄 높이를 한 번 더 비우지 않게 한다.
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// 시트 위 가장자리(양쪽 둥근 모서리와 윗변)에만 그리는 실선.
class _SheetEdgePainter extends CustomPainter {
  _SheetEdgePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const r = CoraRadius.xxl;
    const inset = 0.5; // 선 굵기 1의 절반만큼 안쪽에 그려 바깥으로 번지지 않게 한다.
    final path = Path()
      ..moveTo(inset, r)
      ..arcToPoint(
        const Offset(r, inset),
        radius: const Radius.circular(r - inset),
      )
      ..lineTo(size.width - r, inset)
      ..arcToPoint(
        Offset(size.width - inset, r),
        radius: const Radius.circular(r - inset),
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_SheetEdgePainter old) => old.color != color;
}

/// 진행도에 따라 `scrim`을 덮는다. 누르기는 통과시킨다.
class _ScrimPainter extends CustomPainter {
  _ScrimPainter({
    required this.animation,
    required this.color,
    required this.maxOpacity,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final Color color;
  final double maxOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    final opacity = animation.value.clamp(0.0, 1.0) * maxOpacity;
    if (opacity <= 0) return;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = color.withValues(alpha: color.a * opacity),
    );
  }

  @override
  bool hitTest(Offset position) => false;

  @override
  bool shouldRepaint(_ScrimPainter old) =>
      old.animation != animation ||
      old.color != color ||
      old.maxOpacity != maxOpacity;
}

/// 전환이 진행 중일 때만 영역을 한 색으로 채운다.
class _FillPainter extends CustomPainter {
  _FillPainter({required this.animation, required this.color})
    : super(repaint: animation);

  final Animation<double> animation;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (animation.value <= 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = color);
  }

  // CustomPaint의 뒤 그림은 기본으로 누르기를 받는다. 받으면 시트 위 틈을 눌러도 닫히지 않는다.
  @override
  bool hitTest(Offset position) => false;

  @override
  bool shouldRepaint(_FillPainter old) =>
      old.animation != animation || old.color != color;
}

/// 줄어든 뒤 화면 둘레만 채운다. 가운데를 비워 두어야 투명한 화면(시트) 뒤가 가려지지 않는다.
class _BackdropPainter extends CustomPainter {
  _BackdropPainter({required this.animation, required this.color})
    : super(repaint: animation);

  final Animation<double> animation;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value.clamp(0.0, 1.0);
    if (t <= 0) return;
    final scale = 1 - (1 - CoraMotion.sheetUnderlayScale) * t;
    // 줄어든 화면 가장자리 밑으로 1만큼 들어가게 그려 경계에 실금이 생기지 않게 한다.
    final inner = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: size.width * scale,
      height: size.height * scale,
    ).deflate(1);
    canvas.drawDRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.zero),
      RRect.fromRectAndRadius(
        inner,
        Radius.circular(_UnderlayClipper.radiusAt(t) * scale),
      ),
      Paint()..color = color,
    );
  }

  @override
  bool hitTest(Offset position) => false;

  @override
  bool shouldRepaint(_BackdropPainter old) =>
      old.animation != animation || old.color != color;
}

/// 시트 뒤 화면의 모서리. 시트가 올라오는 만큼 둥글어진다.
class _UnderlayClipper extends CustomClipper<RRect> {
  _UnderlayClipper(this.animation) : super(reclip: animation);

  final Animation<double> animation;

  static double radiusAt(double t) => CoraRadius.md * t;

  @override
  RRect getClip(Size size) => RRect.fromRectAndRadius(
    Offset.zero & size,
    Radius.circular(radiusAt(animation.value.clamp(0.0, 1.0))),
  );

  @override
  bool shouldReclip(_UnderlayClipper old) => old.animation != animation;
}

/// iOS 왼쪽 가장자리에서 밀어 뒤로 가기. Cupertino 전환의 같은 기능을 Cora 전환에 맞춰 옮겼다.
/// 손가락 아래 띠(너비 20 또는 왼쪽 안전 영역)에서 시작한 가로 끌기만 받는다.
class _BackSwipeDetector extends StatefulWidget {
  const _BackSwipeDetector({required this.route, required this.child});

  final _CoraPageRoute<dynamic> route;
  final Widget child;

  @override
  State<_BackSwipeDetector> createState() => _BackSwipeDetectorState();
}

class _BackSwipeDetectorState extends State<_BackSwipeDetector> {
  static const _edgeWidth = 20.0;

  late final HorizontalDragGestureRecognizer _recognizer;
  _BackSwipeController? _controller;

  @override
  void initState() {
    super.initState();
    _recognizer = HorizontalDragGestureRecognizer(debugOwner: this)
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd
      ..onCancel = _handleDragCancel;
  }

  @override
  void dispose() {
    _recognizer.dispose();
    // 끄는 도중에 사라지면 Navigator가 제스처 중인 상태로 남지 않게 한다.
    final controller = _controller;
    if (controller != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (controller.navigator.mounted) {
          controller.navigator.didStopUserGesture();
        }
      });
    }
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (widget.route.popGestureEnabled) _recognizer.addPointer(event);
  }

  void _handleDragStart(DragStartDetails details) {
    _controller = _BackSwipeController(widget.route);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _controller?.dragUpdate(
      _logical(details.primaryDelta! / context.size!.width),
    );
  }

  void _handleDragEnd(DragEndDetails details) {
    _controller?.dragEnd(
      _logical(details.velocity.pixelsPerSecond.dx / context.size!.width),
    );
    _controller = null;
  }

  void _handleDragCancel() {
    _controller?.dragEnd(0);
    _controller = null;
  }

  double _logical(double value) =>
      Directionality.of(context) == TextDirection.rtl ? -value : value;

  @override
  Widget build(BuildContext context) {
    final edge = math.max(
      Directionality.of(context) == TextDirection.rtl
          ? MediaQuery.paddingOf(context).right
          : MediaQuery.paddingOf(context).left,
      _edgeWidth,
    );
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        PositionedDirectional(
          start: 0,
          width: edge,
          top: 0,
          bottom: 0,
          child: Listener(
            onPointerDown: _handlePointerDown,
            behavior: HitTestBehavior.translucent,
          ),
        ),
      ],
    );
  }
}

/// 끌기 값을 경로의 애니메이션 값(1 = 화면이 다 보임, 0 = 사라짐)으로 바꾼다.
class _BackSwipeController {
  _BackSwipeController(this.route) : navigator = route.navigator! {
    // 제스처 중임을 알려야 전환이 곡선 없이 손가락을 따른다.
    navigator.didStartUserGesture();
  }

  final _CoraPageRoute<dynamic> route;
  final NavigatorState navigator;

  /// 화면 너비 기준 초당 이 이상으로 튕기면 위치와 상관없이 방향을 따른다.
  static const _minFlingVelocity = 1.0;

  AnimationController get _animation => route._swipeController;

  void dragUpdate(double delta) {
    _animation.value -= delta;
  }

  void dragEnd(double velocity) {
    final bool stay;
    if (!route.isCurrent) {
      // 끄는 사이 다른 이동이 일어났으면 화면이 스택에 남아 있는지만 따른다.
      stay = route.isActive;
    } else if (velocity.abs() >= _minFlingVelocity) {
      stay = velocity <= 0;
    } else {
      stay = _animation.value > 0.5;
    }

    if (stay) {
      _animation.animateTo(
        1,
        duration: CoraMotion.pushDuration,
        curve: CoraMotion.standardCurve,
      );
    } else {
      if (route.isCurrent) navigator.pop();
      if (_animation.isAnimating) {
        _animation.animateBack(
          0,
          duration: CoraMotion.pushDuration,
          curve: CoraMotion.standardCurve,
        );
      }
    }

    // 손을 뗀 뒤 남은 움직임이 끝날 때까지 제스처 상태를 유지한다. 중간에 풀면 곡선이
    // 바뀌어 화면이 튄다.
    if (_animation.isAnimating) {
      late final AnimationStatusListener done;
      done = (status) {
        navigator.didStopUserGesture();
        _animation.removeStatusListener(done);
      };
      _animation.addStatusListener(done);
    } else {
      navigator.didStopUserGesture();
    }
  }
}
