import 'dart:async';

import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/features/discovery/domain/pass_reason.dart';
import 'package:cora/features/discovery/presentation/widgets/pass_reason_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';

/// 시트를 [showPassReasonSheet]로 연다(건너뛰기와 아래로 내려 닫기는 시트를 닫는 동작이라 라우트가 필요하다).
Future<void> _open(
  WidgetTester tester, {
  required Future<void> Function(PassReason) onSave,
}) async {
  useCanvasPhone(tester);
  await tester.pumpWidget(
    MaterialApp(
      theme: coraLightTheme,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => showPassReasonSheet(context, onSave: onSave),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('a double tap on save sends the reason only once', (
    tester,
  ) async {
    final saves = <PassReason>[];
    final pending = Completer<void>();
    await _open(
      tester,
      onSave: (reason) {
        saves.add(reason);
        return pending.future;
      },
    );
    await tester.tap(find.text('금액이 안 맞아요'));
    await tester.pump();

    // 두 번째 누름이 다시 그려지기 전에 들어온다(연타).
    await tester.tap(find.text('이유 남기고 다음 보기'));
    await tester.tap(find.text('이유 남기고 다음 보기'));
    await tester.pump();

    expect(saves, [PassReason.fee]);
    pending.complete();
    await tester.pumpAndSettle();
  });

  testWidgets(
    'disables the save-reason button until a reason is picked and always '
    'offers skip',
    (tester) async {
      final saves = <PassReason>[];
      await _open(
        tester,
        onSave: (reason) async {
          saves.add(reason);
        },
      );

      expect(find.text('이유 남기고 다음 보기'), findsOneWidget);
      expect(find.text('건너뛰기'), findsOneWidget);
      // 고른 것이 없으면 꺼진 버튼이라 눌러도 저장도 닫기도 일어나지 않는다.
      await tester.tap(find.text('이유 남기고 다음 보기'));
      await tester.pumpAndSettle();
      expect(saves, isEmpty);
      expect(find.text('넘겼어요. 이유를 남길까요?'), findsOneWidget);

      // 고르면 켜지고, 같은 것을 다시 누르면 다시 꺼진다.
      await tester.tap(find.text('분야가 달라요'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('분야가 달라요'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('이유 남기고 다음 보기'));
      await tester.pumpAndSettle();
      expect(saves, isEmpty);

      // 건너뛰기는 고른 것이 있든 없든 저장 없이 닫는다.
      await tester.tap(find.text('분야가 달라요'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('건너뛰기'));
      await tester.pumpAndSettle();

      expect(saves, isEmpty);
      expect(find.text('넘겼어요. 이유를 남길까요?'), findsNothing);
    },
  );

  testWidgets('has no undo row in the sheet', (tester) async {
    await _open(tester, onSave: (_) async {});

    expect(find.text('되돌리기'), findsNothing);
    expect(find.text('이유 없이 다음 보기'), findsNothing);
  });
}
