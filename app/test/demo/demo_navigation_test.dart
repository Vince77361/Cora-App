import 'package:cora/features/demo/demo_app.dart';
import 'package:cora/features/demo/demo_paths.dart';
import 'package:cora/features/demo/demo_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 시연 중 목록으로 돌아가는 두 길(가장자리 밀기, 두 손가락 길게 누르기)이 실제로 되는지.
void main() {
  Future<void> open(WidgetTester tester, String path) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const DemoApp());
    demoRouter.go(DemoPaths.index);
    await tester.pumpAndSettle();
    demoRouter.push(path);
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
    expect(find.text('Cora 시연'), findsNothing);
  }

  for (final path in [
    DemoPaths.brandDiscover,
    DemoPaths.compare,
    DemoPaths.settings,
  ]) {
    testWidgets(
      'edge swipe from $path pops back to the list',
      (tester) async {
        await open(tester, path);
        await tester.timedDragFrom(
          const Offset(5, 400),
          const Offset(300, 0),
          const Duration(milliseconds: 300),
        );
        await tester.pumpAndSettle(
          const Duration(milliseconds: 100),
          EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 5),
        );
        expect(find.text('Cora 시연'), findsOneWidget);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );

    testWidgets(
      'two finger long press on $path goes to the list',
      (tester) async {
        await open(tester, path);
        final a = await tester.startGesture(const Offset(150, 400), pointer: 7);
        final b = await tester.startGesture(const Offset(250, 400), pointer: 8);
        await tester.pump(const Duration(milliseconds: 700));
        await a.up();
        await b.up();
        await tester.pumpAndSettle(
          const Duration(milliseconds: 100),
          EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 5),
        );
        expect(find.text('Cora 시연'), findsOneWidget);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );
  }
}
