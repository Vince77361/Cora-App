import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/core/ui/swipe_deck/swipe_card_frame.dart';
import 'package:cora/core/ui/swipe_deck/swipe_physics.dart';
import 'package:cora/core/ui/swipe_deck/swipe_stamp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {ThemeData? theme}) => MaterialApp(
  theme: theme ?? coraLightTheme,
  home: Scaffold(body: SizedBox(width: 366, height: 680, child: child)),
);

void main() {
  testWidgets('shows badge, name, title, price and tags from the canvas', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const SwipeCardFrame(
          photoUrl: null,
          badge: '운영자 추천 1 / 3',
          name: '서윤의 작은 취향',
          title: '출근 전 30초,\n오늘의 손목 루틴',
          priceLine: '30만 원',
          tags: ['얼굴출연없음', '소품'],
        ),
      ),
    );

    expect(find.text('운영자 추천 1 / 3'), findsOneWidget);
    expect(find.text('서윤의 작은 취향'), findsOneWidget);
    expect(find.text('출근 전 30초,\n오늘의 손목 루틴'), findsOneWidget);
    expect(find.text('30만 원'), findsOneWidget);
    expect(find.text('#얼굴출연없음'), findsOneWidget);
    expect(find.text('#소품'), findsOneWidget);
  });

  testWidgets('the price line uses the accent color', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const SwipeCardFrame(
          photoUrl: null,
          badge: 'b',
          name: 'n',
          title: 't',
          priceLine: '30만 원',
          tags: [],
        ),
      ),
    );
    final style = tester.widget<Text>(find.text('30만 원')).style!;
    expect(style.color, const Color(0xFFC6FF3D));
    expect(style.fontSize, 20);
  });

  testWidgets('clips to a 28 radius and wraps the photo in a Hero on request', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const SwipeCardFrame(
          photoUrl: null,
          badge: 'b',
          name: 'n',
          title: 't',
          priceLine: 'p',
          tags: [],
          heroTag: 'creator:1',
        ),
      ),
    );
    final clip = tester.widget<ClipRRect>(find.byType(ClipRRect).first);
    expect(clip.borderRadius, BorderRadius.circular(28));
    expect(find.byType(Hero), findsOneWidget);
  });

  testWidgets('has no Hero without a tag', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const SwipeCardFrame(
          photoUrl: null,
          badge: 'b',
          name: 'n',
          title: 't',
          priceLine: 'p',
          tags: [],
        ),
      ),
    );
    expect(find.byType(Hero), findsNothing);
  });

  testWidgets('stamps tilt 14 degrees outward and hold stays level', (
    tester,
  ) async {
    Future<double> angleOf(SwipeOutcome outcome) async {
      await tester.pumpWidget(_wrap(Center(child: SwipeStamp(outcome))));
      final box = tester.widget<Transform>(
        find.descendant(
          of: find.byType(SwipeStamp),
          matching: find.byType(Transform),
        ),
      );
      return box.transform.storage[1];
    }

    // 회전 행렬의 sin 값. like는 왼쪽으로 -14도, pass는 +14도다.
    expect(await angleOf(SwipeOutcome.like), closeTo(-0.2419, 1e-3));
    expect(await angleOf(SwipeOutcome.pass), closeTo(0.2419, 1e-3));
    expect(await angleOf(SwipeOutcome.hold), closeTo(0, 1e-6));
  });
}
