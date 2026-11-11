import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../demo_paths.dart';

/// 시연 화면이 함께 쓰는 작은 도구. 이 파일은 조율 세션만 고친다.
/// 묶음마다 필요한 위젯은 그 묶음 폴더 안에 만든다.

/// artifact의 `/_blob/<id>` 사진을 앱 자산으로 바꾼다.
abstract final class DemoImages {
  static const seoyun =
      'assets/images/demo_seoyun.jpg'; // d607dd0c… 서윤의 작은 취향(손목 시계)
  static const minCloset =
      'assets/images/demo_min_closet.jpg'; // b69c53f9… 민의 옷장 기록
  static const onecup = 'assets/images/demo_onecup.png'; // 2c6508f8… 하루 한 컵
  static const moaStudio =
      'assets/images/demo_moa_studio.jpg'; // b17a81a5… 모아 스튜디오
  static const ramen = 'assets/images/demo_ramen.png'; // 05c6e2f1… 한그릇 라멘

  static const Map<String, String> _byBlob = {
    'd607dd0c30dba30c6efc831cbd7a6f4f': seoyun,
    'b69c53f92919508dbffde40eedb1953c': minCloset,
    '2c6508f8caadc5c0466b315d99cbda6b': onecup,
    'b17a81a543b08af172aa89b26b5db39c': moaStudio,
    '05c6e2f12662029787761493c831ec3a': ramen,
  };

  /// `'/_blob/b69c…'` 또는 id만 받아 자산 경로를 돌려준다.
  static String forBlob(String blob) =>
      _byBlob[blob.split('/').last] ?? minCloset;
}

/// artifact의 사진 칸: `object-fit: cover` + `object-position: x% y%`.
class DemoPhoto extends StatelessWidget {
  const DemoPhoto(
    this.asset, {
    super.key,
    this.x = 50,
    this.y = 50,
    this.opacity = 1,
  });

  final String asset;

  /// `object-position`의 퍼센트 값(0~100).
  final double x;
  final double y;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Image.asset(
        asset,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment(x / 50 - 1, y / 50 - 1),
      ),
    );
  }
}

/// artifact의 인라인 SVG를 그대로 그린다. `svg`에는 `<svg …>…</svg>` 전체를 넣는다.
/// `currentColor`는 [color]로 바뀐다.
class DemoSvg extends StatelessWidget {
  const DemoSvg(this.svg, {super.key, this.color, this.size});

  final String svg;
  final Color? color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final c = color ?? DefaultTextStyle.of(context).style.color ?? Colors.black;
    final hex =
        '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
    return SvgPicture.string(
      svg.replaceAll('currentColor', hex),
      width: size,
      height: size,
    );
  }
}

/// artifact 링크(`href="X.dc.html"`)를 따라간다. 같은 화면이면 아무것도 하지 않는다.
void demoGo(BuildContext context, String canvasFile) {
  final path = DemoPaths.forCanvas(canvasFile);
  if (GoRouterState.of(context).uri.path == path) return;
  context.push(path);
}

/// 뒤로 가기(artifact의 `aria-label="뒤로"`/`닫기`): 쌓인 화면이 있으면 닫고, 없으면 목록으로.
void demoBack(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(DemoPaths.index);
  }
}

/// 하단 메뉴 한 칸.
class DemoNavItem {
  const DemoNavItem({
    required this.label,
    required this.svg,
    required this.canvasFile,
    this.current = false,
  });

  final String label;

  /// artifact의 아이콘 `<svg …>` 전체(`stroke="currentColor"`).
  final String svg;

  /// 누르면 갈 artifact 화면 파일 이름.
  final String canvasFile;
  final bool current;
}

/// artifact의 떠 있는 하단 메뉴(`nav aria-label="주요 메뉴"`).
/// 라이트: 바탕 #FFFFFF, 그림자 0 12 32 rgba(23,24,28,.12), 꺼진 칸 #8B9099, 켜진 칸 #17181C.
/// 다크: 바탕 #26282D, 그림자 0 12 32 rgba(23,24,28,.28), 꺼진 칸 #A0A4AD. 켜진 칸 색은 화면마다 다르면 [activeColor]로 넘긴다.
class DemoBottomNav extends StatelessWidget {
  const DemoBottomNav({
    super.key,
    required this.items,
    this.activeColor,
    this.inactiveColor,
  });

