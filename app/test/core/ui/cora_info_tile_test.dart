import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/core/ui/cora_info_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/cora_test_app.dart';

BoxDecoration _decoration(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find.descendant(
                of: find.byType(CoraInfoTile),
                matching: find.byType(DecoratedBox),
              ),
            )
            .decoration
        as BoxDecoration;

TextStyle _style(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style!;

void main() {
  testWidgets('tile has radius 18, surface fill and 12/14 padding', (
    tester,
  ) async {
    await tester.pumpWidget(
      coraTestApp(
        const SizedBox(
          width: 175,
          child: CoraInfoTile(label: '대표 메뉴', value: '돈코츠 라멘 11,000원'),
        ),
      ),
    );

    expect(_decoration(tester).color, CoraColors.light.surface);
    expect(_decoration(tester).borderRadius, BorderRadius.circular(18));
    final tile = tester.getRect(find.byType(CoraInfoTile));
    final label = tester.getTopLeft(find.text('대표 메뉴'));
    expect(label.dx - tile.left, 14);
    expect(label.dy - tile.top, closeTo(12, 3));
  });

  testWidgets('label is 12px secondary and value is 15px 500', (tester) async {
    await tester.pumpWidget(
      coraTestApp(const CoraInfoTile(label: '영업시간', value: '11:30 – 21:00')),
    );

    expect(_style(tester, '영업시간').fontSize, 12);
    expect(_style(tester, '영업시간').color, CoraColors.light.textSecondary);
    expect(_style(tester, '11:30 – 21:00').fontSize, 15);
    expect(_style(tester, '11:30 – 21:00').fontWeight, FontWeight.w500);
    expect(_style(tester, '11:30 – 21:00').color, CoraColors.light.text);
  });

  testWidgets('shows 아직 없어요 when the value is null or blank', (tester) async {
    await tester.pumpWidget(
      coraTestApp(const CoraInfoTile(label: '좌석', value: null)),
    );
    expect(find.text('아직 없어요'), findsOneWidget);

    await tester.pumpWidget(
      coraTestApp(const CoraInfoTile(label: '좌석', value: '  ')),
    );
    expect(find.text('아직 없어요'), findsOneWidget);
  });

  testWidgets('dark uses the dark surface and secondary colors', (
    tester,
  ) async {
    await tester.pumpWidget(
      coraTestApp(
        const CoraInfoTile(label: '좌석', value: '18석'),
        theme: coraDarkTheme,
      ),
    );
    expect(_decoration(tester).color, const Color(0xFF1C1E22));
    expect(_style(tester, '좌석').color, const Color(0xFFA0A4AD));
  });

  testWidgets('exposes label and value to screen readers', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      coraTestApp(const CoraInfoTile(label: '좌석', value: '18석')),
    );
    expect(find.bySemanticsLabel('좌석'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('wraps long values at 1.3x text without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      coraTestApp(
        const SizedBox(
          width: 160,
          child: CoraInfoTile(
            label: '찍기 좋은 시간',
            value: '오후 3시 – 5시, 평일 오전도 좋아요',
          ),
        ),
        textScaler: const TextScaler.linear(1.3),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
