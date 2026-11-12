import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';

/// g1 묶음 화면이 함께 쓰는 색과 작은 위젯. artifact의 라이트·다크 값을 그대로 옮겼다.

const Color g1Lime = Color(0xFFC6FF3D);
const Color g1OnLime = Color(0xFF1F2A00);
const Color g1Olive = Color(0xFF5C7A00);
const Color g1PhotoText = Color(0xFFE4E6EA);
const Color g1Ink = Color(0xFF17181C);

/// 화면 하나가 쓰는 라이트·다크 팔레트.
class G1Palette {
  const G1Palette(this.dark);

  final bool dark;

  static G1Palette of(BuildContext context) =>
      G1Palette(Theme.of(context).brightness == Brightness.dark);

  Color get bg => dark ? const Color(0xFF0F1012) : const Color(0xFFFFFFFF);

  /// 본문 글자색(#17181C / #F2F3F5).
  Color get text => dark ? const Color(0xFFF2F3F5) : const Color(0xFF17181C);

  /// 보조 글자색(#5C6068 / #A0A4AD).
  Color get sub => dark ? const Color(0xFFA0A4AD) : const Color(0xFF5C6068);

  /// 옅은 면(#F8F9FA / #1C1E22).
  Color get surface => dark ? const Color(0xFF1C1E22) : const Color(0xFFF8F9FA);

  /// 구분선·막대 바탕(#E6E8EB / #2A2D33).
  Color get line => dark ? const Color(0xFF2A2D33) : const Color(0xFFE6E8EB);
}

/// CSS 글자 스타일: 크기(px), 굵기, 색, 자간(em), 줄 높이.
TextStyle g1Text(
  double size,
  int weight,
  Color color, {
  double ls = 0,
  double? height,
}) {
  return TextStyle(
    fontSize: size,
    fontWeight: switch (weight) {
      400 => FontWeight.w400,
      500 => FontWeight.w500,
      700 => FontWeight.w700,
      _ => FontWeight.w900,
    },
    color: color,
    letterSpacing: size * ls,
    height: height,
    decoration: TextDecoration.none,
  );
}

/// 눌렀을 때 [onTap]을 부르는 빈 곳 포함 터치 영역.
class G1Tap extends StatelessWidget {
  const G1Tap({super.key, required this.onTap, required this.child});

  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: child,
    );
  }
}

/// 로고(겹친 두 원 + cora). [limeRing]이면 오른쪽 원이 라임이다.
class G1Logo extends StatelessWidget {
  const G1Logo({super.key, required this.fontSize, this.limeRing = false});

  final double fontSize;
  final bool limeRing;

  @override
  Widget build(BuildContext context) {
    final p = G1Palette.of(context);
    final ring = limeRing ? '#C6FF3D' : 'currentColor';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DemoSvg(
          '<svg width="26" height="26" viewBox="0 0 26 26" fill="none" stroke="currentColor" stroke-width="3">'
          '<circle cx="9.5" cy="13" r="6.5"></circle><circle cx="16.5" cy="13" r="6.5" stroke="$ring"></circle></svg>',
          color: p.text,
          size: 26,
        ),
        const SizedBox(width: 6),
        Text('cora', style: g1Text(fontSize, 900, p.text, ls: -0.05)),
      ],
    );
  }
}

/// 관심·보류, 진행 단계의 머리글: 로고만 둔다(화면 이름 알약은 뺐다).
class G1Header extends StatelessWidget {
  const G1Header({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [const G1Logo(fontSize: 25), const SizedBox.shrink()],
      ),
    );
  }
}

const String _navFind =
    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round">'
    '<rect x="6" y="3" width="12" height="17" rx="3"></rect><path d="M3 7v10M21 7v10"></path></svg>';
const String _navLike =
    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round">'
    '<path d="M12 20s-7-4.4-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.6-7 10-7 10z"></path></svg>';
const String _navChat =
    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round">'
    '<path d="M4 5h16v11H10l-6 4z"></path></svg>';
const String _navWork =
    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round">'
    '<rect x="3" y="7" width="18" height="13" rx="2"></rect><path d="M8 7V4h8v3"></path></svg>';
const String _navProfile =
    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round">'
    '<circle cx="12" cy="8" r="4"></circle><path d="M4 21c1.5-4 4.5-6 8-6s6.5 2 8 6"></path></svg>';

/// 브랜드 관점 하단 메뉴. [current]: 0 발견, 1 관심, 2 대화, 3 협업, 4 프로필.
/// 다크에서는 켜진 칸이 라임이다.
Widget g1BottomNav(BuildContext context, int current) {
  final dark = G1Palette.of(context).dark;
  return DemoBottomNav(
    activeColor: dark ? g1Lime : null,
    items: [
      DemoNavItem(
        label: '발견',
        svg: _navFind,
        canvasFile: 'Main.dc.html',
        current: current == 0,
      ),
      DemoNavItem(
        label: '관심',
        svg: _navLike,
        canvasFile: 'Likes.dc.html',
        current: current == 1,
      ),
      DemoNavItem(
        label: '대화',
        svg: _navChat,
        canvasFile: 'Chat.dc.html',
        current: current == 2,
      ),
      DemoNavItem(
        label: '협업',
        svg: _navWork,
        canvasFile: 'Progress.dc.html',
        current: current == 3,
      ),
      DemoNavItem(
        label: '프로필',
        svg: _navProfile,
        canvasFile: 'Principles.dc.html',
        current: current == 4,
      ),
    ],
  );
}

/// 아래로 짙어지는 그라데이션 칸에 쓰는 도우미.
LinearGradient g1FadeDown(
  List<double> alphas, {
  List<double>? stops,
  Color base = const Color(0xFF17181C),
}) {
  return LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [for (final a in alphas) base.withValues(alpha: a)],
    stops: stops,
  );
}
