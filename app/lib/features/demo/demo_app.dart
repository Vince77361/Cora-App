import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import '../../core/theme/cora_theme.dart';
import 'demo_paths.dart';
import 'demo_router.dart';

/// 모든 화면에서 iOS 가장자리 밀기로 뒤로 갈 수 있게 한다.
const _cupertino = PageTransitionsTheme(
  builders: {
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.android: CupertinoPageTransitionsBuilder(),
  },
);

/// 시연에서 라이트·다크를 바꾸는 스위치. 목록 화면의 버튼이 바꾼다.
final ValueNotifier<ThemeMode> demoThemeMode = ValueNotifier(ThemeMode.light);

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: demoThemeMode,
      builder: (context, mode, _) => MaterialApp.router(
        title: 'Cora 시연',
        debugShowCheckedModeBanner: false,
        theme: coraLightTheme.copyWith(pageTransitionsTheme: _cupertino, inputDecorationTheme: const InputDecorationThemeData()),
        darkTheme: coraDarkTheme.copyWith(pageTransitionsTheme: _cupertino, inputDecorationTheme: const InputDecorationThemeData()),
        themeMode: mode,
        routerConfig: demoRouter,
        // 시연 중 목록으로 돌아가는 숨은 길: 맨 위 상태 표시줄 자리(50pt)를 길게 누른다.
        // 화면 모양을 바꾸지 않으려고 보이는 요소는 두지 않는다.
        builder: (context, child) => Stack(
          children: [
            child!,
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 50,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onLongPress: () => demoRouter.go(DemoPaths.index),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
