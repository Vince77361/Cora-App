import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';
import 'g1_ui.dart';

/// 01 발견 · 브랜드 관점 (`Main.dc.html`). 카드를 좌(넘김)·우(관심)·위(보류)로 밀거나 아래 버튼으로 고른다.
class BrandDiscoverPage extends StatefulWidget {
  const BrandDiscoverPage({super.key});

  @override
  State<BrandDiscoverPage> createState() => _BrandDiscoverPageState();
}

class _Card {
  const _Card({
    required this.name,
    required this.title,
    required this.price,
    required this.tags,
    required this.bg,
    required this.mutual,
    required this.blob,
  });

  final String name;
  final String title;
  final String price;
  final List<String> tags;
  final Color bg;
  final bool mutual;
  final String blob;
}

const List<_Card> _cards = [
  _Card(
    name: '서윤의 작은 취향',
    title: '출근 전 30초,\n오늘의 손목 루틴',
    price: '30만 원',
    tags: ['얼굴출연없음', '소품'],
    bg: Color(0xFFE8DDCB),
    mutual: true,
    blob: '/_blob/d607dd0c30dba30c6efc831cbd7a6f4f',
  ),
  _Card(
    name: '민의 옷장 기록',
    title: '같은 니트,\n세 가지 액세서리',
    price: '35만 원',
    tags: ['니트', '액세서리'],
    bg: Color(0xFFD9DCE6),
    mutual: false,
    blob: '/_blob/b69c53f92919508dbffde40eedb1953c',
  ),
  _Card(
    name: '하루 한 컵',
    title: '주말 아침,\n잔 하나로 바뀌는 식탁',
    price: '25만 원',
    tags: ['리빙', '아침루틴'],
    bg: Color(0xFFF3E3D3),
    mutual: false,
    blob: '/_blob/2c6508f8caadc5c0466b315d99cbda6b',
  ),
];

enum _Kind { like, pass, hold }

const String _svgUndo =
    '<svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round">'
    '<path d="M4 12a8 8 0 1 0 2.4-5.7"></path><path d="M4 4v4.5h4.5"></path></svg>';
const String _svgPass =
    '<svg width="42" height="42" viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" stroke-width="3" stroke-linecap="round">'
    '<path d="M6 6l12 12M18 6L6 18"></path></svg>';
const String _svgHold =
    '<svg width="32" height="32" viewBox="0 0 24 24" fill="#FFFFFF">'
    '<path d="M12 3l2.7 5.6 6.1.9-4.4 4.3 1 6.1L12 17l-5.4 2.9 1-6.1L3.2 9.5l6.1-.9z"></path></svg>';
const String _svgLike =
    '<svg width="46" height="46" viewBox="0 0 24 24" fill="#C6FF3D">'
    '<path d="M12 20.5s-7.5-4.6-7.5-10.4A4.3 4.3 0 0 1 12 7.4a4.3 4.3 0 0 1 7.5 2.7c0 5.8-7.5 10.4-7.5 10.4z"></path></svg>';
const String _svgBell =
    '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">'
    '<path d="M6 16V11a6 6 0 0 1 12 0v5l1.5 2h-15z"></path><path d="M10 20a2 2 0 0 0 4 0"></path></svg>';

class _BrandDiscoverPageState extends State<BrandDiscoverPage> {
  int _i = 0;
  double _dx = 0;
  double _dy = 0;
  bool _dragging = false;
  List<int> _history = [];
  String? _toast;
  bool _busy = false;
  Offset? _start;
  Timer? _t;
  Timer? _t2;

  @override
  void dispose() {
    _t?.cancel();
    _t2?.cancel();
    super.dispose();
  }

  void _down(DragDownDetails d) {
    if (_busy) return;
    _start = d.globalPosition;
    setState(() {
      _dragging = true;
      _toast = null;
    });
  }

  void _move(DragUpdateDetails d) {
    final s = _start;
    if (s == null) return;
    setState(() {
      _dx = d.globalPosition.dx - s.dx;
      _dy = d.globalPosition.dy - s.dy;
    });
  }

