import 'package:flutter/material.dart';

import '../shared/demo_ui.dart';

/// g8 화면(F1~F4, F7, F8)이 함께 쓰는 색과 조각. 2026-11-12 캔버스의 라이트·다크 값을 그대로 옮겼다.
class G8Palette {
  const G8Palette._({
    required this.dark,
    required this.bg,
    required this.text,
    required this.sub,
    required this.card,
    required this.line,
    required this.fill,
    required this.raised,
    required this.button,
    required this.knob,
  });

  static const G8Palette light = G8Palette._(
    dark: false,
    bg: Color(0xFFFFFFFF),
    text: Color(0xFF17181C),
    sub: Color(0xFF5C6068),
    card: Color(0xFFF8F9FA),
    line: Color(0xFFE6E8EB),
    fill: Color(0xFF17181C),
    raised: Color(0xFFFFFFFF),
    button: Color(0xFFF2F3F5),
    knob: Color(0xFFFFFFFF),
  );

  static const G8Palette night = G8Palette._(
    dark: true,
    bg: Color(0xFF0F1012),
    text: Color(0xFFF2F3F5),
    sub: Color(0xFFA0A4AD),
    card: Color(0xFF1C1E22),
    line: Color(0xFF2A2D33),
    fill: Color(0xFFF2F3F5),
    raised: Color(0xFF2A2D33),
    button: Color(0xFF2A2D33),
    knob: Color(0xFF0F1012),
  );

  final bool dark;
  final Color bg;
  final Color text;
  final Color sub;

  /// 카드 바탕(#F8F9FA / #1C1E22).
  final Color card;

  /// 구분선·진행 막대 바탕·꺼진 스위치(#E6E8EB / #2A2D33).
  final Color line;

  /// 진행 막대 채움(#17181C / #F2F3F5).
  final Color fill;

  /// 카드 위에 올라온 칸: 고른 탭·고른 칩·꺼진 배지(#FFFFFF / #2A2D33).
  final Color raised;

  /// 보조 큰 버튼(#F2F3F5 / #2A2D33).
  final Color button;

  /// 스위치 손잡이(#FFFFFF / #0F1012).
  final Color knob;

  static const Color lime = Color(0xFFC6FF3D);
  static const Color limeInk = Color(0xFF1F2A00);
  static const Color ink = Color(0xFF17181C);

  static G8Palette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? night : light;
}

const double _normalLineHeight = 1.448;

/// CSS 글자 모양. 줄 높이를 정하지 않은 곳은 `line-height: normal`(Noto Sans KR의 1.448)이고, 줄 간격은
/// 글줄 위아래에 고르게 나눈다. [letterSpacing]은 글자 크기에 대한 비율(em).
TextStyle g8Text(
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
    height: height ?? _normalLineHeight,
    letterSpacing: letterSpacing * size,
    leadingDistribution: TextLeadingDistribution.even,
  );
}

const String g8BackSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M15 5l-7 7 7 7"></path></svg>';

/// 위쪽 줄: `grid-template-columns: 60px 1fr 60px`, 높이 64, 좌우 8.
/// [right]는 오른쪽 칸의 글자(`2 / 3`). 비우면 빈 칸.
class G8Header extends StatelessWidget {
  const G8Header({
    super.key,
    required this.pal,
    required this.center,
    required this.onBack,
    this.right,
  });

  final G8Palette pal;
  final Widget center;
  final VoidCallback onBack;
  final String? right;

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
                      child: DemoSvg(g8BackSvg, color: pal.text, size: 24),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(child: Center(child: center)),
            SizedBox(
              width: 60,
              child: right == null
                  ? null
                  : Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(right!, style: g8Text(13, pal.sub)),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 가운데 알약. 캔버스는 라이트·다크 모두 흰 바탕에 어두운 글자와 같은 그림자다.
class G8Pill extends StatelessWidget {
  const G8Pill(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(23, 24, 28, 0.10),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Text(
        label,
        style: g8Text(13, G8Palette.ink, weight: FontWeight.w500),
      ),
    );
  }
}

/// 단계 막대: 좌우 16, 높이 4.
class G8Progress extends StatelessWidget {
  const G8Progress({super.key, required this.pal, required this.fraction});

  final G8Palette pal;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Container(
          height: 4,
          color: pal.line,
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

/// 화면 아래에 붙는 버튼 줄: `left 0, right 0, bottom 0, padding 0 16 32`.
class G8BottomBar extends StatelessWidget {
  const G8BottomBar({super.key, required this.child});

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

/// 둥근 큰 버튼(높이 58). 바탕·글자·굵기는 호출하는 쪽이 정한다.
class G8BigButton extends StatelessWidget {
  const G8BigButton({
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
        child: Text(label, style: g8Text(size, foreground, weight: weight)),
      ),
    );
  }
}

/// 목록 한 줄: 왼쪽 이름(dt), 오른쪽 값(dd, 오른쪽 정렬). 글줄 바닥을 맞춘다.
///
/// 캔버스의 `display: flex; justify-content: space-between; gap: 12px` 줄을 그대로 옮긴다.
/// 두 칸이 한 줄에 다 들어가지 않으면 CSS flex는 글 길이에 비례해 둘 다 줄이므로, 글 길이를 재서
/// 같은 비율로 나눈다(값만 줄바꿈되고 이름은 그대로 두는 Row와 다르다).
class G8KeyValueRow extends StatelessWidget {
  const G8KeyValueRow({
    super.key,
    required this.pal,
    required this.term,
    required this.value,
    this.first = false,
    this.bold = false,
    this.padding = 10,
    this.valueSize = 15,
    this.gap = 12,
    this.divider = true,
  });

  final G8Palette pal;
  final String term;
  final String value;

  /// 첫 줄은 윗선이 없다.
  final bool first;
  final bool bold;
  final double padding;
  final double valueSize;
  final double gap;

  /// false면 줄 사이 선이 없다(F1의 조회수 수당 설명).
  final bool divider;

  static int _flexOf(BuildContext context, String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: DefaultTextStyle.of(context).style.merge(style),
      ),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final width = painter.width;
    painter.dispose();
    return (width * 100).round().clamp(1, 1 << 30);
  }

  @override
  Widget build(BuildContext context) {
    final termStyle = g8Text(13, pal.sub);
    final valueStyle = g8Text(
      valueSize,
      pal.text,
      weight: bold ? FontWeight.w700 : FontWeight.w500,
    );
    return Container(
      padding: EdgeInsets.symmetric(vertical: padding),
      decoration: BoxDecoration(
        border: Border(
          top: first || !divider
              ? BorderSide.none
              : BorderSide(color: pal.line),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Flexible(
            flex: _flexOf(context, term, termStyle),
            child: Text(term, style: termStyle),
          ),
          SizedBox(width: gap),
          Flexible(
            flex: _flexOf(context, value, valueStyle),
            child: Text(value, textAlign: TextAlign.right, style: valueStyle),
          ),
        ],
      ),
    );
  }
}

/// 숫자에 세 자리마다 쉼표를 넣고 `원`을 붙인다(`60,000원`).
String g8Won(int n) {
  final digits = n.toString();
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return '$out원';
}
