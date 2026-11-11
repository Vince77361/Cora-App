import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/core/ui/cora_step_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/cora_test_app.dart';

Finder _pill(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(DecoratedBox));

void main() {
  testWidgets('header row is 64 tall with a 4px bar under it', (tester) async {
    await tester.pumpWidget(
      coraTestApp(
        SizedBox(
          width: 358,
          child: CoraStepHeader(
            title: '가게 등록',
            step: 1,
            total: 3,
            onBack: () {},
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(CoraStepHeader)).height, 68);
    expect(find.text('가게 등록'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
  });

  testWidgets('progress is the rounded percent of step over total', (
    tester,
  ) async {
    expect(const CoraStepHeader(title: 'a', step: 1, total: 3).progress, 0.33);
    expect(const CoraStepHeader(title: 'a', step: 2, total: 3).progress, 0.67);
    expect(const CoraStepHeader(title: 'a', step: 3, total: 3).progress, 1);
  });

  testWidgets(
    'light pill is white with a shadow and the bar uses canvas colors',
    (tester) async {
      await tester.pumpWidget(
        coraTestApp(const CoraStepHeader(title: '가게 등록', step: 1, total: 3)),
      );
      final c = CoraColors.light;
      final pill =
          tester.widget<DecoratedBox>(_pill('가게 등록').first).decoration
              as BoxDecoration;
      expect(pill.color, const Color(0xFFFFFFFF));
      expect(pill.boxShadow, isNotEmpty);
      expect(pill.borderRadius, BorderRadius.circular(999));
      final texts = tester.widgetList<Text>(find.byType(Text)).toList();
      expect(
        texts.firstWhere((t) => t.data == '1 / 3').style!.color,
        c.textSecondary,
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
    },
  );

  testWidgets(
    'dark pill is light gray without a shadow and the fill is darker than the track',
    (tester) async {
      await tester.pumpWidget(
        coraTestApp(
          const CoraStepHeader(title: '가게 등록', step: 1, total: 3),
          theme: coraDarkTheme,
        ),
      );
      final pill =
          tester.widget<DecoratedBox>(_pill('가게 등록').first).decoration
              as BoxDecoration;
      expect(pill.color, const Color(0xFFF2F3F5));
      expect(pill.boxShadow!.single.color.a, 0);
      expect(
        find.byWidgetPredicate(
          (w) => w is ColoredBox && w.color == const Color(0xFF0F1012),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('back button calls onBack and is 44 x 44', (tester) async {
    var backs = 0;
    await tester.pumpWidget(
      coraTestApp(
        CoraStepHeader(
          title: '가게 등록',
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
      coraTestApp(const CoraStepHeader(title: '가게 등록', step: 1, total: 3)),
    );
    expect(find.byType(CoraBackButton), findsNothing);
  });

  testWidgets('dimmed back button is at 30 percent', (tester) async {
    await tester.pumpWidget(
      coraTestApp(
        CoraStepHeader(
          title: '오퍼',
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

  testWidgets('leading puts a 28px circle inside the pill', (tester) async {
    await tester.pumpWidget(
      coraTestApp(
        const CoraStepHeader(
          title: '하루 한 컵에게 오퍼',
          step: 1,
          total: 3,
          leading: ColoredBox(color: Colors.red, key: Key('lead')),
        ),
      ),
    );
    expect(tester.getSize(find.byKey(const Key('lead'))), const Size(28, 28));
  });

  testWidgets('does not overflow at 1.3x text and a long title', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      coraTestApp(
        CoraStepHeader(
          title: '아주아주 긴 가게 이름을 가진 곳에게 보내는 오퍼',
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
