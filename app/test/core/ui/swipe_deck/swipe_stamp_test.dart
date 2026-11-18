import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/core/ui/swipe_deck/swipe_physics.dart';
import 'package:cora/core/ui/swipe_deck/swipe_stamp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: coraLightTheme,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('labels the like stamp as heart and the hold stamp as save', (
    tester,
  ) async {
    for (final (outcome, label) in [
      (SwipeOutcome.like, '하트'),
      (SwipeOutcome.pass, '넘김'),
      (SwipeOutcome.hold, '저장'),
    ]) {
      await tester.pumpWidget(_wrap(Center(child: SwipeStamp(outcome))));
      expect(find.text(label), findsOneWidget);
    }
    // 옛 이름은 도장에 남지 않는다.
    await tester.pumpWidget(
      _wrap(Center(child: SwipeStamp(SwipeOutcome.like))),
    );
    expect(find.text('관심'), findsNothing);
    await tester.pumpWidget(
      _wrap(Center(child: SwipeStamp(SwipeOutcome.hold))),
    );
    expect(find.text('보류'), findsNothing);
  });
}
