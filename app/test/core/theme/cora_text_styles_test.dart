import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/core/theme/cora_shadows.dart';
import 'package:cora/core/theme/cora_text_styles.dart';
import 'package:cora/core/theme/cora_theme.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 캔버스에 줄 높이가 없는 스타일은 CSS `line-height: normal`과 같은 1.448이다.
  const normal = 1.448;

  // 이름, 스타일, 글자 크기, 굵기, 자간(논리 픽셀), 줄 높이 배수.
  final expected = <(String, TextStyle, double, FontWeight, double, double)>[
    ('display', CoraTextStyles.display, 32, FontWeight.w900, -1.6, 1.25),
    ('title', CoraTextStyles.title, 26, FontWeight.w900, -1.17, 1.3),
    ('heading', CoraTextStyles.heading, 19, FontWeight.w700, -0.38, normal),
    ('bodyLarge', CoraTextStyles.bodyLarge, 16, FontWeight.w500, 0, normal),
    ('body', CoraTextStyles.body, 15, FontWeight.w400, 0, 1.6),
    ('label', CoraTextStyles.label, 13, FontWeight.w500, 0, normal),
    ('caption', CoraTextStyles.caption, 12, FontWeight.w500, 0, normal),
    ('button', CoraTextStyles.button, 16, FontWeight.w700, 0, normal),
  ];

  test('every text style pins family, size, weight, letterSpacing and height', () {
    for (final (name, s, size, weight, spacing, height) in expected) {
      expect(s.fontFamily, 'NotoSansKR', reason: name);
      expect(s.fontSize, size, reason: name);
      expect(s.fontWeight, weight, reason: name);
      expect(s.letterSpacing, isNotNull, reason: '$name letterSpacing');
      expect(s.letterSpacing, spacing, reason: name);
      expect(s.height, isNotNull, reason: '$name height');
      expect(s.height, height, reason: name);
      expect(
        s.leadingDistribution,
        TextLeadingDistribution.even,
        reason: '$name leadingDistribution',
      );
    }
  });

  test('shadow blur converts CSS blur to the Flutter blur radius', () {
    // CSS blur B는 시그마 B/2, Flutter blurRadius r은 시그마 0.57735*r+0.5다.
    expect(CoraShadows.blurRadiusFor(24), closeTo(19.92, 0.01));
    expect(CoraShadows.blurRadiusFor(40), closeTo(33.77, 0.01));
    expect(CoraShadows.blurRadiusFor(32), closeTo(26.85, 0.01));
    expect(CoraShadows.card.single.blurRadius, closeTo(19.92, 0.01));
    expect(CoraShadows.floating.single.blurRadius, closeTo(33.77, 0.01));
    expect(CoraShadows.sheet.single.blurRadius, closeTo(26.85, 0.01));
  });

  test('sheet shadow points upward', () {
    expect(CoraShadows.sheet.single.offset, const Offset(0, -12));
    expect(CoraShadows.card.single.offset, const Offset(0, 8));
    expect(CoraShadows.floating.single.offset, const Offset(0, 16));
  });

  test('both themes use NotoSansKR and carry CoraColors', () {
    expect(coraLightTheme.textTheme.bodyMedium!.fontFamily, 'NotoSansKR');
    expect(coraDarkTheme.extension<CoraColors>(), isNotNull);
  });
}
