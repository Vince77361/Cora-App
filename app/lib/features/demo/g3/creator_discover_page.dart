import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../demo_role.dart';
import '../shared/demo_role_nav.dart';
import '../shared/demo_ui.dart';
import 'g3_common.dart';

/// 카드 뒤에 깔리는 도형(사진이 없는 카드의 그림). artifact의 `shapes`.
class _Shape {
  const _Shape(
    this.l,
    this.t,
    this.w,
    this.h, {
    this.radius = BorderRadius.zero,
    this.bg,
    this.border,
    this.borderWidth = 0,
  });

  final double l;
  final double t;
  final double w;
  final double h;
  final BorderRadius radius;
  final Color? bg;
  final Color? border;
  final double borderWidth;
}

class _Card {
  const _Card({
    required this.href,
    required this.name,
    required this.title,
    required this.price,
    required this.tags,
    required this.bg,
    required this.mutual,
    this.asset,
    this.shapes = const [],
    this.darkShapeOverrides = const {},
  });

  final String href;
  final String name;
  final String title;
  final String price;
  final List<String> tags;
  final Color bg;
  final bool mutual;
  final String? asset;
  final List<_Shape> shapes;

  /// 다크에서 바뀌는 도형 바탕(도형 번호 → 색). 결 리빙 카드의 몸통이 흰색에서 #0F1012가 된다.
  final Map<int, Color> darkShapeOverrides;
}

const Color _lime = Color(0xFFC6FF3D);
const Color _white = Color(0xFFFFFFFF);
const Color _tagText = Color(0xFFE4E6EA);

const String _logoSvg =
    '<svg width="26" height="26" viewBox="0 0 26 26" fill="none" stroke-width="3"><circle cx="9.5" cy="13" r="6.5" stroke="currentColor"></circle><circle cx="16.5" cy="13" r="6.5" stroke="#C6FF3D"></circle></svg>';
const String _undoSvg =
    '<svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"><path d="M4 12a8 8 0 1 0 2.4-5.7"></path><path d="M4 4v4.5h4.5"></path></svg>';
const String _passSvg =
    '<svg width="42" height="42" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round"><path d="M6 6l12 12M18 6L6 18"></path></svg>';
const String _holdSvg =
    '<svg width="32" height="32" viewBox="0 0 24 24" fill="currentColor"><path d="M12 3l2.7 5.6 6.1.9-4.4 4.3 1 6.1L12 17l-5.4 2.9 1-6.1L3.2 9.5l6.1-.9z"></path></svg>';
const String _likeSvg =
    '<svg width="46" height="46" viewBox="0 0 24 24" fill="currentColor"><path d="M12 20.5s-7.5-4.6-7.5-10.4A4.3 4.3 0 0 1 12 7.4a4.3 4.3 0 0 1 7.5 2.7c0 5.8-7.5 10.4-7.5 10.4z"></path></svg>';

