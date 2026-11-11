import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';

/// g5 화면(A2~A5, A9)이 함께 쓰는 색과 조각. artifact의 라이트·다크 값을 그대로 옮겼다.
class G5Palette {
  const G5Palette._({
    required this.dark,
    required this.bg,
    required this.text,
    required this.sub,
    required this.card,
    required this.track,
    required this.fill,
    required this.pillBg,
  });

  static const G5Palette light = G5Palette._(
    dark: false,
    bg: Color(0xFFFFFFFF),
    text: Color(0xFF17181C),
    sub: Color(0xFF5C6068),
    card: Color(0xFFF8F9FA),
    track: Color(0xFFE6E8EB),
    fill: Color(0xFF17181C),
    pillBg: Color(0xFFFFFFFF),
  );

  static const G5Palette night = G5Palette._(
    dark: true,
    bg: Color(0xFF0F1012),
    text: Color(0xFFF2F3F5),
    sub: Color(0xFFA0A4AD),
    card: Color(0xFF1C1E22),
    track: Color(0xFF2A2D33),
    // artifact 다크의 진행 막대 채움색 그대로(#0F1012).
    fill: Color(0xFF0F1012),
    pillBg: Color(0xFFF2F3F5),
  );

  final bool dark;
  final Color bg;
  final Color text;
  final Color sub;
  final Color card;
  final Color track;
  final Color fill;
  final Color pillBg;

  static const Color lime = Color(0xFFC6FF3D);
  static const Color limeInk = Color(0xFF1F2A00);
  static const Color ink = Color(0xFF17181C);

  static G5Palette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? night : light;
}

/// CSS처럼 줄 간격을 글줄 위아래에 고르게 나누는 글자 모양.
TextStyle g5Text(
  double size,
  Color color, {
  FontWeight weight = FontWeight.w400,
  double? height,
  double letterSpacing = 0,
}) {
  return TextStyle(
    fontSize: size,
    color: color,
    fontWeight: weight,
    height: height,
    letterSpacing: letterSpacing * size,
    leadingDistribution: TextLeadingDistribution.even,
  );
}

const String _backSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M15 5l-7 7 7 7"></path></svg>';

/// 위쪽 줄: `grid-template-columns: 60px 1fr 60px`, 높이 64, 좌우 8.
class G5Header extends StatelessWidget {
  const G5Header({
    super.key,
    required this.pal,
    required this.center,
    required this.right,
    required this.onBack,
    this.backOpacity = 1,
  });

  final G5Palette pal;
  final Widget center;
  final String right;
  final VoidCallback onBack;
  final double backOpacity;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onBack,
                  child: Opacity(
                    opacity: backOpacity,
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: DemoSvg(_backSvg, color: pal.text, size: 24),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(child: Center(child: center)),
            SizedBox(
              width: 60,
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(right, style: g5Text(13, pal.sub)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 가운데 알약. 라이트는 흰 바탕과 그림자, 다크는 밝은 바탕에 그림자 없음.
class G5Pill extends StatelessWidget {
  const G5Pill({
    super.key,
    required this.pal,
    required this.child,
    this.padding,
  });

  final G5Palette pal;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: pal.pillBg,
        borderRadius: BorderRadius.circular(999),
        boxShadow: pal.dark
            ? null
            : const [
                BoxShadow(
                  color: Color.fromRGBO(23, 24, 28, 0.10),
                  offset: Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
      ),
      child: DefaultTextStyle.merge(
        style: g5Text(13, G5Palette.ink, weight: FontWeight.w500),
        child: child,
      ),
    );
  }
}

/// 단계 막대: 좌우 16, 높이 4.
class G5Progress extends StatelessWidget {
  const G5Progress({super.key, required this.pal, required this.fraction});

  final G5Palette pal;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Container(
          height: 4,
          color: pal.track,
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: fraction,
            child: Container(height: 4, color: pal.fill),
          ),
        ),
      ),
    );
  }
}

/// 둥근 큰 버튼(높이 58). 바탕·글자·굵기는 호출하는 쪽이 정한다.
class G5BigButton extends StatelessWidget {
  const G5BigButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.background,
    required this.foreground,
    this.size = 16,
    this.weight = FontWeight.w700,
  });

  final String label;
  final VoidCallback onTap;
  final Color background;
  final Color foreground;
  final double size;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label, style: g5Text(size, foreground, weight: weight)),
      ),
    );
  }
}