  final List<DemoNavItem> items;
  final Color? activeColor;
  final Color? inactiveColor;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final on =
        activeColor ??
        (dark ? const Color(0xFFF2F3F5) : const Color(0xFF17181C));
    final off =
        inactiveColor ??
        (dark ? const Color(0xFFA0A4AD) : const Color(0xFF8B9099));
    return Positioned(
      left: 16,
      right: 16,
      bottom: 20,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF26282D) : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(23, 24, 28, dark ? 0.28 : 0.12),
              offset: const Offset(0, 12),
              blurRadius: 32,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (final it in items)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: it.current ? null : () => demoGo(context, it.canvasFile),
                child: SizedBox(
                  width: 58,
                  height: 52,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      DemoSvg(it.svg, color: it.current ? on : off, size: 22),
                      const SizedBox(height: 3),
                      Text(
                        it.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                          color: it.current ? on : off,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// artifact 화면 틀: 390×844 기준의 `position: relative` 판. 자식은 [Stack] 안에서
/// `Positioned`(하단 고정 버튼, 하단 메뉴)와 일반 흐름(Column)을 섞어 쓴다.
/// 위쪽 안전 영역만 비우고, 아래 고정 요소는 artifact 값(bottom 20/32)을 그대로 쓴다.
class DemoFrame extends StatelessWidget {
  const DemoFrame({super.key, required this.children, this.background});

  final List<Widget> children;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(bottom: false, child: Stack(children: children)),
    );
  }
}

/// 화면 왼쪽 가장자리에서 시작한 끌기는 받지 않는 끌기 인식기. iOS 뒤로 밀기가 카드보다 먼저다.
class _EdgeSafePanRecognizer extends PanGestureRecognizer {
  _EdgeSafePanRecognizer({super.debugOwner});

  static const double edge = 24;

  @override
  bool isPointerAllowed(PointerEvent event) =>
      event.position.dx > edge && super.isPointerAllowed(event);
}

/// 카드 넘기기 화면의 손짓. [GestureDetector]와 같은 이름의 인자를 받는다.
/// 왼쪽 가장자리 끌기는 뒤로 밀기에 넘기고, 화면에 들어온 직후(0.7초)의 누르기는 무시한다
/// — 목록에서 누른 손가락이 새 화면의 카드를 누른 것으로 잡히지 않게.
class DemoCardGestures extends StatefulWidget {
  const DemoCardGestures({
    super.key,
    required this.child,
    this.behavior,
    this.onTap,
    this.onPanDown,
    this.onPanUpdate,
    this.onPanEnd,
    this.onPanCancel,
  });

  final Widget child;
  final HitTestBehavior? behavior;
  final VoidCallback? onTap;
  final GestureDragDownCallback? onPanDown;
  final GestureDragUpdateCallback? onPanUpdate;
  final GestureDragEndCallback? onPanEnd;
  final GestureDragCancelCallback? onPanCancel;

  @override
  State<DemoCardGestures> createState() => _DemoCardGesturesState();
}

class _DemoCardGesturesState extends State<DemoCardGestures> {
  final _shownAt = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: widget.behavior,
      gestures: {
        _EdgeSafePanRecognizer:
            GestureRecognizerFactoryWithHandlers<_EdgeSafePanRecognizer>(
              () => _EdgeSafePanRecognizer(debugOwner: this),
              (r) => r
                ..onDown = widget.onPanDown
                ..onUpdate = widget.onPanUpdate
                ..onEnd = widget.onPanEnd
                ..onCancel = widget.onPanCancel,
            ),
        TapGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
              () => TapGestureRecognizer(debugOwner: this),
              (r) => r
                ..onTap = widget.onTap == null
                    ? null
                    : () {
                        if (DateTime.now().difference(_shownAt) <
                            const Duration(milliseconds: 700)) {
                          return;
                        }
                        widget.onTap!();
                      },
            ),
      },
      child: widget.child,
    );
  }
}
