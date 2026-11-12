import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/features/demo/demo_paths.dart';
import 'package:cora/features/demo/demo_role.dart';
import 'package:cora/features/demo/demo_router.dart';
import 'package:cora/features/demo/g9/g9_common.dart';
import 'package:cora/features/demo/shared/demo_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// 가게 사장님 홈(A9)에서 G1 7일 결과로 들어가고, 뒤로 가면 A9로 돌아온다.
Future<void> _loadFonts() async {
  final loader = FontLoader('NotoSansKR');
  for (final w in ['Regular', 'Medium', 'Bold', 'Black']) {
    loader.addFont(rootBundle.load('assets/fonts/NotoSansKR-$w.otf'));
  }
  await loader.load();
}

void main() {
  setUpAll(_loadFonts);
  setUp(() {
    demoRole.value = null;
    demoRedirectFallbacks.clear();
  });
  tearDown(() => demoRole.value = null);

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
  }

  Future<void> openAs(WidgetTester tester, String path) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    demoRole.value = DemoRole.store;
    await tester.pumpWidget(
      MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: coraLightTheme,
        darkTheme: coraDarkTheme,
        routerConfig: demoRouter,
      ),
    );
    demoRouter.go(path);
    await settle(tester);
  }

  List<String> stack() => [
    for (final m in demoRouter.routerDelegate.currentConfiguration.matches)
      m.matchedLocation,
  ];

  Future<void> tapHeaderBack(WidgetTester tester) async {
    await tester.tap(
      find
          .descendant(of: find.byType(G9Header), matching: find.byType(DemoSvg))
          .first,
    );
    await settle(tester);
  }

  testWidgets('store A9 in-progress card opens G1 and back returns to A9', (
    tester,
  ) async {
    await openAs(tester, DemoPaths.storeHome);
    await tester.tap(find.text('진행 중'));
    await settle(tester);
    expect(stack().last, DemoPaths.result);
    expect(find.text('7일 결과'), findsOneWidget);
    expect(find.text('12,500회'), findsOneWidget);

    await tapHeaderBack(tester);
    expect(stack(), [DemoPaths.storeHome]);
    expect(find.text('사장님 홈'), findsOneWidget);
    expect(demoRedirectFallbacks, isEmpty);
  });

  testWidgets('store G1 opened directly goes back to A9', (tester) async {
    await openAs(tester, DemoPaths.result);
    expect(stack(), [DemoPaths.result]);
    await tapHeaderBack(tester);
    expect(stack(), [DemoPaths.storeHome]);
  });

  testWidgets('store G1 buttons stay on store screens', (tester) async {
    await openAs(tester, DemoPaths.storeHome);
    await tester.tap(find.text('진행 중'));
    await settle(tester);
    for (final (label, path) in [
      ('새 오퍼', DemoPaths.offer),
      ('영상 받기', DemoPaths.aiOrder),
      ('하루 한 컵과 다시 만나기', DemoPaths.budget),
    ]) {
      await tester.tap(find.text(label));
      await settle(tester);
      expect(stack().last, path);
      expect(demoAllowedPaths(DemoRole.store), contains(path));
      demoRouter.pop();
      await settle(tester);
      expect(stack().last, DemoPaths.result);
    }
    expect(demoRedirectFallbacks, isEmpty);
  });
}
