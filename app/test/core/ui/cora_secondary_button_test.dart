import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/core/ui/cora_secondary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/cora_test_app.dart';

BoxDecoration _decoration(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find.descendant(
                of: find.byType(CoraSecondaryButton),
                matching: find.byType(DecoratedBox),
              ),
            )
            .decoration
        as BoxDecoration;

void main() {
  testWidgets('is a 58 tall pill that calls onPressed', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      coraTestApp(
        CoraSecondaryButton(label: '정보 고치기', onPressed: () => taps++),
      ),
    );

    expect(tester.getSize(find.byType(CoraSecondaryButton)).height, 58);
    expect(_decoration(tester).borderRadius, BorderRadius.circular(999));
    await tester.tap(find.byType(CoraSecondaryButton));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('surface tone: #F8F9FA light, #1C1E22 dark, 15px 500 label', (
    tester,
  ) async {
    for (final (theme, fill, ink) in [
      (coraLightTheme, const Color(0xFFF8F9FA), CoraColors.light.text),
      (coraDarkTheme, const Color(0xFF1C1E22), CoraColors.dark.text),
    ]) {
      await tester.pumpWidget(
        coraTestApp(
          CoraSecondaryButton(label: '정보 고치기', onPressed: () {}),
          theme: theme,
        ),
      );
      await tester.pumpAndSettle();
      expect(_decoration(tester).color, fill);
      final style = tester.widget<Text>(find.text('정보 고치기')).style!;
      expect(style.color, ink);
      expect(style.fontSize, 15);
      expect(style.fontWeight, FontWeight.w500);
    }
  });

  testWidgets('muted tone is #F2F3F5 with #17181C in light and dark', (
    tester,
  ) async {
    for (final theme in [coraLightTheme, coraDarkTheme]) {
      await tester.pumpWidget(
        coraTestApp(
          CoraSecondaryButton(
            label: '다시 만들기',
            onPressed: () {},
            tone: CoraSecondaryTone.muted,
          ),
          theme: theme,
        ),
      );
      await tester.pumpAndSettle();
      expect(_decoration(tester).color, const Color(0xFFF2F3F5));
      expect(
        tester.widget<Text>(find.text('다시 만들기')).style!.color,
        const Color(0xFF17181C),
      );
    }
  });

  testWidgets('does nothing when disabled', (tester) async {
    await tester.pumpWidget(
      coraTestApp(const CoraSecondaryButton(label: '정보 고치기', onPressed: null)),
    );
    await tester.tap(find.byType(CoraSecondaryButton), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.text('정보 고치기')).style!.color,
      CoraColors.light.textSecondary,
    );
  });

  testWidgets('does not overflow at 1.3x text on a small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      coraTestApp(
        const SizedBox(
          width: 160,
          child: CoraSecondaryButton(label: '정보 고치기 정보 고치기', onPressed: null),
        ),
        textScaler: const TextScaler.linear(1.3),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
