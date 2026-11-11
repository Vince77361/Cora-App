import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/core/ui/cora_error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/cora_test_app.dart';

void main() {
  testWidgets('error view shows the message and retries', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      coraTestApp(
        CoraErrorView(message: '서버에 연결하지 못했어요.', onRetry: () => retries++),
      ),
    );

    expect(find.text('서버에 연결하지 못했어요.'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(retries, 1);
  });

  testWidgets('error view announces the message to screen readers', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      coraTestApp(CoraErrorView(message: '서버에 연결하지 못했어요.', onRetry: () {})),
    );
    expect(
      tester.getSemantics(find.text('서버에 연결하지 못했어요.')),
      matchesSemantics(label: '서버에 연결하지 못했어요.', isLiveRegion: true),
    );
    expect(
      tester.getSemantics(find.text('다시 시도')),
      matchesSemantics(
        label: '다시 시도',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('error view renders in dark theme at 1.3x text', (tester) async {
    await tester.pumpWidget(
      coraTestApp(
        CoraErrorView(message: '서버에 연결하지 못했어요.', onRetry: () {}),
        theme: coraDarkTheme,
        textScaler: const TextScaler.linear(1.3),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
