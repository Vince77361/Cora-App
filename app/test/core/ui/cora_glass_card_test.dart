import 'dart:ui';

import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/core/theme/cora_shadows.dart';
import 'package:cora/core/theme/cora_shapes.dart';
import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/core/ui/cora_glass_card.dart';
import 'package:cora/core/ui/cora_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/cora_test_app.dart';

void main() {
  testWidgets('glass card blurs what is behind it like the Principles canvas', (
    tester,
  ) async {
    await tester.pumpWidget(
      coraTestApp(const CoraGlassCard(child: Text('질문'))),
    );

    final blur = tester.widget<BackdropFilter>(
      find.descendant(
        of: find.byType(CoraGlassCard),
        matching: find.byType(BackdropFilter),
      ),
    );
    // CSS backdrop-filter blur(16px)의 16은 가우시안 시그마다.
    expect(blur.filter, ImageFilter.blur(sigmaX: 16, sigmaY: 16));

    final clip = tester.widget<ClipRRect>(
      find.descendant(
        of: find.byType(CoraGlassCard),
        matching: find.byType(ClipRRect),
      ),
    );
    expect(clip.borderRadius, BorderRadius.circular(CoraRadius.xxl));

    final shadow = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(CoraGlassCard),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final decoration = shadow.decoration as BoxDecoration;
    expect(decoration.boxShadow, CoraShadows.floating);
    expect(decoration.borderRadius, BorderRadius.circular(CoraRadius.xxl));

    final fill = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byType(CoraGlassCard),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(fill.color, CoraColors.light.glass);
  });

  testWidgets('glass card uses the dark glass fill in dark theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      coraTestApp(const CoraGlassCard(child: Text('질문')), theme: coraDarkTheme),
    );
    await tester.pumpAndSettle();
    final fill = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byType(CoraGlassCard),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(fill.color, CoraColors.dark.glass);
  });

  testWidgets('logo shows the cora wordmark next to a 28 mark', (tester) async {
    await tester.pumpWidget(coraTestApp(const CoraLogo()));

    expect(find.text('cora'), findsOneWidget);
    final mark = find.byKey(CoraLogo.markKey);
    expect(tester.getSize(mark), const Size(28, 28));
    final word = tester.renderObject<RenderParagraph>(find.text('cora'));
    expect(word.text.style!.fontSize, 26);
    expect(word.text.style!.fontWeight, FontWeight.w900);
    expect(word.text.style!.letterSpacing, -1.3);
    expect(word.text.style!.color, CoraColors.light.text);
    // 마크와 글자 사이 6
    expect(
      tester.getRect(find.text('cora')).left - tester.getRect(mark).right,
      6,
    );
  });

  testWidgets('logo scales the wordmark with its size', (tester) async {
    await tester.pumpWidget(coraTestApp(const CoraLogo(size: 56)));
    expect(tester.getSize(find.byKey(CoraLogo.markKey)), const Size(56, 56));
    final word = tester.renderObject<RenderParagraph>(find.text('cora'));
    expect(word.text.style!.fontSize, 52);
    expect(word.text.style!.letterSpacing, -2.6);
  });
}
