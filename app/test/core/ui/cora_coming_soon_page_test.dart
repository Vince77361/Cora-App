import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/core/ui/cora_coming_soon_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app({ThemeData? theme, TextScaler? scaler}) => MaterialApp(
    theme: theme ?? coraLightTheme,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: scaler),
      child: child!,
    ),
    home: const CoraComingSoonPage(title: '가게 홈'),
  );

  testWidgets('shows the title and the coming-soon body', (tester) async {
    await tester.pumpWidget(app());

    expect(find.text('가게 홈'), findsOneWidget);
    expect(find.text('준비 중이에요.'), findsOneWidget);
  });

  testWidgets('has no back button when nothing is below it', (tester) async {
    await tester.pumpWidget(app());
    expect(find.byTooltip('뒤로'), findsNothing);
    expect(find.bySemanticsLabel('뒤로'), findsNothing);
  });

  testWidgets('shows a back button that pops when something is below', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: coraLightTheme,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const CoraComingSoonPage(title: '약관'),
              ),
            ),
            child: const Text('열기'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    expect(find.text('약관'), findsOneWidget);

    await tester.tap(find.byType(CustomPaint).last);
    await tester.pumpAndSettle();

    expect(find.text('약관'), findsNothing);
  });

  testWidgets('renders in dark and at 1.3x text without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      app(theme: coraDarkTheme, scaler: const TextScaler.linear(1.3)),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('준비 중이에요.'), findsOneWidget);
  });
}
