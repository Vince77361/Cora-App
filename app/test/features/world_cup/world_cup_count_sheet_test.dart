import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/features/world_cup/presentation/widgets/world_cup_count_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';

/// 버튼 `open`이 시트를 열고, 시트가 돌려준 값을 `result`에 적는다.
Future<ValueNotifier<Object?>> _pump(
  WidgetTester tester, {
  required int saved,
  ThemeData? theme,
  bool smallPhoneLargeText = false,
}) async {
  if (smallPhoneLargeText) {
    useSmallPhoneWithLargeText(tester);
  } else {
    useCanvasPhone(tester);
  }
  final result = ValueNotifier<Object?>('not asked');
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? coraLightTheme,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async {
                result.value = await showWorldCupCountSheet(
                  context,
                  savedCount: saved,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  setUpAll(loadAppFonts);

  group('WorldCupCountSheet', () {
    testWidgets('shows the canvas texts with the saved count', (tester) async {
      await _pump(tester, saved: 8);
      expect(find.text('몇 강으로 할까요?'), findsOneWidget);
      expect(find.text('저장한 8명 중에서 골라요. 우승한 분께 바로 제안할 수 있어요.'), findsOneWidget);
      expect(find.text('4강'), findsOneWidget);
      expect(find.text('4명이 겨뤄요'), findsOneWidget);
      expect(find.text('8강'), findsOneWidget);
      expect(find.text('8명이 겨뤄요'), findsOneWidget);
      expect(find.text('시작하기'), findsOneWidget);
      expect(find.text('닫기'), findsOneWidget);
    });

    testWidgets('starts with 4강 chosen and returns it from 시작하기', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final result = await _pump(tester, saved: 8);
      expect(_node(tester, 4), _option(4, selected: true));
      expect(_node(tester, 8), _option(8, selected: false));
      await tester.tap(find.text('시작하기'));
      await tester.pumpAndSettle();
      expect(result.value, 4);
      expect(find.text('몇 강으로 할까요?'), findsNothing);
      semantics.dispose();
    });

    testWidgets('returns 8 after choosing 8강 with eight or more saved', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final result = await _pump(tester, saved: 10);
      await tester.tap(find.text('8강'));
      await tester.pumpAndSettle();
      expect(_node(tester, 8), _option(8, selected: true));
      expect(_node(tester, 4), _option(4, selected: false));
      await tester.tap(find.text('시작하기'));
      await tester.pumpAndSettle();
      expect(result.value, 8);
      semantics.dispose();
    });

    testWidgets('disables 8강 below eight saved', (tester) async {
      final semantics = tester.ensureSemantics();
      final result = await _pump(tester, saved: 7);
      await tester.tap(find.text('8강'));
      await tester.pumpAndSettle();
      // 꺼진 선택은 눌러도 고르지 않는다. 4강이 그대로 골라져 있다.
      expect(_node(tester, 8), _option(8, selected: false, enabled: false));
      expect(_node(tester, 4), _option(4, selected: true));
      await tester.tap(find.text('시작하기'));
      await tester.pumpAndSettle();
      expect(result.value, 4);
      semantics.dispose();
    });

    testWidgets('returns nothing when 닫기 is pressed', (tester) async {
      final result = await _pump(tester, saved: 8);
      await tester.tap(find.text('닫기'));
      await tester.pumpAndSettle();
      expect(result.value, isNull);
      expect(find.text('몇 강으로 할까요?'), findsNothing);
    });

    testWidgets('uses the canvas tokens in light mode', (tester) async {
      await _pump(tester, saved: 8);
      final c = coraLightTheme.extension<CoraColors>()!;
      expect(_sheetColor(tester), c.background);
      expect(
        tester.widget<Text>(find.text('4명이 겨뤄요')).style?.color,
        c.textSecondary,
      );
    });

    testWidgets('uses the dark tokens in dark mode', (tester) async {
      await _pump(tester, saved: 8, theme: coraDarkTheme);
      final c = coraDarkTheme.extension<CoraColors>()!;
      expect(_sheetColor(tester), c.background);
      expect(c.background, const Color(0xFF0F1012));
      expect(
        tester.widget<Text>(find.text('4명이 겨뤄요')).style?.color,
        c.textSecondary,
      );
    });

    testWidgets('does not overflow at 1.3x', (tester) async {
      await _pump(tester, saved: 12, smallPhoneLargeText: true);
      expect(tester.takeException(), isNull);
      expect(find.text('시작하기'), findsOneWidget);
    });
  });
}

/// 선택 줄의 의미 정보(고른 상태, 켜짐 여부).
Matcher _option(int size, {required bool selected, bool enabled = true}) =>
    matchesSemantics(
      label: size == 4 ? '4강 4명이 겨뤄요' : '8강 8명이 겨뤄요',
      isSelected: selected,
      hasSelectedState: true,
      isButton: true,
      hasEnabledState: true,
      isEnabled: enabled,
      hasTapAction: enabled,
    );

SemanticsNode _node(WidgetTester tester, int size) =>
    tester.getSemantics(find.byKey(ValueKey('world-cup-size-$size')));

/// 시트 맨 뒤 바탕.
Color? _sheetColor(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find
        .ancestor(
          of: find.text('몇 강으로 할까요?'),
          matching: find.byType(DecoratedBox),
        )
        .last,
  );
  return (box.decoration as BoxDecoration).color;
}
