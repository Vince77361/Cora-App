import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';

/// g6 화면이 함께 쓰는 색·글자·머리글. artifact의 라이트/다크 파일 값을 그대로 옮겼다.
class G6Palette {
  const G6Palette._(this.dark);

  factory G6Palette.of(BuildContext context) =>
      G6Palette._(Theme.of(context).brightness == Brightness.dark);

  final bool dark;

  Color get bg => dark ? const Color(0xFF0F1012) : const Color(0xFFFFFFFF);
  Color get text => dark ? const Color(0xFFF2F3F5) : const Color(0xFF17181C);
  Color get sub => dark ? const Color(0xFFA0A4AD) : const Color(0xFF5C6068);
  Color get card => dark ? const Color(0xFF1C1E22) : const Color(0xFFF8F9FA);
  Color get line => dark ? const Color(0xFF2A2D33) : const Color(0xFFE6E8EB);

  /// 고른 칸(알약·카드)의 바탕과 글자.
  Color get selBg => dark ? const Color(0xFFF2F3F5) : const Color(0xFFE3E5E9);
  Color get selFg => dark ? const Color(0xFF0F1012) : const Color(0xFF17181C);
  Color get unselBg => card;
  Color get unselFg => text;

  static const lime = Color(0xFFC6FF3D);
  static const onLime = Color(0xFF1F2A00);
}

/// CSS `letter-spacing: -0.04em`는 [ls]에 -0.04를, `line-height: 1.3`은 [height]에 1.3을 넣는다.
TextStyle g6Text(
  double size,
  Color color, {
  FontWeight weight = FontWeight.w400,
  double ls = 0,
  double? height,
}) {
  return TextStyle(
    fontSize: size,
    color: color,
    fontWeight: weight,
    letterSpacing: ls * size,
    height: height,
  );
}

const String g6BackSvg =
    '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M15 5l-7 7 7 7"></path></svg>';

const String g6CloseSvg =
    '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"><path d="M6 6l12 12M18 6L6 18"></path></svg>';

const String g6LogoSvg =
    '<svg viewBox="0 0 26 26" fill="none" stroke="currentColor" stroke-width="3"><circle cx="9.5" cy="13" r="6.5"></circle><circle cx="16.5" cy="13" r="6.5" stroke="#C6FF3D"></circle></svg>';

/// 44×44 누르는 칸 안의 아이콘(뒤로·닫기).
class G6IconButton extends StatelessWidget {
  const G6IconButton({
    super.key,
    required this.svg,
    required this.color,
    required this.size,
    required this.onTap,
  });

  final String svg;
  final Color color;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: DemoSvg(svg, color: color, size: size),
        ),
      ),
    );
  }
}

/// 가운데 제목이 있는 머리글: grid 60px 1fr 60px, padding 0 8.
class G6Header extends StatelessWidget {
  const G6Header({
    super.key,
    required this.title,
    required this.fallback,
    this.height = 56,
  });

  final String title;

  /// 쌓인 화면이 없을 때 뒤로 가는 캔버스 화면(`NStoreHome.dc.html`).
  final String fallback;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = G6Palette.of(context);
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: Align(
                alignment: Alignment.centerLeft,
                child: G6IconButton(
                  svg: g6BackSvg,
                  color: p.text,
                  size: 24,
                  onTap: () => demoBack(context, fallback: fallback),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  title,
                  style: g6Text(16, p.text, weight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(width: 60),
          ],
        ),
      ),
    );
  }
}

/// 화면 아래에 붙는 한 줄 버튼 영역(padding 0 16 32).
class G6BottomBar extends StatelessWidget {
  const G6BottomBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: child,
      ),
    );
  }
}

/// 둥근 큰 버튼(높이 58, 999 모서리).
class G6PillButton extends StatelessWidget {
  const G6PillButton({
    super.key,
    required this.label,
    required this.bg,
    required this.fg,
    required this.onTap,
    this.weight = FontWeight.w700,
    this.size = 16,
    this.height = 58,
  });

  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback? onTap;
  final FontWeight weight;
  final double size;
  final double height;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label, style: g6Text(size, fg, weight: weight)),
      ),
    );
  }
}

/// 숫자에 천 단위 쉼표를 붙이고 '원'을 이어 붙인다(`toLocaleString('ko-KR') + '원'`).
String g6Won(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return '$buf원';
}