const List<_Card> _cards = [
  _Card(
    href: 'NCampaign.dc.html',
    name: '모아 스튜디오',
    title: '나만의 아침 루틴\n속 작은 포인트',
    price: '30만 원 + 제품',
    tags: ['얼굴출연없음', '대본낭독없음'],
    bg: Color(0xFF2E5B43),
    mutual: true,
    asset: DemoImages.moaStudio,
    shapes: [
      _Shape(
        70,
        160,
        150,
        150,
        radius: BorderRadius.all(Radius.circular(75)),
        border: Color(0xFFE8C07A),
        borderWidth: 14,
      ),
      _Shape(
        226,
        260,
        84,
        84,
        radius: BorderRadius.all(Radius.circular(42)),
        border: Color(0xFFD9DCE6),
        borderWidth: 9,
      ),
      _Shape(0, 400, 390, 70, bg: Color(0xFF24493A)),
    ],
  ),
  _Card(
    href: 'NStoreView.dc.html',
    name: '한그릇 라멘',
    title: '김이 오르는\n첫 숟가락',
    price: '2인 식사권 + 조회수당',
    tags: ['소상공인', '팔로워무관'],
    bg: Color(0xFFF6E3C8),
    mutual: false,
    asset: DemoImages.ramen,
  ),
  _Card(
    href: 'Proposal.dc.html',
    name: '결 리빙',
    title: '느린 주말,\n향으로 여는 방',
    price: '40만 원',
    tags: ['리빙', '솔직후기'],
    bg: Color(0xFFE7DDEE),
    mutual: false,
    darkShapeOverrides: {0: Color(0xFF0F1012)},
    shapes: [
      _Shape(
        150,
        210,
        90,
        150,
        radius: BorderRadius.all(Radius.circular(14)),
        bg: Color(0xFFFFFFFF),
      ),
      _Shape(
        190,
        176,
        10,
        34,
        radius: BorderRadius.all(Radius.circular(5)),
        bg: Color(0xFF3A3D46),
      ),
      // border-radius: 50% 50% 50% 50% / 60% 60% 40% 40% (22×30)
      _Shape(
        184,
        150,
        22,
        30,
        radius: BorderRadius.only(
          topLeft: Radius.elliptical(11, 18),
          topRight: Radius.elliptical(11, 18),
          bottomLeft: Radius.elliptical(11, 12),
          bottomRight: Radius.elliptical(11, 12),
        ),
        bg: Color(0xFFFFB547),
      ),
      _Shape(0, 360, 390, 420, bg: Color(0xFFCDBFD8)),
    ],
  ),
  _Card(
    href: 'Proposal.dc.html',
    name: '오늘의 잔',
    title: '하루 한 잔,\n손에 맞는 컵',
    price: '20만 원 + 제품',
    tags: ['주방', '손클로즈업'],
    bg: Color(0xFFF6E7C8),
    mutual: false,
    shapes: [
      _Shape(
        120,
        210,
        130,
        150,
        radius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(50),
          bottomRight: Radius.circular(50),
        ),
        bg: Color(0xFF3C6E91),
      ),
      _Shape(
        236,
        236,
        56,
        64,
        radius: BorderRadius.all(Radius.circular(32)),
        border: Color(0xFF3C6E91),
        borderWidth: 12,
      ),
      _Shape(0, 360, 390, 420, bg: Color(0xFFE2CDA0)),
    ],
  ),
];

/// 08 크리에이터의 발견 (`CreatorDiscover.dc.html`) — 카드를 끌어 관심·넘김·보류.
class CreatorDiscoverPage extends StatefulWidget {
  const CreatorDiscoverPage({super.key});

  @override
  State<CreatorDiscoverPage> createState() => _CreatorDiscoverPageState();
}

class _CreatorDiscoverPageState extends State<CreatorDiscoverPage> {
  int _i = 0;
  double _dx = 0;
  double _dy = 0;
  bool _dragging = false;
  final List<int> _history = [];
  String? _toast; // pass | like | hold | match
  bool _busy = false;
  Timer? _t;
  Timer? _t2;

  static const _curve = Cubic(.2, .8, .3, 1);

  @override
  void dispose() {
    _t?.cancel();
    _t2?.cancel();
    super.dispose();
  }

  double _clamp(double v) => math.max(0, math.min(1, v));

  void _down() {
    if (_busy) return;
    setState(() {
      _dragging = true;
      _toast = null;
    });
  }

  void _move(DragUpdateDetails d) {
    if (_busy) return;
    setState(() {
      _dx += d.delta.dx;
      _dy += d.delta.dy;
    });
  }

  void _up() {
    if (_busy) return;
    if (_dx > 110) {
      _fling('like');
    } else if (_dx < -110) {
      _fling('pass');
    } else if (_dy < -140 && _dx.abs() < 80) {
      _fling('hold');
    } else {
      setState(() {
        _dx = 0;
        _dy = 0;
        _dragging = false;
      });
    }
  }

  void _cancelDrag() {
    if (_busy) return;
    setState(() {
      _dx = 0;
      _dy = 0;
      _dragging = false;
    });
  }

