import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/core/ui/cora_network_photo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/cora_test_app.dart';

Color _background(WidgetTester tester) => tester
    .widget<ColoredBox>(
      find.descendant(
        of: find.byType(CoraNetworkPhoto),
        matching: find.byType(ColoredBox),
      ),
    )
    .color;

void main() {
  testWidgets('without a url it is just the surface box', (tester) async {
    await tester.pumpWidget(
      coraTestApp(
        const SizedBox.square(
          dimension: 46,
          child: CoraNetworkPhoto(url: null),
        ),
      ),
    );

    expect(find.byType(Image), findsNothing);
    expect(_background(tester), CoraColors.light.surface);
    expect(tester.getSize(find.byType(CoraNetworkPhoto)), const Size(46, 46));
  });

  testWidgets('surface background in dark too', (tester) async {
    await tester.pumpWidget(
      coraTestApp(
        const SizedBox.square(dimension: 46, child: CoraNetworkPhoto(url: '')),
        theme: coraDarkTheme,
      ),
    );
    expect(_background(tester), CoraColors.dark.surface);
  });

  testWidgets('keeps the surface box while loading and when loading fails', (
    tester,
  ) async {
    // 테스트 환경의 이미지 요청은 실패로 끝난다. 실패해도 깨진 그림 대신 바탕만 보여야 한다.
    await tester.pumpWidget(
      coraTestApp(
        const SizedBox.square(
          dimension: 46,
          child: CoraNetworkPhoto(
            url: 'http://127.0.0.1:1/none.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
    expect(find.byType(Image), findsOneWidget);
    expect(tester.widget<Image>(find.byType(Image)).fit, BoxFit.contain);
    expect(_background(tester), CoraColors.light.surface);

    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(_background(tester), CoraColors.light.surface);
    expect(find.byIcon(Icons.broken_image), findsNothing);
  });
}
