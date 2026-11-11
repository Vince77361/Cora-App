import 'package:cora/core/ui/cora_logo.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/cora_test_app.dart';

double _wordSize(WidgetTester tester) => tester
    .renderObject<RenderParagraph>(find.text('cora'))
    .text
    .style!
    .fontSize!;

void main() {
  testWidgets('the default logo keeps the A1 sizes', (tester) async {
    await tester.pumpWidget(coraTestApp(const CoraLogo()));

    expect(tester.getSize(find.byKey(CoraLogo.markKey)), const Size(28, 28));
    expect(_wordSize(tester), 26);
    final mark = tester.getRect(find.byKey(CoraLogo.markKey));
    final word = tester.getRect(find.text('cora'));
    expect(word.left - mark.right, 6);
  });

  testWidgets('the hero logo is 34 with a 8 gap and a 32 wordmark', (
    tester,
  ) async {
    await tester.pumpWidget(coraTestApp(const CoraLogo.hero()));

    expect(tester.getSize(find.byKey(CoraLogo.markKey)), const Size(34, 34));
    expect(_wordSize(tester), 32);
    final mark = tester.getRect(find.byKey(CoraLogo.markKey));
    final word = tester.getRect(find.text('cora'));
    expect(word.left - mark.right, 8);
    final style = tester
        .renderObject<RenderParagraph>(find.text('cora'))
        .text
        .style!;
    expect(style.letterSpacing, closeTo(-1.6, 0.001));
    expect(style.fontWeight, FontWeight.w900);
  });
}
