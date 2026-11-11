import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/core/theme/cora_motion.dart';
import 'package:cora/core/theme/cora_shadows.dart';
import 'package:cora/core/theme/cora_shapes.dart';
import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/core/ui/cora_select_card.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/cora_test_app.dart';

// 캔버스 A1 카드 1의 문구.
const _overline = '일을 맡기는 쪽';
const _title = '가게를 알리고 싶어요';
const _subtitle = '식당, 미용실, 공방 같은 동네 가게';

Widget _card({required bool selected, VoidCallback? onTap}) => SizedBox(
  width: 358,
  child: CoraSelectCard(
    overline: _overline,
    title: _title,
    subtitle: _subtitle,
    selected: selected,
    onTap: onTap ?? () {},
  ),
);

BoxDecoration _cardDecoration(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.byType(CoraSelectCard),
          matching: find.byType(DecoratedBox),
        )
        .first,
  );
  return box.decoration as BoxDecoration;
}

/// 오른쪽 원(지름 24)의 장식.
BoxDecoration _dotDecoration(WidgetTester tester) {
  final dot = find.descendant(
    of: find.byType(CoraSelectCard),
    matching: find.byKey(CoraSelectCard.dotKey),
  );
  return (tester.widget<DecoratedBox>(dot)).decoration as BoxDecoration;
}

void main() {
  testWidgets('select card exposes selected state to accessibility', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(coraTestApp(_card(selected: true)));

    expect(
      tester.getSemantics(find.byType(CoraSelectCard)),
      matchesSemantics(
        label: '$_overline\n$_title\n$_subtitle',
        isSelected: true,
        hasSelectedState: true,
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );

    await tester.pumpWidget(coraTestApp(_card(selected: false)));
    expect(
      tester.getSemantics(find.byType(CoraSelectCard)),
      matchesSemantics(
        label: '$_overline\n$_title\n$_subtitle',
        isSelected: false,
        hasSelectedState: true,
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('select card calls onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      coraTestApp(_card(selected: false, onTap: () => taps++)),
    );
    await tester.tap(find.text(_title));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('select card is at least 92 tall and grows with long text', (
    tester,
  ) async {
    await tester.pumpWidget(
      coraTestApp(
        SizedBox(
          width: 358,
          child: CoraSelectCard(title: '가게', selected: false, onTap: () {}),
        ),
      ),
    );
    expect(tester.getSize(find.byType(CoraSelectCard)).height, 92);

    // 작은 휴대폰 너비, 글자 1.3배에서 긴 문구가 잘리지 않고 카드가 늘어난다.
    await tester.pumpWidget(
      coraTestApp(
        SizedBox(
          width: 328,
          child: CoraSelectCard(
            overline: _overline,
            title: '브랜드 제품을 알리고 싶어요 그리고 아주 긴 제목이 두 줄로 넘어가요',
            subtitle: '팔로워가 적어도 누구나 시작할 수 있어요. 설명이 길어져도 카드가 늘어나요.',
            selected: true,
            onTap: () {},
          ),
        ),
        textScaler: const TextScaler.linear(1.3),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(CoraSelectCard)).height, greaterThan(92));
  });

  testWidgets('select card matches the A1 canvas box', (tester) async {
    await tester.pumpWidget(coraTestApp(_card(selected: false)));

    final decoration = _cardDecoration(tester);
    expect(decoration.borderRadius, BorderRadius.circular(CoraRadius.xl));
    // 오른쪽 원은 지름 24, 카드 안쪽 여백은 위아래 18, 좌우 20이다.
    final cardRect = tester.getRect(find.byType(CoraSelectCard));
    final dotRect = tester.getRect(find.byKey(CoraSelectCard.dotKey));
    expect(dotRect.size, const Size(24, 24));
    expect(cardRect.right - dotRect.right, 20);
    final overlineRect = tester.getRect(find.text(_overline));
    expect(overlineRect.left - cardRect.left, 20);
    expect(overlineRect.top - cardRect.top, 18);
    // 글자 묶음과 원 사이 간격 16
    final titleRect = tester.getRect(find.text(_title));
    expect(dotRect.left - titleRect.left, greaterThanOrEqualTo(16));

    final title = tester.renderObject<RenderParagraph>(find.text(_title));
    expect(title.text.style!.fontSize, 19);
    expect(title.text.style!.fontWeight, FontWeight.w700);
  });

  testWidgets('selected card uses surfaceSelected without a shadow', (
    tester,
  ) async {
    await tester.pumpWidget(coraTestApp(_card(selected: true)));
    final c = CoraColors.light;
    final decoration = _cardDecoration(tester);
    expect(decoration.color, c.surfaceSelected);
    expect(decoration.boxShadow ?? const <BoxShadow>[], isEmpty);
    expect(_dotDecoration(tester).color, c.selectionDot);
  });

  testWidgets('unselected card uses background with the card shadow', (
    tester,
  ) async {
    await tester.pumpWidget(coraTestApp(_card(selected: false)));
    final c = CoraColors.light;
    final decoration = _cardDecoration(tester);
    expect(decoration.color, c.background);
    expect(decoration.boxShadow, CoraShadows.card);
    expect(_dotDecoration(tester).color, c.line);
  });

  testWidgets('dark selected card follows the DarkNRole colors', (
    tester,
  ) async {
    await tester.pumpWidget(
      coraTestApp(_card(selected: true), theme: coraDarkTheme),
    );
    await tester.pumpAndSettle();
    final c = CoraColors.dark;
    expect(_cardDecoration(tester).color, c.surfaceSelected);
    expect(_dotDecoration(tester).color, c.selectionDot);
    final title = tester.renderObject<RenderParagraph>(find.text(_title));
    expect(title.text.style!.color, c.onSurfaceSelected);
  });

  testWidgets('select card animates its selection', (tester) async {
    final c = CoraColors.light;
    await tester.pumpWidget(coraTestApp(_card(selected: false)));
    await tester.pumpWidget(coraTestApp(_card(selected: true)));
    await tester.pump(const Duration(milliseconds: 100));

    final mid = _cardDecoration(tester).color!;
    expect(mid, isNot(c.background));
    expect(mid, isNot(c.surfaceSelected));

    await tester.pump(CoraMotion.stateDuration);
    expect(_cardDecoration(tester).color, c.surfaceSelected);
  });

  testWidgets('select card snaps to the new state when reducing motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      coraTestApp(_card(selected: false), disableAnimations: true),
    );
    await tester.pumpWidget(
      coraTestApp(_card(selected: true), disableAnimations: true),
    );
    await tester.pump();
    expect(_cardDecoration(tester).color, CoraColors.light.surfaceSelected);
  });

  testWidgets('select card shrinks slightly while pressed', (tester) async {
    await tester.pumpWidget(coraTestApp(_card(selected: false)));
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(CoraSelectCard)),
    );
    await tester.pump(kPressTimeout);
    await tester.pump(CoraMotion.pressDuration);
    // 화면에 실제로 그려진 너비 ÷ 배치 너비.
    final surface = find
        .descendant(
          of: find.byType(CoraSelectCard),
          matching: find.byType(DecoratedBox),
        )
        .first;
    final scale = tester.getRect(surface).width / tester.getSize(surface).width;
    expect(scale, moreOrLessEquals(CoraMotion.pressedScale));
    await gesture.up();
    await tester.pumpAndSettle();
  });
}
