import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/features/brand_onboarding/presentation/widgets/close_campaign_sheet.dart';
import 'package:cora/features/discovery/presentation/widgets/like_note_sheet.dart';
import 'package:cora/features/discovery/presentation/widgets/pass_reason_sheet.dart';
import 'package:cora/features/interests/presentation/widgets/hold_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';

typedef _Show = Future<void> Function(BuildContext context);

/// 시트를 연 채 시스템 밝기를 바꿔도 시트 바탕이 새 색을 따라가는지 본다. 시트를 열 때 색을 한 번 잡아
/// 두면 글자만 바뀌고 바탕은 옛 색으로 남는다.
Future<void> _expectSheetFollowsTheme(WidgetTester tester, _Show show) async {
  final mode = ValueNotifier(ThemeMode.light);
  addTearDown(mode.dispose);
  await tester.pumpWidget(
    ValueListenableBuilder<ThemeMode>(
      valueListenable: mode,
      builder: (context, value, _) => MaterialApp(
        theme: coraLightTheme,
        darkTheme: coraDarkTheme,
        themeMode: value,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => show(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();

  // 시트 바탕을 칠한 상자: 시트 안에서 배경색으로 칠한 가장 안쪽 상자.
  Color? sheetBackground() {
    final boxes = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((b) => b.decoration)
        .whereType<BoxDecoration>()
        .where((d) => d.borderRadius != null && d.color != null);
    return boxes.isEmpty ? null : boxes.first.color;
  }

  expect(sheetBackground(), CoraColors.light.background);
  mode.value = ThemeMode.dark;
  await tester.pumpAndSettle();
  expect(sheetBackground(), CoraColors.dark.background);
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('the pass reason sheet repaints when the theme flips', (
    tester,
  ) async {
    await _expectSheetFollowsTheme(
      tester,
      (context) => showPassReasonSheet(context, onSave: (_) async {}),
    );
  });

  testWidgets('the like note sheet repaints when the theme flips', (
    tester,
  ) async {
    await _expectSheetFollowsTheme(tester, showLikeNoteSheet);
  });

  testWidgets('the close campaign sheet repaints when the theme flips', (
    tester,
  ) async {
    await _expectSheetFollowsTheme(tester, showCloseCampaignSheet);
  });

  testWidgets('the hold sheet repaints when the theme flips', (tester) async {
    await _expectSheetFollowsTheme(tester, showHoldSheet);
  });
}
