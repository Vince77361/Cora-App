import 'package:flutter/material.dart';

import '../../../core/theme/cora_colors.dart';
import '../shared/demo_ui.dart';

/// g3 화면이 함께 쓰는 색과 작은 위젯. artifact의 라이트·다크 값을 그대로 옮긴다.
class G3Palette {
  G3Palette.of(BuildContext context)
    : dark = Theme.of(context).brightness == Brightness.dark,
      _c = context.colors;

  final bool dark;
  final CoraColors _c;

  /// 화면 바탕: #FFFFFF / #0F1012
  Color get bg => _c.background;

  /// 기본 글자: #17181C / #F2F3F5
  Color get text => _c.text;

  /// 보조 글자: #5C6068 / #A0A4AD
  Color get sub => _c.textSecondary;

  /// 카드·칸 바탕: #F8F9FA / #1C1E22
  Color get card => _c.surface;

  Color get accent => _c.accent;
  Color get onAccent => _c.onAccent;

  /// 고른 칩·탭: #E3E5E9 / #F2F3F5
  Color get chipOn => dark ? const Color(0xFFF2F3F5) : const Color(0xFFE3E5E9);

  /// 고른 칩·탭 위 글자: #17181C / #0F1012
  Color get onChipOn =>
      dark ? const Color(0xFF0F1012) : const Color(0xFF17181C);

  /// 안 고른 칩 위 글자: #17181C / #F2F3F5
  Color get onChipOff => text;
}

const Color g3Ink = Color(0xFF17181C);

/// 글자 자간(`letter-spacing: -0.045em`)을 px로 바꾼다.
double g3Ls(double fontSize, double em) => fontSize * em;

const String g3BackSvg =
    '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M15 5l-7 7 7 7"></path></svg>';

const String g3CloseSvg =
    '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"><path d="M6 6l12 12M18 6L6 18"></path></svg>';

/// 머리글의 뒤로·닫기 버튼(44×44).
class G3HeaderButton extends StatelessWidget {
  const G3HeaderButton({
    super.key,
    required this.svg,
    required this.color,
    required this.label,
    required this.fallback,
  });

  final String svg;
  final Color color;
  final String label;

  /// 쌓인 화면이 없을 때 가는 캔버스 화면(`Retro.dc.html`).
  final String fallback;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => demoBack(context, fallback: fallback),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(child: DemoSvg(svg, color: color)),
        ),
      ),
    );
  }
}

/// 알약 모양 버튼(링크). 글자는 가운데.
class G3Pill extends StatelessWidget {
  const G3Pill({
    super.key,
    required this.label,
    required this.background,
    required this.color,
    required this.height,
    required this.fontSize,
    required this.fontWeight,
    required this.onTap,
    this.padding,
  });

  final String label;
  final Color background;
  final Color color;
  final double height;
  final double fontSize;
  final FontWeight fontWeight;
  final VoidCallback onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: height,
        padding: padding,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
          ),
        ),
      ),
    );
  }
}
