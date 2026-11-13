import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/core/ui/cora_segmented_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/cora_test_app.dart';

Widget _tabs({int selected = 0, ValueChanged<int>? onChanged}) =>
    CoraSegmentedTabs(
      labels: const ['지원한 크리에이터 5', '보낸 오퍼 3'],
      selected: selected,
      onChanged: onChanged ?? (_) {},
    );

// AnimatedContainer.decoration은 목표 값이라, 지금 그려지는 DecoratedBox에서 읽는다.
Color? _tabColor(WidgetTester tester, String label) =>
    (tester
                .widget<DecoratedBox>(
                  find.descendant(
                    of: find.ancestor(
                      of: find.text(label),
                      matching: find.byType(AnimatedContainer),
                    ),
                    matching: find.byType(DecoratedBox),
                  ),
                )
                .decoration
            as BoxDecoration)
        .color;

void main() {
  testWidgets('tabs are 38 tall pills 6 apart', (tester) async {
    await tester.pumpWidget(coraTestApp(_tabs()));

    final a = tester.getRect(
      find.ancestor(
        of: find.text('지원한 크리에이터 5'),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final b = tester.getRect(
      find.ancestor(
        of: find.text('보낸 오퍼 3'),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect(a.height, 38);
    expect(b.left - a.right, 6);
    final decoration =
        tester
                .widget<AnimatedContainer>(
                  find.ancestor(
                    of: find.text('보낸 오퍼 3'),
                    matching: find.byType(AnimatedContainer),
                  ),
                )
                .decoration
            as BoxDecoration;
    expect(decoration.borderRadius, BorderRadius.circular(999));
  });

  testWidgets('light: selected #E3E5E9, other #F8F9FA', (tester) async {
    await tester.pumpWidget(coraTestApp(_tabs(selected: 1)));
    expect(_tabColor(tester, '보낸 오퍼 3'), const Color(0xFFE3E5E9));
    expect(_tabColor(tester, '지원한 크리에이터 5'), const Color(0xFFF8F9FA));
  });

  testWidgets('dark: selected #33363D with #F2F3F5 text, other #1C1E22', (
    tester,
  ) async {
    await tester.pumpWidget(coraTestApp(_tabs(), theme: coraDarkTheme));
    expect(_tabColor(tester, '지원한 크리에이터 5'), const Color(0xFF33363D));
    expect(_tabColor(tester, '보낸 오퍼 3'), const Color(0xFF1C1E22));
    expect(
      tester.widget<Text>(find.text('지원한 크리에이터 5')).style!.color,
      const Color(0xFFF2F3F5),
    );
    expect(
      tester.widget<Text>(find.text('보낸 오퍼 3')).style!.color,
      CoraColors.dark.text,
    );
  });

  testWidgets('tapping a tab reports its index', (tester) async {
    final picked = <int>[];
    await tester.pumpWidget(coraTestApp(_tabs(onChanged: picked.add)));

    await tester.tap(find.text('보낸 오퍼 3'));
    await tester.pumpAndSettle();

    expect(picked, [1]);
  });

  testWidgets('selection animates then settles', (tester) async {
    late StateSetter setState;
    var selected = 0;
    await tester.pumpWidget(
      coraTestApp(
        StatefulBuilder(
          builder: (context, set) {
            setState = set;
            return _tabs(selected: selected);
          },
        ),
      ),
    );
    setState(() => selected = 1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final mid = _tabColor(tester, '보낸 오퍼 3');
    expect(mid, isNot(CoraColors.light.surface));
    expect(mid, isNot(CoraColors.light.notifyTabSelected));
    await tester.pumpAndSettle();
    expect(_tabColor(tester, '보낸 오퍼 3'), CoraColors.light.notifyTabSelected);
  });

  testWidgets('does not overflow at 1.3x text on a small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      coraTestApp(_tabs(), textScaler: const TextScaler.linear(1.3)),
    );
    expect(tester.takeException(), isNull);
  });
}
