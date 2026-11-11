import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/core/ui/cora_step_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/cora_test_app.dart';

void main() {
  testWidgets('header row is 64 tall with a 4px bar under it', (tester) async {
    await tester.pumpWidget(
      coraTestApp(
        SizedBox(
          width: 358,
          child: CoraStepHeader(
            pageLabel: '가게 등록',
            step: 1,
            total: 3,
            onBack: () {},
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(CoraStepHeader)).height, 68);
    expect(find.text('1 / 3'), findsOneWidget);
  });

  testWidgets('shows back, n / m and the progress bar but no title pill', (
    tester,
  ) async {
    await tester.pumpWidget(
      coraTestApp(
        SizedBox(
          width: 358,
          child: CoraStepHeader(
            pageLabel: '가게 등록',
            step: 2,
            total: 3,
            onBack: () {},
          ),
        ),
      ),
    );

    // 소유자가 가운데 화면 이름 알약을 뺐다(2026-11-12).
    expect(find.text('가게 등록'), findsNothing);
    expect(find.byType(CoraBackButton), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is FractionallySizedBox && w.widthFactor == 0.67,
      ),
      findsOneWidget,
    );

    // 뒤로 가기는 왼쪽, `n / m`은 오른쪽에 그대로 있다.
    final header = tester.getRect(find.byType(CoraStepHeader));
    final back = tester.getRect(find.byType(CoraBackButton));
    final count = tester.getRect(find.text('2 / 3'));
    expect(back.left, header.left + 8);
    expect(count.right, header.right - 16);
    expect(back.center.dy, header.top + 32);
    expect(count.center.dy, header.top + 32);
  });

  testWidgets(
    'keeps the page name as an invisible heading for screen readers',
    (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        coraTestApp(
          const CoraStepHeader(pageLabel: '가게 등록', step: 1, total: 3),
        ),
      );

      expect(find.bySemanticsLabel('가게 등록'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('가게 등록')),
        matchesSemantics(label: '가게 등록', isHeader: true),
      );
      handle.dispose();
    },
  );

  testWidgets('progress is the rounded percent of step over total', (
    tester,
  ) async {
    expect(
      const CoraStepHeader(pageLabel: 'a', step: 1, total: 3).progress,
      0.33,
    );
    expect(
      const CoraStepHeader(pageLabel: 'a', step: 2, total: 3).progress,
      0.67,
    );
    expect(const CoraStepHeader(pageLabel: 'a', step: 3, total: 3).progress, 1);
  });

  testWidgets('light bar uses the canvas colors', (tester) async {
    await tester.pumpWidget(
      coraTestApp(const CoraStepHeader(pageLabel: '가게 등록', step: 1, total: 3)),
    );
    final texts = tester.widgetList<Text>(find.byType(Text)).toList();
    expect(
      texts.firstWhere((t) => t.data == '1 / 3').style!.color,
      CoraColors.light.textSecondary,
    );
    final track = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((d) => d.decoration)
        .whereType<BoxDecoration>()
        .where((d) => d.color == const Color(0xFFE6E8EB));
    expect(track, isNotEmpty);
    expect(
      find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == const Color(0xFF17181C),
      ),
      findsOneWidget,
    );
  });

  testWidgets('dark fill is darker than the track', (tester) async {
    await tester.pumpWidget(
      coraTestApp(
        const CoraStepHeader(pageLabel: '가게 등록', step: 1, total: 3),
        theme: coraDarkTheme,
      ),
    );
    expect(
      find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == const Color(0xFF0F1012),
      ),
      findsOneWidget,
    );
  });

  testWidgets('back button calls onBack and is 44 x 44', (tester) async {
    var backs = 0;
    await tester.pumpWidget(
      coraTestApp(
        CoraStepHeader(
          pageLabel: '가게 등록',
          step: 2,
          total: 3,
          onBack: () => backs++,
        ),
      ),
    );

    expect(tester.getSize(find.byType(CoraBackButton)), const Size(44, 44));
    await tester.tap(find.byType(CoraBackButton));
    await tester.pumpAndSettle();
    expect(backs, 1);
  });

  testWidgets('without onBack there is no back button', (tester) async {
    await tester.pumpWidget(
      coraTestApp(const CoraStepHeader(pageLabel: '가게 등록', step: 1, total: 3)),
    );
    expect(find.byType(CoraBackButton), findsNothing);
  });

  testWidgets('dimmed back button is at 30 percent', (tester) async {
    await tester.pumpWidget(
      coraTestApp(
        CoraStepHeader(
          pageLabel: '오퍼',
          step: 1,
          total: 3,
          onBack: () {},
          backDimmed: true,
        ),
      ),
    );
    final opacity = tester.widget<Opacity>(
      find.descendant(
        of: find.byType(CoraBackButton),
        matching: find.byType(Opacity),
      ),
    );
    expect(opacity.opacity, 0.3);
  });

  testWidgets('does not overflow at 1.3x text and a long page label', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      coraTestApp(
        CoraStepHeader(
          pageLabel: '아주아주 긴 가게 이름을 가진 곳에게 보내는 오퍼',
          step: 2,
          total: 3,
          onBack: () {},
        ),
        textScaler: const TextScaler.linear(1.3),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
