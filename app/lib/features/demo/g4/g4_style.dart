import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';

/// g4 화면들이 함께 쓰는 색·글씨·아이콘. artifact의 값을 그대로 옮겼다.
bool g4IsDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

class G4Colors {
  const G4Colors._(this.dark);

  factory G4Colors.of(BuildContext context) => G4Colors._(g4IsDark(context));

  final bool dark;

  static const lime = Color(0xFFC6FF3D);
  static const onLime = Color(0xFF1F2A00);
  static const ink = Color(0xFF17181C);
  static const photoBg = Color(0xFFD9DCE6);

  Color get bg => dark ? const Color(0xFF0F1012) : const Color(0xFFFFFFFF);
  Color get text => dark ? const Color(0xFFF2F3F5) : const Color(0xFF17181C);
  Color get sub => dark ? const Color(0xFFA0A4AD) : const Color(0xFF5C6068);
  Color get fill => dark ? const Color(0xFF1C1E22) : const Color(0xFFF8F9FA);
  Color get line => dark ? const Color(0xFF2A2D33) : const Color(0xFFE6E8EB);

  /// 로드 전 사진 칸 바탕(`#E6E8EB` / `#2A2D33`).
  Color get thumbBg => line;

  /// 켜진 알약 안내(탭 전환 등)의 바탕. 다크는 그림자 없이 밝은 알약이다.
  Color get pillOn => dark ? const Color(0xFFF2F3F5) : const Color(0xFFFFFFFF);
  Color get navActive => dark ? lime : ink;
}

TextStyle g4Style(
  double size, {
  FontWeight weight = FontWeight.w400,
  required Color color,
  double? em,
  double? height,
  TextDecoration? decoration,
  List<Shadow>? shadows,
}) {
  return TextStyle(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: em == null ? null : size * em,
    height: height,
    decoration: decoration ?? TextDecoration.none,
    decorationColor: color,
    shadows: shadows,
  );
}

/// CSS `filter: drop-shadow(0 2px 6px rgba(0,0,0,.55))`를 흉내 낸 아이콘.
class G4ShadowSvg extends StatelessWidget {
  const G4ShadowSvg(
    this.svg, {
    super.key,
    required this.color,
    required this.size,
  });

  final String svg;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final shadowSvg = svg.replaceAllMapped(
      RegExp(r'fill="#[0-9A-Fa-f]{6}"'),
      (_) => 'fill="#000000"',
    );
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Transform.translate(
          offset: const Offset(0, 2),
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Opacity(
              opacity: 0.55,
              child: DemoSvg(shadowSvg, color: Colors.black, size: size),
            ),
          ),
        ),
        DemoSvg(svg, color: color, size: size),
      ],
    );
  }
}

/// 하단 메뉴 아이콘(artifact 그대로).
abstract final class G4Icons {
  static const discover =
      '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round" aria-hidden="true"><rect x="6" y="3" width="12" height="17" rx="3"></rect><path d="M3 7v10M21 7v10"></path></svg>';
  static const heart =
      '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round" aria-hidden="true"><path d="M12 20s-7-4.4-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.6-7 10-7 10z"></path></svg>';
  static const chat =
      '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round" aria-hidden="true"><path d="M4 5h16v11H10l-6 4z"></path></svg>';
  static const work =
      '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round" aria-hidden="true"><rect x="3" y="7" width="18" height="13" rx="2"></rect><path d="M8 7V4h8v3"></path></svg>';
  static const person =
      '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="8" r="4"></circle><path d="M4 21c1.5-4 4.5-6 8-6s6.5 2 8 6"></path></svg>';
  static const home =
      '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round" aria-hidden="true"><path d="M4 10l8-6 8 6v10H4z"></path></svg>';
  static const plus =
      '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><path d="M12 5v14M5 12h14"></path></svg>';
  static const sparkle =
      '<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round" aria-hidden="true"><path d="M12 3l2 5 5 2-5 2-2 5-2-5-5-2 5-2z"></path></svg>';

  static const back =
      '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M15 5l-7 7 7 7"></path></svg>';
  static const close =
      '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" aria-hidden="true"><path d="M6 6l12 12M18 6L6 18"></path></svg>';
}

/// 상단 줄(`height: 56`, 좌우 8)의 뒤로·닫기 버튼 한 칸(44×44).
class G4HeaderButton extends StatelessWidget {
  const G4HeaderButton({
    super.key,
    required this.svg,
    required this.label,
    required this.size,
  });

  final String svg;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => demoBack(context),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: DemoSvg(svg, color: G4Colors.of(context).text, size: size),
          ),
        ),
      ),
    );
  }
}

/// 가운데 제목이 있는 상단 줄: `grid-template-columns: 60px 1fr 60px`.
class G4TitleHeader extends StatelessWidget {
  const G4TitleHeader({super.key, required this.title, required this.leading});

  final String title;
  final Widget leading;

  @override
  Widget build(BuildContext context) {
    final c = G4Colors.of(context);
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: Align(alignment: Alignment.centerLeft, child: leading),
            ),
            Expanded(
              child: Center(
                child: Text(
                  title,
                  style: g4Style(16, weight: FontWeight.w500, color: c.text),
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

/// 같은 크기의 사진 칸 여섯 개 격자(3열, 칸 사이 4, 모서리 14/4).
class G4CornerRadii {
  static BorderRadius forIndex(
    int i,
    int count, {
    double big = 14,
    double small = 4,
    int columns = 3,
  }) {
    final last = count - 1;
    final bottomLeft = last - (columns - 1);
    return BorderRadius.only(
      topLeft: Radius.circular(i == 0 ? big : small),
      topRight: Radius.circular(i == columns - 1 ? big : small),
      bottomLeft: Radius.circular(i == bottomLeft ? big : small),
      bottomRight: Radius.circular(i == last ? big : small),
    );
  }
}
