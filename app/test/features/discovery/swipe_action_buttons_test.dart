import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/features/discovery/presentation/widgets/swipe_action_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';

Future<void> _pump(
  WidgetTester tester, {
  bool canUndo = true,
  VoidCallback? onUndo,
  VoidCallback? onPass,
  VoidCallback? onHold,
  VoidCallback? onLike,
  double textScale = 1,
  ThemeData? theme,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? coraLightTheme,
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(390, 844),
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: SwipeActionButtons(
              canUndo: canUndo,
              onUndo: onUndo ?? () {},
              onPass: onPass ?? () {},
              onHold: onHold ?? () {},
              onLike: onLike ?? () {},
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('shows four labelled buttons: undo, pass, save, heart', (
    tester,
  ) async {
    await _pump(tester);

    // 아이콘 아래의 글자 네 개(왼쪽부터 되돌리기, 넘기기, 저장, 하트).
    final labels = ['되돌리기', '넘기기', '저장', '하트'];
    for (final label in labels) {
      expect(find.text(label), findsOneWidget);
      expect(find.bySemanticsLabel(label), findsOneWidget);
    }
    final xs = [for (final l in labels) tester.getCenter(find.text(l)).dx];
    expect(xs, [...xs]..sort());
    // 옛 이름이 남지 않는다.
    expect(find.text('보류'), findsNothing);
    expect(find.text('관심 있어요'), findsNothing);
  });

  testWidgets('fires onHold from the save button and onLike from the heart '
      'button', (tester) async {
    var holds = 0;
    var likes = 0;
    var passes = 0;
    var undos = 0;
    await _pump(
      tester,
      onHold: () => holds++,
      onLike: () => likes++,
      onPass: () => passes++,
      onUndo: () => undos++,
    );

    await tester.tap(find.text('저장'));
    await tester.tap(find.text('하트'));
    await tester.tap(find.text('넘기기'));
    await tester.tap(find.text('되돌리기'));

    expect([holds, likes, passes, undos], [1, 1, 1, 1]);
  });

  testWidgets('labels are 11px white text and the undo button dims when there '
      'is nothing to undo', (tester) async {
    await _pump(tester, canUndo: false);

    final style = tester.widget<Text>(find.text('저장')).style!;
    expect(style.fontSize, 11);
    expect(style.fontWeight, FontWeight.w500);
    expect(style.color, const Color(0xFFFFFFFF));
    final dim = tester.widget<Opacity>(
      find.ancestor(of: find.text('되돌리기'), matching: find.byType(Opacity)),
    );
    expect(dim.opacity, 0.45);
  });

  testWidgets('keeps every label inside its 60px button at 2x text size', (
    tester,
  ) async {
    // 2배에서는 글자가 60을 넘으려 하므로 `FittedBox`가 줄이지 않으면 화면상 너비가 60을 넘는다
    // (`getRect`는 `FittedBox`의 변환을 곱한 화면상 상자를 돌려준다).
    await _pump(tester, textScale: 2);

    expect(tester.takeException(), isNull);
    for (final label in ['되돌리기', '넘기기', '저장', '하트']) {
      final box = tester.getRect(find.text(label));
      expect(box.width, lessThanOrEqualTo(60), reason: label);
    }
    // 줄어든 글자는 그래도 한 줄이다.
    expect(tester.getRect(find.text('되돌리기')).height, lessThan(30));
  });

  testWidgets('keeps the same layout in the dark theme', (tester) async {
    await _pump(tester, theme: coraDarkTheme);

    expect(find.text('하트'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