  void _fling(String kind) {
    if (_busy || _i >= _cards.length) return;
    _busy = true;
    final outDx = kind == 'like' ? 560.0 : (kind == 'pass' ? -560.0 : 0.0);
    final outDy = kind == 'hold' ? -900.0 : _dy;
    setState(() {
      _dx = outDx;
      _dy = outDy;
      _dragging = false;
      _toast = null;
    });
    _t?.cancel();
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _t = Timer(reduced ? Duration.zero : const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final idx = _i;
      final card = _cards[idx];
      final toast = kind == 'like' && card.mutual ? 'match' : kind;
      setState(() {
        _i = idx + 1;
        _dx = 0;
        _dy = 0;
        _dragging = true;
        _history.add(idx);
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
      _i = _history.removeLast();
      _toast = null;
      _dx = 0;
      _dy = 0;
      _dragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = G3Palette.of(context);
    final n = _cards.length;
    return DemoFrame(
      background: p.bg,
      children: [
        _header(context, p),
        Positioned(
          left: 12,
          right: 12,
          top: 64,
          bottom: 100,
          child: Container(
            clipBehavior: Clip.antiAlias,
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
            child: Stack(
              children: [
                if (_i >= n) _doneOverlay(context, p),
                if (_i + 1 < n) _nextCard(p, _i + 1),
                if (_i < n) _topCard(context, p, _i),
                if (_toast != null) _toastBar(context, p),
                if (_i < n) _actions(),
              ],
            ),
          ),
        ),
        demoRoleNav(
          current: 0,
          fallback: DemoRole.creator,
          activeColor: p.dark ? _lime : null,
        ),
      ],
    );
  }

  Widget _header(BuildContext context, G3Palette p) {
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
            Row(
              children: [
                DemoSvg(_logoSvg, color: p.text, size: 26),
                const SizedBox(width: 6),
                Text(
                  'cora',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: g3Ls(24, -0.05),
                    color: p.text,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _doneOverlay(BuildContext context, G3Palette p) {
    return Positioned.fill(
      child: Container(
        color: const Color(0xFF1F2A00),
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '오늘 맞는 캠페인을 모두 봤어요.',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: g3Ls(28, -0.04),
                color: _white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '협업 원칙을 다듬으면 더 잘 맞는 캠페인이 올라와요.',
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Color(0xFFF3FFD6),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => demoGo(context, 'Principles.dc.html'),
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _lime,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '협업 원칙 다듬기',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: p.dark
                        ? const Color(0xFFE4FFB0)
                        : const Color(0xFF1F2A00),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _undo,
              child: const SizedBox(
                height: 44,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '마지막 카드 되돌리기',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _lime,
                      decoration: TextDecoration.underline,
                      decorationColor: _lime,
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

  Widget _nextCard(G3Palette p, int idx) {
    final pr = _clamp(math.max(_dx.abs(), -_dy) / 120);
    return Positioned.fill(
      key: ValueKey('card$idx'),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: 0.94 + 0.06 * pr),
        duration: _dragging ? Duration.zero : const Duration(milliseconds: 300),
        curve: _curve,
        builder: (context, s, child) => Transform.scale(scale: s, child: child),
        child: IgnorePointer(child: _cardBody(p, idx, 0, 0, 0)),
      ),
    );
  }

  Widget _topCard(BuildContext context, G3Palette p, int idx) {
    final likeOp = _clamp(_dx / 100);
    final passOp = _clamp(-_dx / 100);
    final holdOp = _dx.abs() < 60 ? _clamp(-_dy / 120) : 0.0;
    return Positioned.fill(
      key: ValueKey('card$idx'),
      child: DemoCardGestures(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!_busy) demoGo(context, _cards[idx].href);
        },
        onPanDown: (_) => _down(),
        onPanUpdate: _move,
        onPanEnd: (_) => _up(),
        onPanCancel: _cancelDrag,
        child: TweenAnimationBuilder<Offset>(
          tween: Tween<Offset>(end: Offset(_dx, _dy)),
          duration: _dragging
              ? Duration.zero
              : const Duration(milliseconds: 300),
          curve: _curve,
          builder: (context, o, child) => Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..translateByDouble(o.dx, o.dy, 0, 1)
              ..rotateZ(o.dx / 16 * math.pi / 180),
            child: child,
          ),
          child: _cardBody(p, idx, likeOp, passOp, holdOp),
        ),
      ),
    );
  }

  Widget _cardBody(
    G3Palette p,
    int idx,
    double likeOp,
    double passOp,
    double holdOp,
  ) {
    final c = _cards[idx];
    const shadow = [
      Shadow(color: Color(0x47000000), offset: Offset(0, 1), blurRadius: 14),
    ];
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(color: c.bg),
      child: Stack(
        children: [
          for (var k = 0; k < c.shapes.length; k++)
            _shape(c.shapes[k], p.dark ? c.darkShapeOverrides[k] : null),
          if (c.asset != null)
            Positioned.fill(child: DemoPhoto(c.asset!, x: 62, y: 50)),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 120,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x6117181C), Color(0x0017181C)],
                ),
              ),
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            top: 14,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: p.dark ? const Color(0xFF0F1012) : _white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0x66FFFFFF),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            top: 28,
            child: Text(
              '내 원칙과 맞는 캠페인 ${idx + 1} / ${_cards.length}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _white,
              ),
            ),
          ),
          Positioned(
            left: 22,
            top: 70,
            child: Opacity(
              opacity: likeOp,
              child: Transform.rotate(
                angle: -14 * math.pi / 180,
                child: _stamp('관심', _lime, _lime, const Color(0x8C1F2A00)),
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
                child: _stamp('넘김', _white, _white, const Color(0x8C17181C)),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 170,
            child: Opacity(
              opacity: holdOp,
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: 124,
                  child: _stamp(
                    '보류',
                    _white,
                    _white,
                    const Color(0x8C17181C),
                    fixedWidth: true,
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
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x0017181C),
                    Color(0x3317181C),
                    Color(0x7A17181C),
                    Color(0xA817181C),
                  ],
                  stops: [0, .35, .7, 1],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _tagText,
                      shadows: shadow,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    c.title,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: g3Ls(36, -0.05),
                      height: 1.1,
                      color: _white,
                      shadows: shadow,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      Text(
                        c.price,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: g3Ls(20, -0.02),
                          color: _lime,
                          shadows: shadow,
                        ),
                      ),
                      for (final t in c.tags)
                        Text(
                          '#$t',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _tagText,
                            shadows: shadow,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stamp(
    String label,
    Color border,
    Color text,
    Color bg, {
    bool fixedWidth = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 2,
        horizontal: fixedWidth ? 0 : 14,
      ),
      alignment: fixedWidth ? Alignment.center : null,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 5),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w900,
          letterSpacing: g3Ls(40, -0.02),
          color: text,
        ),
      ),
    );
  }

  Widget _shape(_Shape s, Color? darkBg) {
    return Positioned(
      left: s.l,
      top: s.t,
      width: s.w,
      height: s.h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: darkBg ?? s.bg,
          borderRadius: s.radius,
          border: s.borderWidth > 0
              ? Border.all(color: s.border!, width: s.borderWidth)
              : null,
        ),
      ),
    );
  }

  Widget _toastBar(BuildContext context, G3Palette p) {
    late final String msg;
    late final String link;
    late final String file;
    switch (_toast) {
      case 'pass':
        msg = '넘겼어요. 브랜드에는 알리지 않아요.';
        link = '이유 남기기';
        file = 'Pass.dc.html';
      case 'like':
        msg = '관심을 보냈어요. 브랜드도 고르면 알려드려요.';
        link = '관심 목록';
        file = 'Likes.dc.html';
      case 'hold':
        msg = '보류함에 담았어요.';
        link = '보류 보기';
        file = 'Likes.dc.html';
      default:
        msg = '모아 스튜디오와 서로 관심이 닿았어요.';
        link = '확인하기';
        file = 'Match.dc.html';
    }
    final match = _toast == 'match';
    final bg = match ? _lime : (p.dark ? const Color(0xFF2A2D33) : _white);
    final fg = match ? const Color(0xFF1F2A00) : (p.dark ? _white : g3Ink);
    final linkColor = match
        ? (p.dark ? const Color(0xFFF2F3F5) : g3Ink)
        : _lime;
    return Positioned(
      left: 10,
      right: 10,
      top: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: (match || p.dark)
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
                msg,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: match ? FontWeight.w500 : FontWeight.w400,
                  color: fg,
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => demoGo(context, file),
              child: Text(
                link,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: match ? FontWeight.w900 : FontWeight.w700,
                  color: linkColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actions() {
    final noUndo = _history.isEmpty;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 26,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _actionButton(
            '되돌리기',
            _undoSvg,
            _white,
            52,
            28,
            noUndo ? null : _undo,
            opacity: noUndo ? 0.45 : 1,
          ),
          const SizedBox(width: 16),
          _actionButton('넘기기', _passSvg, _white, 64, 42, () => _fling('pass')),
          const SizedBox(width: 16),
          _actionButton('보류', _holdSvg, _white, 52, 32, () => _fling('hold')),
          const SizedBox(width: 16),
          _actionButton(
            '관심 있어요',
            _likeSvg,
            _lime,
            64,
            46,
            () => _fling('like'),
          ),
        ],
      ),
    );
  }

  /// 흰 아이콘 버튼. artifact의 `filter: drop-shadow(0 2px 6px rgba(0,0,0,.55))`는 같은 아이콘을 검게 흐려 아래에 깐다.
  Widget _actionButton(
    String label,
    String svg,
    Color color,
    double box,
    double icon,
    VoidCallback? onTap, {
    double opacity = 1,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Opacity(
          opacity: opacity,
          child: SizedBox(
            width: box,
            height: box,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.translate(
                  offset: const Offset(0, 2),
                  child: Opacity(
                    opacity: 0.55,
                    child: ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                      child: DemoSvg(
                        svg,
                        color: const Color(0xFF000000),
                        size: icon,
                      ),
                    ),
                  ),
                ),
                DemoSvg(svg, color: color, size: icon),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
