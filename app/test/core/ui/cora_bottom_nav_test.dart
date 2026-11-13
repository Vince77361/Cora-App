import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/core/ui/cora_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/cora_test_app.dart';

Widget _nav({int current = 0, ValueChanged<int>? onTap}) => CoraBottomNav(
  items: CoraNavItems.store,
  currentIndex: current,
  onTap: onTap ?? (_) {},
);

BoxDecoration _bar(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find
                  .descendant(
                    of: find.byType(CoraBottomNav),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .decoration
        as BoxDecoration;

Color _labelColor(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style!.color!;

void main() {
  testWidgets('bar is 64 tall with radius 32 and floats 16/20 from the edges', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: coraLightTheme,
        home: Scaffold(
          body: Stack(
            children: [Align(alignment: Alignment.bottomCenter, child: _nav())],
          ),
        ),
      ),
    );

    final bar = tester.getRect(
      find
          .descendant(
            of: find.byType(CoraBottomNav),
            matching: find.byType(SizedBox),
          )
          .first,
    );
    expect(bar.height, 64);
    expect(bar.left, 16);
    expect(bar.right, 390 - 16);
    expect(bar.bottom, 844 - 20);
    expect(_bar(tester).borderRadius, BorderRadius.circular(32));
    expect(_bar(tester).boxShadow, isNotEmpty);
  });

  testWidgets('light: white bar, selected ink, others #8B9099', (tester) async {
    await tester.pumpWidget(coraTestApp(_nav(current: 0)));

    expect(_bar(tester).color, const Color(0xFFFFFFFF));
    expect(_labelColor(tester, '홈'), const Color(0xFF17181C));
    expect(_labelColor(tester, '찾기'), const Color(0xFF8B9099));
    expect(find.text('AI 글'), findsOneWidget);
  });

  testWidgets('dark: #26282D bar, selected #F2F3F5, others #8B9099', (
    tester,
  ) async {
    await tester.pumpWidget(
      coraTestApp(_nav(current: 0), theme: coraDarkTheme),
    );

    expect(_bar(tester).color, const Color(0xFF26282D));
    expect(_labelColor(tester, '홈'), const Color(0xFFF2F3F5));
    expect(_labelColor(tester, '찾기'), const Color(0xFF8B9099));
    expect(_bar(tester).boxShadow!.single.color, const Color(0x1F17181C));
  });

  testWidgets('tapping an item reports its index', (tester) async {
    final taps = <int>[];
    await tester.pumpWidget(coraTestApp(_nav(onTap: taps.add)));

    await tester.tap(find.text('오퍼'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('홈'));
    await tester.pumpAndSettle();

    expect(taps, [3, 0]);
  });

  testWidgets('items are 58 x 52 and expose selected state', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(coraTestApp(_nav(current: 1)));

    final item = find.ancestor(
      of: find.text('찾기'),
      matching: find.byWidgetPredicate((w) => w is SizedBox && w.width == 58),
    );
    expect(tester.getSize(item.first), const Size(58, 52));
    expect(
      tester.getSemantics(find.text('찾기')),
      matchesSemantics(
        label: '찾기',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('does not overflow at 1.3x text on a small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    // 화면 가장자리에 붙여 띄운다(하단 메뉴는 자체 좌우 16 여백을 가진다).
    await tester.pumpWidget(
      MaterialApp(
        theme: coraLightTheme,
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.3)),
          child: app!,
        ),
        home: Scaffold(
          body: Align(alignment: Alignment.bottomCenter, child: _nav()),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
