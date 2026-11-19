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

/// 늘 위 카드를 골라 결승까지 간다. 같은 시드의 대진으로 우승자와 4강 진출자를 미리 구한다.
({WorldCupCandidate champion, List<WorldCupCandidate> semifinalists})
_expected({required int saved, required int size, required int seed}) {
  final bracket = WorldCupBracket<WorldCupCandidate>.start(
    wcCandidates(saved),
    size: size,
    random: Random(seed),
  );
  while (!bracket.finished) {
    bracket.pick(bracket.match.a);
  }
  return (champion: bracket.champion, semifinalists: bracket.semifinalists);
}

Future<void> _playToTheEnd(WidgetTester tester, int matches) async {
  for (var i = 0; i < matches; i++) {
    await tester.tap(find.byType(WorldCupCard).first);
    await tester.pumpAndSettle();
  }
}

void main() {
  setUpAll(loadAppFonts);

  group('WorldCupResultPage', () {
    testWidgets('shows 이상형 1위 with 다시 하기 and 제안하기', (tester) async {
      await pumpWorldCup(tester, saved: 4, size: 4, seed: 5);
      await _playToTheEnd(tester, 3);
      final expected = _expected(saved: 4, size: 4, seed: 5);

      expect(find.text('이상형 월드컵'), findsOneWidget);
      expect(find.text('이상형 1위'), findsOneWidget);
      expect(find.text(expected.champion.name), findsOneWidget);
      expect(find.text(expected.champion.headline!), findsOneWidget);
      expect(find.text(expected.champion.meta), findsOneWidget);
      expect(find.text('다시 하기'), findsOneWidget);
      expect(find.text('제안하기'), findsOneWidget);
      expect(find.bySemanticsLabel('닫기'), findsOneWidget);
    });

    testWidgets('lists the three other semifinalists under 4강까지 올랐던 후보', (
      tester,
    ) async {
      await pumpWorldCup(tester, saved: 9, size: 8, seed: 2);
      await _playToTheEnd(tester, 7);
      final expected = _expected(saved: 9, size: 8, seed: 2);

      expect(find.text('4강까지 올랐던 후보'), findsOneWidget);
      expect(expected.semifinalists, hasLength(3));
      for (final p in expected.semifinalists) {
        expect(find.text(p.name), findsOneWidget);
      }
      // 우승자는 큰 카드에만 한 번 나온다.
      expect(find.text(expected.champion.name), findsOneWidget);
    });

    testWidgets('restarts with the same size when 다시 하기 is pressed', (
      tester,
    ) async {
      await pumpWorldCup(tester, saved: 9, size: 8);
      await _playToTheEnd(tester, 7);
      await tester.tap(find.text('다시 하기'));
      await tester.pumpAndSettle();
      expect(find.text('8강 · 1 / 4'), findsOneWidget);
      expect(find.text('이상형 1위'), findsNothing);

      // 4강으로 한 번 더.
      await tester.tap(find.bySemanticsLabel('그만하기'));
      await tester.pumpAndSettle();
      expect(find.text('go start'), findsOneWidget);
    });

    testWidgets('restarts a four-candidate world cup at 4강 · 1 / 2', (
      tester,
    ) async {
      await pumpWorldCup(tester, saved: 6, size: 4);
      await _playToTheEnd(tester, 3);
      await tester.tap(find.text('다시 하기'));
      await tester.pumpAndSettle();
      expect(find.text('4강 · 1 / 2'), findsOneWidget);
    });

    testWidgets('sends the champion to 제안하기', (tester) async {
      final harness = await pumpWorldCup(tester, saved: 4, size: 4, seed: 7);
      await _playToTheEnd(tester, 3);
      final expected = _expected(saved: 4, size: 4, seed: 7);

      await tester.tap(find.text('제안하기'));
      await tester.pumpAndSettle();
      expect(harness.proposals.winners, [expected.champion]);
    });

    testWidgets('shows the notice the proposal flow returns', (tester) async {
      await pumpWorldCup(
        tester,
        saved: 4,
        size: 4,
        notice: const WorldCupNotice(message: '크리에이터에게 제안을 보냈어요.'),
      );
      await _playToTheEnd(tester, 3);
      await tester.tap(find.text('제안하기'));
      await tester.pump();
      expect(find.text('크리에이터에게 제안을 보냈어요.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(find.text('크리에이터에게 제안을 보냈어요.'), findsNothing);
    });

    testWidgets('returns to the saved box when 닫기 is pressed', (tester) async {
      await pumpWorldCup(tester, saved: 4, size: 4);
      await _playToTheEnd(tester, 3);
      await tester.tap(find.bySemanticsLabel('닫기'));
      await tester.pumpAndSettle();
      expect(find.text('go start'), findsOneWidget);
      expect(find.text('이상형 1위'), findsNothing);
    });

    testWidgets('uses the canvas tokens in light mode', (tester) async {
      await pumpWorldCup(tester, saved: 4, size: 4);
      await _playToTheEnd(tester, 3);
      final light = coraLightTheme.extension<CoraColors>()!;
      expect(_textColor(tester, '4강까지 올랐던 후보'), light.text);
      for (final name in _semifinalNames(tester)) {
        expect(_textColor(tester, name), light.textSecondary);
      }
    });

    testWidgets('uses the dark tokens in dark mode', (tester) async {
      await pumpWorldCup(tester, saved: 4, size: 4, theme: coraDarkTheme);
      await _playToTheEnd(tester, 3);
      final dark = coraDarkTheme.extension<CoraColors>()!;
      for (final name in _semifinalNames(tester)) {
        expect(_textColor(tester, name), dark.textSecondary);
      }
      expect(dark.textSecondary, const Color(0xFFA0A4AD));
    });

    testWidgets('does not overflow at 1.3x with long names', (tester) async {
      const longName = '아주아주 긴 활동 이름을 가진 크리에이터의 작은 취향 기록장';
      await pumpWorldCup(
        tester,
        smallPhoneLargeText: true,
        candidates: [
          for (var i = 1; i <= 4; i++)
            wcCandidate(
              i,
              name: '$longName $i',
              headline: '주말 아침 잔 하나로 바뀌는 식탁과 오래 쓰는 도구들에 관한 아주 긴 한 줄 소개',
              meta: '일상형 릴스와 맛집 리뷰와 라멘 기록 · 팔로워 1,234,567',
            ),
        ],
      );
      await _playToTheEnd(tester, 3);
      expect(tester.takeException(), isNull);
      expect(find.text('제안하기'), findsOneWidget);
    });
  });
}

Color? _textColor(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

/// 4강까지 올랐던 후보 줄에 보이는 이름(`크리에이터 n`) 가운데 큰 카드의 우승자를 뺀 것.
List<String> _semifinalNames(WidgetTester tester) {
  final all = [for (var i = 1; i <= 4; i++) '크리에이터 $i'];
  return [
    for (final name in all)
      if (find.text(name).evaluate().isNotEmpty &&
          tester
              .widgetList<WorldCupCard>(find.byType(WorldCupCard))
              .every((card) => card.candidate.name != name))
        name,
  ];
}
