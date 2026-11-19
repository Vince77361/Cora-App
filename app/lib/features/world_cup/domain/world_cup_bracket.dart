import 'dart:math';

import 'world_cup_round.dart';

/// 이상형 월드컵의 대진. 저장한 사람 가운데 [size]명을 무작위로 뽑아 한 대결씩 고른다. 서버와 화면을 모르는 순수
/// 계산이다. 뽑는 데 쓰는 [Random]은 부르는 쪽이 넘긴다(시험은 고정 시드).
///
/// 대진은 뽑힌 차례대로 둘씩 묶는다. 이긴 사람이 다음 단계로 올라가고, 결승을 이기면 끝난다.
class WorldCupBracket<T> {
  /// [saved]에서 [size]명을 뽑아 시작한다. [size]는 `4` 또는 `8`이고 [saved]가 그보다 적으면 [ArgumentError]다.
  /// [saved] 목록 자체는 바꾸지 않는다.
  WorldCupBracket.start(
    List<T> saved, {
    required this.size,
    required Random random,
  }) : participants = _draw(saved, size, random) {
    _round = size == 8 ? WorldCupRound.quarterfinal : WorldCupRound.semifinal;
    _entrants = participants;
  }

  static const sizes = [4, 8];

  static List<T> _draw<T>(List<T> saved, int size, Random random) {
    if (!sizes.contains(size)) {
      throw ArgumentError.value(size, 'size', '4 또는 8이어야 해요.');
    }
    if (saved.length < size) {
      throw ArgumentError.value(saved.length, 'saved', '저장한 사람이 $size명보다 적어요.');
    }
    final pool = List<T>.of(saved)..shuffle(random);
    return List<T>.unmodifiable(pool.take(size));
  }

  /// 몇 강으로 시작했는가(`4` 또는 `8`).
  final int size;

  /// 뽑힌 사람들. 대진 차례대로다.
  final List<T> participants;

  /// 지금 단계에 올라온 사람들(대진 차례).
  late List<T> _entrants;
  late WorldCupRound _round;

  /// 지금 단계에서 이미 끝난 대결의 수.
  int _played = 0;
  final List<T> _winners = [];

  /// 4강에 오른 네 명. 4강으로 시작하면 처음 뽑힌 네 명이고, 8강으로 시작하면 8강의 승자들이다.
  List<T>? _semifinalists;
  T? _champion;
  bool _finished = false;

  bool get finished => _finished;

  /// 지금 단계.
  WorldCupRound get round => _round;

  /// 지금 단계에서 몇 번째 대결인가(1부터).
  int get matchNumber => _played + 1;

  /// 단계 글자(`4강 · 1 / 2`).
  String get roundLabel {
    _requireRunning();
    return _round.label(matchNumber);
  }

  /// 지금 겨루는 둘.
  ({T a, T b}) get match {
    _requireRunning();
    return (a: _entrants[_played * 2], b: _entrants[_played * 2 + 1]);
  }

  /// [winner]를 고른다. 지금 대결의 두 사람 가운데 하나여야 하고, 끝난 뒤에는 [StateError]다.
  void pick(T winner) {
    _requireRunning();
    final m = match;
    if (winner != m.a && winner != m.b) {
      throw ArgumentError.value(winner, 'winner', '지금 대결에 없는 사람이에요.');
    }
    _winners.add(winner);
    _played++;
    if (_played < _round.matches) return;

    if (_round == WorldCupRound.finalRound) {
      _champion = winner;
      _finished = true;
      return;
    }
    // 단계가 끝났다. 이긴 사람들이 다음 단계로 올라간다.
    _entrants = List<T>.of(_winners);
    _winners.clear();
    _played = 0;
    _round = _round == WorldCupRound.quarterfinal
        ? WorldCupRound.semifinal
        : WorldCupRound.finalRound;
    if (_round == WorldCupRound.semifinal) {
      _semifinalists = List<T>.of(_entrants);
    }
  }

  /// 우승자. 결승이 끝나기 전에는 [StateError]다.
  T get champion {
    _requireFinished();
    return _champion as T;
  }

  /// 우승자를 뺀 4강 진출자들(결과 화면의 `4강까지 올랐던 후보`).
  List<T> get semifinalists {
    _requireFinished();
    final all = _semifinalists ?? participants;
    return [
      for (final p in all)
        if (p != _champion) p,
    ];
  }

  void _requireRunning() {
    if (_finished) throw StateError('월드컵이 이미 끝났어요.');
  }

  void _requireFinished() {
    if (!_finished) throw StateError('아직 결승이 끝나지 않았어요.');
  }
}
