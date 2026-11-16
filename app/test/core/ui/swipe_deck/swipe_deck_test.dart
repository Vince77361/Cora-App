import 'dart:async';

import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/core/ui/swipe_deck/swipe_deck.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Swipe = (String, SwipeOutcome);

Future<void> _pumpDeck(
  WidgetTester tester, {
  required List<String> items,
  required Future<void> Function(String, SwipeOutcome) onSwiped,
  VoidCallback? onTap,
  VoidCallback? onRejected,
  SwipeDeckController? controller,
  bool disableAnimations = false,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: coraLightTheme,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: 366,
              height: 680,
              child: SwipeDeck<String>(
                items: items,
                controller: controller,
                onTap: onTap,
                onRejected: onRejected,
                cardBuilder: (context, item) => Center(child: Text(item)),
                onSwiped: onSwiped,
                empty: const Center(child: Text('empty')),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('dragging past the threshold calls onSwiped once with like', (
    tester,
  ) async {
    final calls = <_Swipe>[];
    await _pumpDeck(
      tester,
      items: const ['A', 'B', 'C'],
      onSwiped: (item, outcome) async => calls.add((item, outcome)),
    );

    await tester.drag(find.text('A'), const Offset(200, 0));
    await tester.pumpAndSettle();

    expect(calls, [('A', SwipeOutcome.like)]);
    // 넘긴 카드는 사라지고 다음 카드가 맨 위로 온다.
    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('dragging left passes and dragging up holds', (tester) async {
    final calls = <_Swipe>[];
    await _pumpDeck(
      tester,
      items: const ['A', 'B', 'C'],
      onSwiped: (item, outcome) async => calls.add((item, outcome)),
    );

    await tester.drag(find.text('A'), const Offset(-200, 0));
    await tester.pumpAndSettle();
    await tester.drag(find.text('B'), const Offset(0, -240));
    await tester.pumpAndSettle();

    expect(calls, [('A', SwipeOutcome.pass), ('B', SwipeOutcome.hold)]);
    expect(find.text('C'), findsOneWidget);
  });

  testWidgets('a short drag springs back and calls nothing', (tester) async {
    var calls = 0;
    await _pumpDeck(
      tester,
      items: const ['A', 'B'],
      onSwiped: (item, outcome) async => calls++,
    );
    final home = tester.getCenter(find.text('A'));

    await tester.drag(find.text('A'), const Offset(60, 20));
    await tester.pumpAndSettle();

    expect(calls, 0);
    expect(tester.getCenter(find.text('A')).dx, closeTo(home.dx, 0.5));
    expect(tester.getCenter(find.text('A')).dy, closeTo(home.dy, 0.5));
  });

  testWidgets('a cancelled short drag springs back', (tester) async {
    var calls = 0;
    await _pumpDeck(
      tester,
      items: const ['A', 'B'],
      onSwiped: (item, outcome) async => calls++,
    );
    final home = tester.getCenter(find.text('A'));

    final gesture = await tester.startGesture(home);
    await gesture.moveBy(const Offset(60, 0));
    await tester.pump();
    await gesture.cancel();
    await tester.pumpAndSettle();

    expect(calls, 0);
    expect(tester.getCenter(find.text('A')).dx, closeTo(home.dx, 0.5));
  });

  testWidgets('ignores a second drag while the first card is flying out', (
    tester,
  ) async {
    final pending = Completer<void>();
    final calls = <_Swipe>[];
    await _pumpDeck(
      tester,
      items: const ['A', 'B', 'C'],
      onSwiped: (item, outcome) {
        calls.add((item, outcome));
        return pending.future;
      },
    );

    await tester.drag(find.text('A'), const Offset(200, 0));
    await tester.pump(const Duration(milliseconds: 100));
    // 날아가는 도중에 다른 끌기를 시도한다.
    await tester.dragFrom(const Offset(195, 400), const Offset(-250, 0));
    await tester.pump(const Duration(milliseconds: 400));
    // onSwiped가 끝나지 않았으므로 다음 카드도 넘길 수 없다.
    await tester.dragFrom(const Offset(195, 400), const Offset(-250, 0));
    await tester.pumpAndSettle();

    expect(calls, [('A', SwipeOutcome.like)]);

    pending.complete();
    await tester.pumpAndSettle();
    expect(find.text('B'), findsOneWidget);

    await tester.drag(find.text('B'), const Offset(-200, 0));
    await tester.pumpAndSettle();
    expect(calls, [('A', SwipeOutcome.like), ('B', SwipeOutcome.pass)]);
  });

  testWidgets('controller.swipe animates the same way as a drag', (
    tester,
  ) async {
    final controller = SwipeDeckController();
    addTearDown(controller.dispose);
    final calls = <_Swipe>[];
    await _pumpDeck(
      tester,
      items: const ['A', 'B'],
      controller: controller,
      onSwiped: (item, outcome) async => calls.add((item, outcome)),
    );
    final home = tester.getCenter(find.text('A'));
    expect(controller.busy, isFalse);

    final done = controller.swipe(SwipeOutcome.like);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 140));

    expect(controller.busy, isTrue);
    expect(tester.getCenter(find.text('A')).dx, greaterThan(home.dx + 50));
    expect(calls, isEmpty);

    // 날아가는 동안 또 부르면 무시한다.
    await controller.swipe(SwipeOutcome.pass);

    await tester.pumpAndSettle();
    await done;
    expect(calls, [('A', SwipeOutcome.like)]);
    expect(controller.busy, isFalse);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('returns the card when onSwiped throws', (tester) async {
    final controller = SwipeDeckController();
    addTearDown(controller.dispose);
    var attempts = 0;
    await _pumpDeck(
      tester,
      items: const ['A', 'B'],
      controller: controller,
      onSwiped: (item, outcome) async {
        attempts++;
        if (attempts == 1) throw StateError('network');
      },
    );
    final home = tester.getCenter(find.text('A'));

    await tester.drag(find.text('A'), const Offset(200, 0));
    await tester.pumpAndSettle();

    // 삼키지 않고 Flutter 오류로도 알린다.
    expect(tester.takeException(), isA<StateError>());
    expect(attempts, 1);
    expect(find.text('A'), findsOneWidget);
    expect(tester.getCenter(find.text('A')).dx, closeTo(home.dx, 0.5));
    expect(controller.busy, isFalse);

    // 같은 카드를 다시 넘길 수 있다.
    await tester.drag(find.text('A'), const Offset(200, 0));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets(
    'a rejected swipe returns the card quietly and then calls onRejected',
    (tester) async {
      final controller = SwipeDeckController();
      addTearDown(controller.dispose);
      var rejected = 0;
      var rejectedWhileBusy = true;
      var rejectedOffset = 0.0;
      await _pumpDeck(
        tester,
        items: const ['A', 'B'],
        controller: controller,
        onSwiped: (item, outcome) async => throw const SwipeRejected(),
        onRejected: () {
          rejected++;
          rejectedWhileBusy = controller.busy;
          rejectedOffset = tester.getCenter(find.text('A')).dx;
        },
      );
      final home = tester.getCenter(find.text('A'));

      await tester.drag(find.text('A'), const Offset(200, 0));
      await tester.pumpAndSettle();

      // 예상된 거절이라 Flutter 오류로 알리지 않는다. 카드가 제자리로 돌아온 뒤에 불린다.
      expect(tester.takeException(), isNull);
      expect(rejected, 1);
      expect(rejectedWhileBusy, isFalse);
      expect(rejectedOffset, closeTo(home.dx, 0.5));
      expect(find.text('A'), findsOneWidget);
      expect(tester.getCenter(find.text('A')).dx, closeTo(home.dx, 0.5));
    },
  );

  testWidgets('shows the empty widget after the last card', (tester) async {
    await _pumpDeck(
      tester,
      items: const ['A'],
      onSwiped: (item, outcome) async {},
    );
    expect(find.text('empty'), findsNothing);

    await tester.drag(find.text('A'), const Offset(200, 0));
    await tester.pumpAndSettle();

    expect(find.text('A'), findsNothing);
    expect(find.text('empty'), findsOneWidget);
  });

  testWidgets('shows the empty widget when there are no cards at all', (
    tester,
  ) async {
    await _pumpDeck(
      tester,
      items: const [],
      onSwiped: (item, outcome) async {},
    );
    expect(find.text('empty'), findsOneWidget);
  });

  testWidgets('tapping without dragging calls onTap', (tester) async {
    var taps = 0;
    var swipes = 0;
    await _pumpDeck(
      tester,
      items: const ['A', 'B'],
      onTap: () => taps++,
      onSwiped: (item, outcome) async => swipes++,
    );

    await tester.tap(find.text('A'));
    await tester.pumpAndSettle();

    expect(taps, 1);
    expect(swipes, 0);
  });

  testWidgets('a drag does not count as a tap', (tester) async {
    var taps = 0;
    await _pumpDeck(
      tester,
      items: const ['A', 'B'],
      onTap: () => taps++,
      onSwiped: (item, outcome) async {},
    );

    await tester.drag(find.text('A'), const Offset(200, 0));
    await tester.pumpAndSettle();

    expect(taps, 0);
  });

  testWidgets('the card behind sits at 96% and grows when the front leaves', (
    tester,
  ) async {
    await _pumpDeck(
      tester,
      items: const ['A', 'B'],
      onSwiped: (item, outcome) async {},
    );
    // 두 카드는 같은 크기의 상자 안에 있다. 뒤 카드 글자는 96% 크기 상자의 가운데다.
    final behindScale = tester
        .widget<Transform>(
          find
              .ancestor(of: find.text('B'), matching: find.byType(Transform))
              .first,
        )
        .transform
        .storage[0];
    expect(behindScale, closeTo(0.96, 1e-6));

    await tester.drag(find.text('A'), const Offset(200, 0));
    await tester.pumpAndSettle();

    final frontScale = tester
        .widget<Transform>(
          find
              .ancestor(of: find.text('B'), matching: find.byType(Transform))
              .first,
        )
        .transform
        .storage[0];
    expect(frontScale, closeTo(1, 1e-6));
  });

  testWidgets('does not move or save when animations are reduced', (
    tester,
  ) async {
    final calls = <_Swipe>[];
    await _pumpDeck(
      tester,
      items: const ['A', 'B'],
      disableAnimations: true,
      onSwiped: (item, outcome) async => calls.add((item, outcome)),
    );

    await tester.drag(find.text('A'), const Offset(200, 0));
    await tester.pumpAndSettle();

    expect(calls, [('A', SwipeOutcome.like)]);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('keeps hiding swiped cards when the parent rebuilds the list', (
    tester,
  ) async {
    await _pumpDeck(
      tester,
      items: const ['A', 'B', 'C'],
      onSwiped: (item, outcome) async {},
    );
    await tester.drag(find.text('A'), const Offset(200, 0));
    await tester.pumpAndSettle();

    // 부모가 새 목록 객체를 만들어 다시 그려도 넘긴 A는 돌아오지 않는다.
    await _pumpDeck(
      tester,
      items: ['A', 'B', 'C'],
      onSwiped: (item, outcome) async {},
    );
    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('works when the parent removes the swiped card meanwhile', (
    tester,
  ) async {
    final pending = Completer<void>();
    final items = ValueNotifier<List<String>>(['A', 'B', 'C']);
    addTearDown(items.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: coraLightTheme,
        home: Scaffold(
          body: SizedBox(
            width: 366,
            height: 680,
            child: ValueListenableBuilder<List<String>>(
              valueListenable: items,
              builder: (context, list, _) => SwipeDeck<String>(
                items: list,
                cardBuilder: (context, item) => Center(child: Text(item)),
                onSwiped: (item, outcome) {
                  items.value = [...items.value]..remove(item);
                  return pending.future;
                },
                empty: const Center(child: Text('empty')),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.drag(find.text('A'), const Offset(200, 0));
    await tester.pump(const Duration(milliseconds: 400));
    // 부모가 A를 지웠어도 B가 날아간 자리에서 나타나지 않는다.
    expect(tester.getCenter(find.text('B')).dx, closeTo(183, 1));

    pending.complete();
    await tester.pumpAndSettle();
    expect(find.text('B'), findsOneWidget);
    expect(find.text('A'), findsNothing);
  });

  testWidgets('keeps the card state when the back card becomes the top card', (
    tester,
  ) async {
    final created = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: coraLightTheme,
        home: Scaffold(
          body: SizedBox(
            width: 366,
            height: 680,
            child: SwipeDeck<String>(
              items: const ['A', 'B'],
              cardBuilder: (context, item) =>
                  _Probe(item, onCreate: created.add),
              onSwiped: (item, outcome) async {},
              empty: const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
    expect(created, unorderedEquals(['A', 'B']));

    await tester.drag(find.text('A'), const Offset(200, 0));
    await tester.pumpAndSettle();

    // B는 뒤에서 맨 위로 올라왔지만 상태를 새로 만들지 않았다(사진이 깜빡이지 않는다).
    expect(created, unorderedEquals(['A', 'B']));
    expect(find.text('B'), findsOneWidget);
  });
}

class _Probe extends StatefulWidget {
  const _Probe(this.label, {required this.onCreate});

  final String label;
  final void Function(String) onCreate;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    widget.onCreate(widget.label);
  }

  @override
  Widget build(BuildContext context) => Center(child: Text(widget.label));
}
