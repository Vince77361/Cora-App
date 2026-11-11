import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/core/theme/cora_shadows.dart';
import 'package:cora/core/theme/cora_text_styles.dart';
import 'package:cora/core/theme/cora_theme.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('display style matches the design canvas', () {
    const s = CoraTextStyles.display;
    expect(s.fontFamily, 'NotoSansKR');
    expect(s.fontSize, 32);
    expect(s.fontWeight, FontWeight.w900);
    expect(s.letterSpacing, -1.6);
    expect(s.height, 1.25);
  });

  test('body style matches the design canvas', () {
    const s = CoraTextStyles.body;
    expect(s.fontSize, 15);
    expect(s.fontWeight, FontWeight.w400);
    expect(s.letterSpacing, 0);
    expect(s.height, 1.6);
  });

  test('sheet shadow points upward', () {
    expect(CoraShadows.sheet.single.offset, const Offset(0, -12));
    expect(CoraShadows.sheet.single.blurRadius, 32);
    expect(CoraShadows.card.single.offset, const Offset(0, 8));
  });

  test('both themes use NotoSansKR and carry CoraColors', () {
    expect(coraLightTheme.textTheme.bodyMedium!.fontFamily, 'NotoSansKR');
    expect(coraDarkTheme.extension<CoraColors>(), isNotNull);
  });
}