  void _up() {
    if (_start == null) return;
    _start = null;
    if (_dx > 110) {
      _fling(_Kind.like);
    } else if (_dx < -110) {
      _fling(_Kind.pass);
    } else if (_dy < -140 && _dx.abs() < 80) {
      _fling(_Kind.hold);
    } else {
      setState(() {
        _dx = 0;
        _dy = 0;
        _dragging = false;
      });
    }
  }

  void _fling(_Kind kind) {
    if (_busy || _i >= _cards.length) return;
    _busy = true;
    setState(() {
      switch (kind) {
        case _Kind.like:
          _dx = 560;
        case _Kind.pass:
          _dx = -560;
        case _Kind.hold:
          _dx = 0;
          _dy = -900;
      }
      _dragging = false;
      _toast = null;
    });
    _t?.cancel();
    _t = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final idx = _i;
      final card = _cards[idx];
      final toast = kind == _Kind.like && card.mutual ? 'match' : kind.name;
      setState(() {
        _i = idx + 1;
        _dx = 0;
        _dy = 0;
        _dragging = true;
        _history = [..._history, idx];
        _toast = toast;
      });
      _t2 = Timer(const Duration(milliseconds: 40), () {
        if (!mounted) return;
        _busy = false;
        setState(() => _dragging = false);
      });
    });
  }

  void _undo() {
    if (_history.isEmpty || _busy) return;
    setState(() {
      _i = _history.last;
      _history = _history.sublist(0, _history.length - 1);
      _toast = null;
      _dx = 0;
      _dy = 0;
      _dragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = G1Palette.of(context);
    final done = _i >= _cards.length;
    return DemoFrame(
      background: p.bg,
      children: [
        _header(context, p),
        Positioned(
          left: 12,
          right: 12,
          top: 64,
          bottom: 100,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: p.dark ? const Color(0xFF0F1012) : const Color(0xFFE6E8EB),
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2917181C),
                  offset: Offset(0, 16),
                  blurRadius: 40,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (done) _donePanel(context, p),
                  if (_i + 1 < _cards.length) _cardView(_i + 1, false, p),
                  if (_i < _cards.length) _cardView(_i, true, p),
                  if (_toast == 'pass')
                    _toastBox(
                      p,
                      '넘겼어요. 상대에게는 알리지 않아요.',
                      '이유 남기기',
                      'Pass.dc.html',
                    ),
                  if (_toast == 'like')
                    _toastBox(
                      p,
                      '관심을 보냈어요. 상대도 고르면 알려드려요.',
                      '관심 목록',
                      'Likes.dc.html',
                    ),
                  if (_toast == 'hold')
                    _toastBox(p, '보류함에 담았어요.', '보류 보기', 'Likes.dc.html'),
                  if (_toast == 'match') _matchToast(p),
                  if (!done) _actions(),
                ],
              ),
            ),
          ),
        ),
        g1BottomNav(context, 0),
      ],
    );
  }

  Widget _header(BuildContext context, G1Palette p) {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const G1Logo(fontSize: 24, limeRing: true),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                G1Tap(
                  onTap: () => demoGo(context, 'NNotify.dc.html'),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        DemoSvg(_svgBell, color: p.text, size: 22),
                        Positioned(
                          right: 10,
                          top: 10,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: g1Lime,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: p.bg, spreadRadius: 2),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: p.dark
                              ? const Color(0xFFF2F3F5)
                              : const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: p.dark
                              ? null
                              : const [
                                  BoxShadow(
                                    color: Color(0x1A17181C),
                                    offset: Offset(0, 2),
                                    blurRadius: 8,
                                  ),
                                ],
                        ),
                        child: Text('브랜드', style: g1Text(13, 500, g1Ink)),
                      ),
                      const SizedBox(width: 2),
                      G1Tap(
                        onTap: () => demoGo(context, 'CreatorDiscover.dc.html'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          child: Text('크리에이터', style: g1Text(13, 500, p.sub)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _donePanel(BuildContext context, G1Palette p) {
    return Positioned.fill(
      child: Container(
        color: const Color(0xFF1F2A00),
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '오늘 추천을 모두 봤어요.',
              style: g1Text(28, 900, Colors.white, ls: -0.04),
            ),
            const SizedBox(height: 12),
            Text(
              '관심과 보류에 담은 후보를 비교해 보세요. 내일 새 추천이 올라와요.',
              style: g1Text(15, 400, const Color(0xFFF3FFD6), height: 1.6),
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 8),
            G1Tap(
              onTap: () => demoGo(context, 'Likes.dc.html'),
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                decoration: BoxDecoration(
                  color: g1Lime,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  '관심·보류 보기',
                  style: g1Text(
                    16,
                    700,
                    p.dark ? const Color(0xFFE4FFB0) : g1OnLime,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            G1Tap(
              onTap: _undo,
              child: SizedBox(
                height: 44,
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: 1,
                  child: Text(
                    '마지막 카드 되돌리기',
                    style: g1Text(14, 500, g1Lime).copyWith(
                      decoration: TextDecoration.underline,
                      decorationColor: g1Lime,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardView(int idx, bool top, G1Palette p) {
    final c = _cards[idx];
    final n = _cards.length;
    double clamp(double v) => v.clamp(0.0, 1.0);
    final prog = clamp(math.max(_dx.abs(), -_dy) / 120);
    final Matrix4 m = top
        ? (Matrix4.translationValues(_dx, _dy, 0)
            ..rotateZ(_dx / 16 * math.pi / 180))
        : (Matrix4.identity()
            ..scaleByDouble(0.94 + 0.06 * prog, 0.94 + 0.06 * prog, 1, 1));
    final likeOp = top ? clamp(_dx / 100) : 0.0;
    final passOp = top ? clamp(-_dx / 100) : 0.0;
    final holdOp = top && _dx.abs() < 60 ? clamp(-_dy / 120) : 0.0;

    Widget content = ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: c.bg),
          DemoPhoto(DemoImages.forBlob(c.blob), x: 50, y: 30),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 120,
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: g1FadeDown([0.38, 0])),
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            top: 14,
            child: Row(
              children: [
                for (var k = 0; k < 3; k++) ...[
                  if (k > 0) const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: k == 0
                            ? (p.dark ? const Color(0xFF0F1012) : Colors.white)
                            : const Color(0x66FFFFFF),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            left: 16,
            top: 28,
            child: Text(
              '운영자 추천 ${idx + 1} / $n',
              style: g1Text(12, 500, Colors.white),
            ),
          ),
          Positioned(
            left: 22,
            top: 70,
            child: Opacity(
              opacity: likeOp,
              child: Transform.rotate(
                angle: -14 * math.pi / 180,
                child: _stamp('관심', g1Lime, const Color(0x8C1F2A00), pad: 14),
              ),
            ),
          ),
          Positioned(
            right: 22,
            top: 70,
            child: Opacity(
              opacity: passOp,
              child: Transform.rotate(
                angle: 14 * math.pi / 180,
                child: _stamp(
                  '넘김',
                  Colors.white,
                  const Color(0x8C17181C),
                  pad: 14,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 170,
            child: Center(
              child: Opacity(
                opacity: holdOp,
                child: SizedBox(
                  width: 124,
                  child: _stamp(
                    '보류',
                    Colors.white,
                    const Color(0x8C17181C),
                    pad: 0,
                    center: true,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 300, 22, 116),
              decoration: BoxDecoration(
                gradient: g1FadeDown(
                  [0, 0.2, 0.48, 0.66],
                  stops: const [0, 0.35, 0.7, 1],
                ),
              ),
              child: _cardText(c),
            ),
          ),
        ],
      ),
    );

    if (top) {
      content = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanDown: _down,
        onPanUpdate: _move,
        onPanEnd: (_) => _up(),
        onPanCancel: _up,
        onTap: () {
          if (_busy) return;
          demoGo(context, 'Terms.dc.html');
        },
        child: content,
      );
    }

    return Positioned.fill(
      key: ValueKey(idx),
      child: AnimatedContainer(
        duration: _dragging ? Duration.zero : const Duration(milliseconds: 300),
        curve: const Cubic(.2, .8, .3, 1),
        transformAlignment: Alignment.center,
        transform: m,
        child: content,
      ),
    );
  }

  Widget _stamp(
    String label,
    Color color,
    Color bg, {
    required double pad,
    bool center = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: pad, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: color, width: 5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        textAlign: center ? TextAlign.center : null,
        style: g1Text(40, 900, color, ls: -0.02),
      ),
    );
  }

  Widget _cardText(_Card c) {
    const shadow = [
      Shadow(color: Color(0x47000000), offset: Offset(0, 1), blurRadius: 14),
    ];
    TextStyle s(double size, int w, Color color, {double ls = 0, double? h}) =>
        g1Text(size, w, color, ls: ls, height: h).copyWith(shadows: shadow);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(c.name, style: s(14, 500, g1PhotoText)),
        const SizedBox(height: 10),
        Text(c.title, style: s(36, 900, Colors.white, ls: -0.05, h: 1.1)),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(c.price, style: s(20, 900, g1Lime, ls: -0.02)),
            for (final t in c.tags) ...[
              const SizedBox(width: 12),
              Text('#$t', style: s(15, 700, g1PhotoText)),
            ],
          ],
        ),
      ],
    );
  }

  Widget _toastBox(
    G1Palette p,
    String message,
    String linkLabel,
    String canvasFile,
  ) {
    return Positioned(
      left: 10,
      right: 10,
      top: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: p.dark ? const Color(0xFF2A2D33) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: p.dark
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x2917181C),
                    offset: Offset(0, 8),
                    blurRadius: 24,
                  ),
                ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: g1Text(14, 400, p.dark ? Colors.white : g1Ink),
              ),
            ),
            const SizedBox(width: 10),
            G1Tap(
              onTap: () => demoGo(context, canvasFile),
              child: Text(linkLabel, style: g1Text(14, 700, g1Lime)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _matchToast(G1Palette p) {
    return Positioned(
      left: 10,
      right: 10,
      top: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: g1Lime,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '서윤의 작은 취향과 서로 관심이 닿았어요.',
                style: g1Text(14, 500, g1OnLime),
              ),
            ),
            const SizedBox(width: 10),
            G1Tap(
              onTap: () => demoGo(context, 'Match.dc.html'),
              child: Text('확인하기', style: g1Text(14, 900, p.text)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actions() {
    final noUndo = _history.isEmpty;
    Widget btn(
      double box,
      String svg,
      VoidCallback? onTap, {
      double opacity = 1,
    }) {
      return G1Tap(
        onTap: onTap,
        child: Opacity(
          opacity: opacity,
          child: SizedBox(
            width: box,
            height: box,
            child: Center(child: _Shadowed(child: DemoSvg(svg))),
          ),
        ),
      );
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 26,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          btn(52, _svgUndo, noUndo ? null : _undo, opacity: noUndo ? 0.45 : 1),
          const SizedBox(width: 16),
          btn(64, _svgPass, () => _fling(_Kind.pass)),
          const SizedBox(width: 16),
          btn(52, _svgHold, () => _fling(_Kind.hold)),
          const SizedBox(width: 16),
          btn(64, _svgLike, () => _fling(_Kind.like)),
        ],
      ),
    );
  }
}

/// CSS `filter: drop-shadow(0 2px 6px rgba(0,0,0,0.55))`에 가깝게 흐린 그림자를 깐다.
class _Shadowed extends StatelessWidget {
  const _Shadowed({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Transform.translate(
          offset: const Offset(0, 2),
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Color(0x8C000000),
                BlendMode.srcIn,
              ),
              child: child,
            ),
          ),
        ),
        child,
      ],
    );
  }
}
