import 'dart:async';

import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/features/discovery/domain/pass_reason.dart';
import 'package:cora/features/discovery/domain/undo_result.dart';
import 'package:cora/features/discovery/presentation/widgets/pass_reason_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';

Future<void> _pump(
  WidgetTester tester, {
  required Future<void> Function(PassReason) onSave,
  required Future<UndoResult> Function() onUndo,
}) async {
  useCanvasPhone(tester);
  await tester.pumpWidget(
    MaterialApp(
      theme: coraLightTheme,
      home: Scaffold(
        body: PassReasonSheet(onSave: onSave, onUndo: onUndo),
      ),
    ),
  );
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('a double tap on save sends the reason only once', (
    tester,
  ) async {
    final saves = <PassReason>[];
    final pending = Completer<void>();
    await _pump(
      tester,
      onSave: (reason) {
        saves.add(reason);
        return pending.future;
      },
      onUndo: () async => UndoResult.undone,
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

  testWidgets('a double tap on undo undoes only once', (tester) async {
    var undos = 0;
    final pending = Completer<UndoResult>();
    await _pump(
      tester,
      onSave: (_) async {},
      onUndo: () {
        undos++;
        return pending.future;
      },
    );

    await tester.tap(find.text('되돌리기'));
    await tester.tap(find.text('되돌리기'));
    await tester.pump();

    expect(undos, 1);
    pending.complete(UndoResult.nothing);
    await tester.pumpAndSettle();
  });
}
