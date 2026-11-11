import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/core/theme/cora_motion.dart';
import 'package:cora/core/theme/cora_shapes.dart';
import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/core/ui/cora_primary_button.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/cora_test_app.dart';

BoxDecoration _decoration(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find.descendant(
      of: find.byType(CoraPrimaryButton),
      matching: find.byType(DecoratedBox),
    ),
  );
  return box.decoration as BoxDecoration;
}

TextStyle _labelStyle(WidgetTester tester, String label) =>
    tester.renderObject<RenderParagraph>(find.text(label)).text.style!;

/// 화면에 실제로 그려진 너비 ÷ 배치 너비. 누르는 동안 1보다 작다.
double _scale(WidgetTester tester) {
  final surface = find.descendant(
    of: find.byType(CoraPrimaryButton),
    matching: find.byType(DecoratedBox),
  );
  return tester.getRect(surface).width / tester.getSize(surface).width;
}

void main() {
  testWidgets('primary button is 58 tall and calls onPressed', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      coraTestApp(CoraPrimaryButton(label: '다음', onPressed: () => taps++)),
    );

    expect(tester.getSize(find.byType(CoraPrimaryButton)).height, 58);
    await tester.tap(find.byType(CoraPrimaryButton));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets(
    'primary button is a pill in primaryAction with a bold 16 label',
    (tester) async {
      await tester.pumpWidget(
        coraTestApp(CoraPrimaryButton(label: '다음', onPressed: () {})),
      );

      final c = CoraColors.light;
      final decoration = _decoration(tester);
      expect(decoration.color, c.primaryAction);
      expect(decoration.borderRadius, BorderRadius.circular(CoraRadius.pill));
      final style = _labelStyle(tester, '다음');
      expect(style.color, c.onPrimaryAction);
      expect(style.fontSize, 16);
      expect(style.fontWeight, FontWeight.w700);
    },
  );

  testWidgets('primary button label is 500 in dark and 700 in light', (
    tester,
  ) async {
    for (final (theme, weight) in [
      (coraLightTheme, FontWeight.w700),
      (coraDarkTheme, FontWeight.w500),
    ]) {
      await tester.pumpWidget(
        coraTestApp(
          CoraPrimaryButton(label: '다음', onPressed: () {}),
          theme: theme,
        ),
      );
      await tester.pumpAndSettle();
      expect(_labelStyle(tester, '다음').fontWeight, weight);
      expect(_labelStyle(tester, '다음').fontSize, 16);
    }
  });

  testWidgets('primary button fills the available width', (tester) async {
    await tester.pumpWidget(
      coraTestApp(
        SizedBox(
          width: 358,
          child: CoraPrimaryButton(label: '다음', onPressed: () {}),
        ),
      ),
    );
    expect(tester.getSize(find.byType(CoraPrimaryButton)).width, 358);
  });

  testWidgets('primary button ignores taps when disabled', (tester) async {
    final semantics = tester.ensureSemantics();
    var taps = 0;
    var enabled = false;
    late StateSetter setState;
    await tester.pumpWidget(
      coraTestApp(
        StatefulBuilder(
          builder: (context, set) {
            setState = set;
            return CoraPrimaryButton(
              label: '다음',
              onPressed: enabled ? () => taps++ : null,
            );
          },
        ),
      ),
    );

    await tester.tap(find.byType(CoraPrimaryButton), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(taps, 0);
    expect(
      tester.getSemantics(find.byType(CoraPrimaryButton)),
      matchesSemantics(
        label: '다음',
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
      ),
    );

    // 같은 버튼이 다시 켜지면 눌린다.
    setState(() => enabled = true);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CoraPrimaryButton));
    await tester.pumpAndSettle();
    expect(taps, 1);
    semantics.dispose();
  });

  testWidgets('disabled primary button uses line with textSecondary', (
    tester,
  ) async {
    await tester.pumpWidget(
      coraTestApp(const CoraPrimaryButton(label: '다음', onPressed: null)),
    );
    expect(_decoration(tester).color, CoraColors.light.line);
    expect(_labelStyle(tester, '다음').color, CoraColors.light.textSecondary);

    await tester.pumpWidget(
      coraTestApp(
        const CoraPrimaryButton(label: '다음', onPressed: null),
        theme: coraDarkTheme,
      ),
    );
    await tester.pumpAndSettle();
    expect(_decoration(tester).color, CoraColors.dark.line);
    expect(_labelStyle(tester, '다음').color, CoraColors.dark.textSecondary);
  });

  testWidgets('primary button animates between enabled and disabled', (
    tester,
  ) async {
    Widget button(bool enabled) => coraTestApp(
      CoraPrimaryButton(label: '다음', onPressed: enabled ? () {} : null),
    );
    final c = CoraColors.light;
    await tester.pumpWidget(button(true));
    await tester.pumpWidget(button(false));
    await tester.pump(const Duration(milliseconds: 100));

    final mid = _decoration(tester).color!;
    expect(mid, isNot(c.primaryAction));
    expect(mid, isNot(c.line));

    await tester.pump(CoraMotion.stateDuration);
    expect(_decoration(tester).color, c.line);
  });

  testWidgets('primary button snaps to the new state when reducing motion', (
    tester,
  ) async {
    Widget button(bool enabled) => coraTestApp(
      CoraPrimaryButton(label: '다음', onPressed: enabled ? () {} : null),
      disableAnimations: true,
    );
    await tester.pumpWidget(button(true));
    await tester.pumpWidget(button(false));
    await tester.pump();
    expect(_decoration(tester).color, CoraColors.light.line);
  });

  testWidgets('primary button shrinks slightly while pressed without ink', (
    tester,
  ) async {
    await tester.pumpWidget(
      coraTestApp(CoraPrimaryButton(label: '다음', onPressed: () {})),
    );
    expect(
      find.descendant(
        of: find.byType(CoraPrimaryButton),
        matching: find.byType(InkWell),
      ),
      findsNothing,
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(CoraPrimaryButton)),
    );
    await tester.pump(kPressTimeout);
    await tester.pump(CoraMotion.pressDuration);
    expect(_scale(tester), moreOrLessEquals(CoraMotion.pressedScale));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(_scale(tester), 1);
  });

  testWidgets('disabled primary button does not react to presses', (
    tester,
  ) async {
    await tester.pumpWidget(
      coraTestApp(const CoraPrimaryButton(label: '다음', onPressed: null)),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(CoraPrimaryButton)),
    );
    await tester.pump(kPressTimeout);
    await tester.pump(CoraMotion.pressDuration);
    expect(_scale(tester), 1);
    await gesture.up();
  });

  group('accent look (E1, E2)', () {
    testWidgets('is the lime accent in light and dark', (tester) async {
      for (final (theme, c) in [
        (coraLightTheme, CoraColors.light),
        (coraDarkTheme, CoraColors.dark),
      ]) {
        await tester.pumpWidget(
          coraTestApp(
            CoraPrimaryButton(
              label: '확인',
              onPressed: () {},
              look: CoraPrimaryButtonLook.accent,
            ),
            theme: theme,
          ),
        );
        await tester.pumpAndSettle();
        expect(_decoration(tester).color, c.accent);
        final style = _labelStyle(tester, '확인');
        expect(style.color, c.onAccent);
        expect(style.fontWeight, FontWeight.w700);
      }
    });

    testWidgets('disabled is surface with a medium textSecondary label', (
      tester,
    ) async {
      for (final (theme, c) in [
        (coraLightTheme, CoraColors.light),
        (coraDarkTheme, CoraColors.dark),
      ]) {
        await tester.pumpWidget(
          coraTestApp(
            const CoraPrimaryButton(
              label: '6자리를 모두 넣어주세요',
              onPressed: null,
              look: CoraPrimaryButtonLook.accent,
            ),
            theme: theme,
          ),
        );
        await tester.pumpAndSettle();
        expect(_decoration(tester).color, c.surface);
        final style = _labelStyle(tester, '6자리를 모두 넣어주세요');
        expect(style.color, c.textSecondary);
        expect(style.fontSize, 16);
        expect(style.fontWeight, FontWeight.w500);
      }
    });
  });
}
