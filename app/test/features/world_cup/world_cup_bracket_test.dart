import 'dart:math';

import 'package:cora/features/world_cup/domain/world_cup_bracket.dart';
import 'package:flutter_test/flutter_test.dart';

List<String> _people(int n) => [for (var i = 1; i <= n; i++) 'p$i'];

/// 매번 대결의 첫째 칸(`a`)을 고른다.
void _playPickingA(WorldCupBracket<String> bracket) {
  while (!bracket.finished) {
    bracket.pick(bracket.match.a);
  }
}

void main() {
  group('WorldCupBracket', () {
    test(
      'plays four candidates in two semifinals and a final and ends with one champion',
      () {
        final bracket = WorldCupBracket<String>.start(
          _people(4),
          size: 4,
          random: Random(1),
        );
        var matches = 0;
        while (!bracket.finished) {
          bracket.pick(bracket.match.b);
          matches++;
        }
        // 4명이면 준결승 둘과 결승 하나로 세 번 겨룬다.
        expect(matches, 3);
        expect(bracket.finished, isTrue);
        expect(bracket.participants, contains(bracket.champion));
        // 우승자는 한 명이고, 마지막 대결을 이긴 사람이다.
        expect(bracket.champion, isNotEmpty);
      },
    );

    test('plays eight candidates in four quarterfinals first', () {
      final bracket = WorldCupBracket<String>.start(
        _people(8),
        size: 8,
        random: Random(2),
      );
      final labels = <String>[];
      while (!bracket.finished) {
        labels.add(bracket.roundLabel);
        bracket.pick(bracket.match.a);
      }
      expect(labels, [
        '8강 · 1 / 4',
        '8강 · 2 / 4',
        '8강 · 3 / 4',
        '8강 · 4 / 4',
        '4강 · 1 / 2',
        '4강 · 2 / 2',
        '결승 · 1 / 1',
      ]);
    });

    test('labels rounds 8강 · 1 / 4, 4강 · 1 / 2 and 결승 · 1 / 1', () {
      final four = WorldCupBracket<String>.start(
        _people(4),
        size: 4,
        random: Random(3),
      );
      expect(four.roundLabel, '4강 · 1 / 2');
      four.pick(four.match.a);
      expect(four.roundLabel, '4강 · 2 / 2');
      four.pick(four.match.a);
      expect(four.roundLabel, '결승 · 1 / 1');

      final eight = WorldCupBracket<String>.start(
        _people(8),
        size: 8,
        random: Random(3),
      );
      expect(eight.roundLabel, '8강 · 1 / 4');
    });

    test(
      'draws exactly size candidates at random from a larger saved list',
      () {
        final saved = _people(12);
        final bracket = WorldCupBracket<String>.start(
          saved,
          size: 8,
          random: Random(42),
        );
        expect(bracket.size, 8);
        expect(bracket.participants, hasLength(8));
        expect(bracket.participants.toSet(), hasLength(8));
        expect(saved, containsAll(bracket.participants));

        // 같은 시드면 같은 사람들이 뽑히고, 시드가 다르면 달라질 수 있다(저장 순서대로 앞 8명이 아니다).
        final again = WorldCupBracket<String>.start(
          saved,
          size: 8,
          random: Random(42),
        );
        expect(again.participants, bracket.participants);
        final picks = {
          for (var seed = 0; seed < 20; seed++)
            WorldCupBracket<String>.start(
              saved,
              size: 4,
              random: Random(seed),
            ).participants.join(','),
        };
        expect(picks.length, greaterThan(1));
        // 저장한 목록은 건드리지 않는다.
        expect(saved, _people(12));
      },
    );

    test('uses every saved candidate when exactly size are saved', () {
      final bracket = WorldCupBracket<String>.start(
        _people(4),
        size: 4,
        random: Random(7),
      );
      expect(bracket.participants.toSet(), _people(4).toSet());
    });

    test('throws when fewer saved than size', () {
      expect(
        () => WorldCupBracket<String>.start(
          _people(7),
          size: 8,
          random: Random(1),
        ),
        throwsArgumentError,
      );
      expect(
        () => WorldCupBracket<String>.start(
          _people(3),
          size: 4,
          random: Random(1),
        ),
        throwsArgumentError,
      );
    });

    test('throws when size is neither four nor eight', () {
      expect(
        () => WorldCupBracket<String>.start(
          _people(10),
          size: 6,
          random: Random(1),
        ),
        throwsArgumentError,
      );
    });

    test('lists the semifinalists except the champion', () {
      final four = WorldCupBracket<String>.start(
        _people(4),
        size: 4,
        random: Random(5),
      );
      _playPickingA(four);
      expect(four.semifinalists, hasLength(3));
      expect(four.semifinalists, isNot(contains(four.champion)));
      expect({...four.semifinalists, four.champion}, four.participants.toSet());

      final eight = WorldCupBracket<String>.start(
        _people(8),
        size: 8,
        random: Random(5),
      );
      _playPickingA(eight);
      // 8강에서 이긴 네 명이 4강 진출자다. 우승자를 뺀 세 명이 남는다.
      expect(eight.semifinalists, hasLength(3));
      expect(eight.semifinalists, isNot(contains(eight.champion)));
      expect(eight.participants, containsAll(eight.semifinalists));
    });

    test('rejects a winner who is not in the current match', () {
      final bracket = WorldCupBracket<String>.start(
        _people(4),
        size: 4,
        random: Random(1),
      );
      final outsider = bracket.participants.firstWhere(
        (p) => p != bracket.match.a && p != bracket.match.b,
      );
      expect(() => bracket.pick(outsider), throwsArgumentError);
      expect(() => bracket.pick('stranger'), throwsArgumentError);
    });

    test('refuses to answer the champion before the final is played', () {
      final bracket = WorldCupBracket<String>.start(
        _people(4),
        size: 4,
        random: Random(1),
      );
      expect(bracket.finished, isFalse);
      expect(() => bracket.champion, throwsStateError);
      expect(() => bracket.semifinalists, throwsStateError);
      _playPickingA(bracket);
      expect(() => bracket.pick(bracket.participants.first), throwsStateError);
      expect(() => bracket.match, throwsStateError);
    });
  });
}
