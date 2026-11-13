import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';

/// g9 화면(G1·G2·G3·F5·F6)이 함께 쓰는 색과 조각. 2026-11-12 캔버스의 라이트·다크 값을 그대로 옮겼다.
/// 다른 묶음 파일을 끌어 쓰지 않으려고 이 묶음 안에 따로 둔다.
class G9Palette {
  const G9Palette._({
    required this.dark,
    required this.bg,
    required this.text,
    required this.sub,
    required this.card,
    required this.line,
    required this.soft,
    required this.picked,
    required this.barNow,
  });

  static const G9Palette light = G9Palette._(
    dark: false,
    bg: Color(0xFFFFFFFF),
    text: Color(0xFF17181C),
    sub: Color(0xFF5C6068),
    card: Color(0xFFF8F9FA),
    line: Color(0xFFE6E8EB),
    soft: Color(0xFFF2F3F5),
    picked: Color(0xFFE3E5E9),
    barNow: Color(0xFF17181C),
  );

  static const G9Palette night = G9Palette._(
    dark: true,
    bg: Color(0xFF0F1012),
    text: Color(0xFFF2F3F5),
    sub: Color(0xFFA0A4AD),
    card: Color(0xFF1C1E22),
    line: Color(0xFF2A2D33),
    soft: Color(0xFF2A2D33),
    picked: Color(0xFF33363D),
    // 캔버스 다크의 "이번" 막대는 바탕색(#0F1012)을 그대로 쓴다.
    barNow: Color(0xFF0F1012),
  );

  final bool dark;
  final Color bg;
  final Color text;
  final Color sub;

  /// 카드·묶음 바탕(#F8F9FA / #1C1E22).
  final Color card;

  /// 구분선, 꺼진 확인 칸, 막대 길(#E6E8EB / #2A2D33).
  final Color line;

  /// 보조 큰 버튼 바탕(#F2F3F5 / #2A2D33).
  final Color soft;

  /// 고른 카드 바탕(#E3E5E9 / #33363D).
  final Color picked;

  /// 7일 결과의 "이번" 막대 색.
  final Color barNow;

  static const Color lime = Color(0xFFC6FF3D);
  static const Color limeInk = Color(0xFF1F2A00);

  /// 사진 위 글자(#FFFFFF)와 보조 글자(#E4E6EA).
  static const Color onPhoto = Color(0xFFFFFFFF);
  static const Color onPhotoSub = Color(0xFFE4E6EA);

  static G9Palette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? night : light;
}

/// 캔버스에 `line-height`가 없는 글은 CSS `normal`이다. Noto Sans KR은 hhea (1160 + 288) / 1000 = 1.448.
/// Flutter는 줄 높이를 비워 두면 글꼴의 다른 지표(약 1.6)를 써서 캔버스보다 커지므로 직접 정한다.
const double g9LineNormal = 1.448;

/// CSS처럼 줄 간격을 글줄 위아래에 고르게 나누는 글자 모양. [letterSpacing]은 em 값이다.
TextStyle g9Text(
  double size,
  Color color, {
  FontWeight weight = FontWeight.w400,
  double? height,
  double letterSpacing = 0,
  TextDecoration? decoration,
}) {
  return TextStyle(
    fontSize: size,
    color: color,
    fontWeight: weight,
    height: height ?? g9LineNormal,
    letterSpacing: letterSpacing * size,
    decoration: decoration,
    decorationColor: color,
    leadingDistribution: TextLeadingDistribution.even,
  );
}

const String g9BackSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M15 5l-7 7 7 7"></path></svg>';

/// 캔버스의 뒤로 링크(`aria-label="뒤로"`). 쌓인 화면이 있으면 닫고, 없으면 캔버스 링크([canvasFile])의 화면으로 새로 시작한다.
void g9Back(BuildContext context, String canvasFile) =>
    demoBack(context, fallback: canvasFile);

/// 위쪽 줄: `grid-template-columns: 60px 1fr 60px`, 높이 64, 좌우 8.
class G9Header extends StatelessWidget {
  const G9Header({
    super.key,
    required this.pal,
    required this.title,
    required this.onBack,
    this.right,
  });

  final G9Palette pal;
  final String title;
  final VoidCallback onBack;

  /// 오른쪽 칸(60px, 오른쪽 끝 맞춤). 없으면 빈 칸.
  final Widget? right;

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
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: DemoSvg(g9BackSvg, color: pal.text, size: 24),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: g9Text(16, pal.text, weight: FontWeight.w500),
                ),
              ),
            ),
            SizedBox(
              width: 60,
              child: Align(
                alignment: Alignment.centerRight,
                child: right ?? const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 둥근 큰 버튼. 높이 [height], 바탕·글자는 호출하는 쪽이 정한다.
class G9Button extends StatelessWidget {
  const G9Button({
    super.key,
    required this.label,
    required this.onTap,
    required this.background,
    required this.foreground,
    this.height = 58,
    this.size = 16,
    this.weight = FontWeight.w700,
    this.padding,
    this.leading,
  });

  /// 누를 수 없는 버튼(캔버스의 `disabled` 버튼).
  const G9Button.disabled({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.height = 58,
    this.size = 15,
    this.weight = FontWeight.w500,
  }) : onTap = null,
       padding = null,
       leading = null;

  final String label;
  final VoidCallback? onTap;
  final Color background;
  final Color foreground;
  final double height;
  final double size;
  final FontWeight weight;
  final EdgeInsetsGeometry? padding;

  /// 글자 앞 아이콘(8px 간격).
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      textAlign: TextAlign.center,
      style: g9Text(size, foreground, weight: weight),
    );
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
        child: leading == null
            ? text
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [leading!, const SizedBox(width: 8), text],
              ),
      ),
    );
  }
}

/// 사진 칸 아래쪽의 어두운 번짐(`linear-gradient(180deg, rgba(23,24,28,0), rgba(23,24,28,a))`).
class G9PhotoShade extends StatelessWidget {
  const G9PhotoShade({
    super.key,
    required this.height,
    required this.colors,
    this.stops,
  });

  final double height;
  final List<Color> colors;
  final List<double>? stops;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: height,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: colors,
              stops: stops,
            ),
          ),
        ),
      ),
    );
  }
}

/// 사진 위 왼쪽 위 알약(`rgba(255,255,255,0.92)` 바탕, 12px 500).
class G9PhotoChip extends StatelessWidget {
  const G9PhotoChip(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 14,
      top: 14,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(255, 255, 255, 0.92),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: g9Text(12, const Color(0xFF17181C), weight: FontWeight.w500),
        ),
      ),
    );
  }
}
