import 'dart:math';

import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/features/world_cup/domain/world_cup_bracket.dart';
import 'package:cora/features/world_cup/domain/world_cup_candidate.dart';
import 'package:cora/features/world_cup/presentation/widgets/world_cup_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';
import 'world_cup_fixtures.dart';

/// 화면에 올라온 두 후보(위, 아래 차례).
List<WorldCupCandidate> _shown(WidgetTester tester) => [
  for (final card in tester.widgetList<WorldCupCard>(find.byType(WorldCupCard)))
    card.candidate,
];

void main() {
  setUpAll(loadAppFonts);

  group('WorldCupMatchPage', () {
    testWidgets('shows the stage, the hint and two cards with the canvas '
        'texts', (tester) async {
      await pumpWorldCup(tester, saved: 4, size: 4);

      expect(find.text('이상형 월드컵'), findsOneWidget);
      expect(find.text('4강 · 1 / 2'), findsOneWidget);
      expect(find.text('더 마음에 드는 분을 골라요.'), findsOneWidget);
      expect(find.text('VS'), findsOneWidget);
      expect(find.text('이거보다 좋아'), findsNWidgets(2));
      final shown = _shown(tester);
      expect(shown, hasLength(2));
      for (final c in shown) {
        expect(find.text('저장 ${c.savedOrder}번째'), findsOneWidget);
        expect(find.text(c.name), findsOneWidget);
        expect(find.text(c.headline!), findsOneWidget);
        expect(find.text(c.meta), findsOneWidget);
      }
    });

    testWidgets('moves to the next match when a card is chosen', (
      tester,
    ) async {
      await pumpWorldCup(tester, saved: 4, size: 4, seed: 3);
      // 같은 시드로 같은 대진을 미리 만들어 누가 이기고 올라가는지 예상한다.
      final expected = WorldCupBracket<WorldCupCandidate>.start(
        wcCandidates(4),
        size: 4,
        random: Random(3),
      );
      final first = expected.match;
      expect(_shown(tester), [first.a, first.b]);

      await tester.tap(find.text(first.a.name));
      await tester.pumpAndSettle();
      expect(find.text('4강 · 2 / 2'), findsOneWidget);
      expect(_shown(tester), isNot([first.a, first.b]));

      expected.pick(first.a);
      final second = expected.match;
      expect(_shown(tester), [second.a, second.b]);
      await tester.tap(find.text(second.b.name));
      await tester.pumpAndSettle();
      expect(find.text('결승 · 1 / 1'), findsOneWidget);
      // 결승에는 두 준결승의 승자가 올라온다.
      expect(_shown(tester).toSet(), {first.a, second.b});
    });

    testWidgets('plays an eight-candidate world cup starting at 8강 · 1 / 4', (
      tester,
    ) async {
      await pumpWorldCup(tester, saved: 9, size: 8);
      expect(find.text('8강 · 1 / 4'), findsOneWidget);
      for (final label in ['8강 · 2 / 4', '8강 · 3 / 4', '8강 · 4 / 4']) {
        await tester.tap(find.byType(WorldCupCard).first);
        await tester.pumpAndSettle();
        expect(find.text(label), findsOneWidget);
      }
      await tester.tap(find.byType(WorldCupCard).first);
      await tester.pumpAndSettle();
      expect(find.text('4강 · 1 / 2'), findsOneWidget);
    });

    testWidgets('opens the result after the final', (tester) async {
      await pumpWorldCup(tester, saved: 4, size: 4);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byType(WorldCupCard).first);
        await tester.pumpAndSettle();
      }
      expect(find.text('이상형 1위'), findsOneWidget);
      expect(find.text('제안하기'), findsOneWidget);
    });

    testWidgets('returns without saving when 그만하기 is pressed', (tester) async {
      final harness = await pumpWorldCup(tester, saved: 4, size: 4);
      expect(find.bySemanticsLabel('그만하기'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('그만하기'));
      await tester.pumpAndSettle();

      expect(find.text('go start'), findsOneWidget);
      expect(find.text('이상형 월드컵'), findsNothing);
      expect(harness.proposals.winners, isEmpty);
    });

    testWidgets('uses the canvas tokens in light mode', (tester) async {
      await pumpWorldCup(tester);
      final c = coraLightTheme.extension<CoraColors>()!;
      expect(_textColor(tester, '더 마음에 드는 분을 골라요.'), c.textSecondary);
      expect(_textColor(tester, '4강 · 1 / 2'), c.textSecondary);
      expect(_vsCircleColor(tester), c.background);
    });

    testWidgets('uses the dark tokens in dark mode', (tester) async {
      await pumpWorldCup(tester, theme: coraDarkTheme);
      final c = coraDarkTheme.extension<CoraColors>()!;
      expect(_textColor(tester, '더 마음에 드는 분을 골라요.'), c.textSecondary);
      expect(_vsCircleColor(tester), c.background);
      expect(c.background, const Color(0xFF0F1012));
    });

    testWidgets('does not overflow at 1.3x with long names and headlines', (
      tester,
    ) async {
      const longName = '아주아주 긴 활동 이름을 가진 크리에이터의 작은 취향 기록장';
      const longHeadline = '주말 아침 잔 하나로 바뀌는 식탁과 오래 쓰는 도구들에 관한 아주 긴 한 줄 소개';
      await pumpWorldCup(
        tester,
        smallPhoneLargeText: true,
        candidates: [
          for (var i = 1; i <= 4; i++)
            wcCandidate(
              i,
              name: '$longName $i',
              headline: longHeadline,
              meta: '일상형 릴스와 맛집 리뷰와 라멘 기록 · 팔로워 1,234,567',
            ),
        ],
      );
      expect(tester.takeException(), isNull);
    });
  });
}

Color? _textColor(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

/// `VS` 동그라미의 바탕.
Color? _vsCircleColor(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find
        .ancestor(of: find.text('VS'), matching: find.byType(DecoratedBox))
        .first,
  );
  return (box.decoration as BoxDecoration).color;
}
