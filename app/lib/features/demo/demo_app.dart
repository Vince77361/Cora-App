import 'package:flutter/material.dart';

import '../../core/theme/cora_theme.dart';
import 'demo_router.dart';

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
        theme: coraLightTheme,
        darkTheme: coraDarkTheme,
        themeMode: mode,
        routerConfig: demoRouter,
      ),
    );
  }
}
