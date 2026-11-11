import 'dart:io';

import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/features/demo/demo_paths.dart';
import 'package:cora/features/demo/demo_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// 시연 화면을 모두 390×844로 라이트·다크 한 번씩 그려 본다. 예외나 넘침이 있으면 실패한다.
/// `SHOTS=1`이면 build/demo_shots/에 그림을 남긴다(눈으로 artifact와 대조할 때).
Future<void> _loadFonts() async {
  final loader = FontLoader('NotoSansKR');
  for (final w in ['Regular', 'Medium', 'Bold', 'Black']) {
    loader.addFont(rootBundle.load('assets/fonts/NotoSansKR-$w.otf'));
  }
  await loader.load();
}

void main() {
  final shots = Platform.environment['SHOTS'] == '1';
  setUpAll(_loadFonts);
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final s in demoScreens) {
      testWidgets('${mode.name} ${s.path} renders', (tester) async {
        tester.view.physicalSize = const Size(390, 844) * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: coraLightTheme,
              darkTheme: coraDarkTheme,
              themeMode: mode,
              routerConfig: demoRouter,
            ),
          ),
        );
        demoRouter.go(s.path);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.textContaining('아직 만들지 않은 화면'), findsNothing);
        if (shots) {
          await tester.runAsync(() async {
            for (final img in find.byType(Image).evaluate()) {
              final p = (img.widget as Image).image;
              await precacheImage(p, img);
            }
          });
          await tester.pump();
          final name = '${mode.name}${s.path.replaceAll('/', '_')}';
          await expectLater(
            find.byKey(key),
            matchesGoldenFile('../../build/demo_shots/$name.png'),
          );
        }
      });
    }
  }
}
