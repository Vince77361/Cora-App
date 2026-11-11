import 'package:flutter/material.dart';

/// g2 화면이 함께 쓰는 색. artifact의 라이트·다크 파일에서 같은 자리에 쓰인 값을 그대로 옮겼다.
class G2Palette {
  const G2Palette._(this.dark);

  factory G2Palette.of(BuildContext context) =>
      G2Palette._(Theme.of(context).brightness == Brightness.dark);

  final bool dark;

  static const lime = Color(0xFFC6FF3D);
  static const onLime = Color(0xFF1F2A00);
  static const photoGreen = Color(0xFF2E5B43);
  static const photoCream = Color(0xFFE8DDCB);

  Color get bg => dark ? const Color(0xFF0F1012) : const Color(0xFFFFFFFF);
  Color get text => dark ? const Color(0xFFF2F3F5) : const Color(0xFF17181C);
  Color get sub => dark ? const Color(0xFFA0A4AD) : const Color(0xFF5C6068);
  Color get card => dark ? const Color(0xFF1C1E22) : const Color(0xFFF8F9FA);
  Color get line => dark ? const Color(0xFF2A2D33) : const Color(0xFFE6E8EB);
}

/// `letter-spacing: -0.045em`처럼 em으로 적힌 자간을 글자 크기에 곱해 준다.
TextStyle g2Text(
  double size, {
  required Color color,
  FontWeight weight = FontWeight.w400,
  double? spacingEm,
  double? height,
  TextDecoration? decoration,
}) {
  return TextStyle(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: spacingEm == null ? null : size * spacingEm,
    height: height,
    decoration: decoration,
  );
}

/// 아이콘 SVG 문자열 모음(artifact 그대로).
abstract final class G2Icons {
  static const back =
      '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M15 5l-7 7 7 7"></path></svg>';
  static const close =
      '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"><path d="M6 6l12 12M18 6L6 18"></path></svg>';
  static const check =
      '<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3.4" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12l5 5 9-10"></path></svg>';
}
