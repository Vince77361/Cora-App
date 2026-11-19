import 'dart:math';

import 'package:cora/features/world_cup/presentation/viewmodels/world_cup_view_model.dart';
import 'package:cora/features/world_cup/presentation/world_cup_flow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'world_cup_fixtures.dart';

void main() {
  late ProviderContainer container;
  late WorldCupMatchArgs args;

  setUp(() {
    container = ProviderContainer(
      overrides: [worldCupRandomProvider.overrideWithValue(Random(1))],
    );
    addTearDown(container.dispose);
    args = WorldCupMatchArgs(
      saved: wcCandidates(4),
      size: 4,
      onPropose: ProposeLog().call,
    );
  });

  test('advances one match per pick and finishes after three', () {
    final provider = worldCupViewModelProvider(args);
    final vm = container.read(provider.notifier);
    for (var step = 0; step < 3; step++) {
      expect(container.read(provider).finished, isFalse);
      vm.pick(container.read(provider).bracket.match.a);
      expect(container.read(provider).step, step + 1);
    }
    expect(container.read(provider).finished, isTrue);
  });

  test('keeps the last match on the state once the final is played', () {
    final provider = worldCupViewModelProvider(args);
    final vm = container.read(provider.notifier);
    vm.pick(container.read(provider).bracket.match.a);
    vm.pick(container.read(provider).bracket.match.a);
    final last = container.read(provider).bracket.match;
    vm.pick(last.a);

    final state = container.read(provider);
    expect(state.finished, isTrue);
    expect(state.shown, last);
    expect(state.stage, '결승 · 1 / 1');
  });

  test('ignores a pick for someone who is not in the current match', () {
    final provider = worldCupViewModelProvider(args);
    final vm = container.read(provider.notifier);
    final match = container.read(provider).bracket.match;
    final outsider = wcCandidates(
      4,
    ).firstWhere((c) => c != match.a && c != match.b);
    vm.pick(outsider);
    expect(container.read(provider).step, 0);
  });

  test('ignores a late pick after the final', () {
    final provider = worldCupViewModelProvider(args);
    final vm = container.read(provider.notifier);
    for (var i = 0; i < 3; i++) {
      vm.pick(container.read(provider).bracket.match.a);
    }
    final champion = container.read(provider).bracket.champion;
    vm.pick(champion);
    expect(container.read(provider).step, 3);
    expect(container.read(provider).bracket.champion, champion);
  });

  test('draws a new line-up for every game even with the same people', () {
    final first = container.read(worldCupViewModelProvider(args));
    final again = WorldCupMatchArgs(
      saved: args.saved,
      size: args.size,
      onPropose: args.onPropose,
    );
    final second = container.read(worldCupViewModelProvider(again));
    expect(identical(first.bracket, second.bracket), isFalse);
  });
}
