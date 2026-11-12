import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import '../../core/theme/cora_theme.dart';
import 'demo_router.dart';

/// 모든 화면에서 iOS 가장자리 밀기로 뒤로 갈 수 있게 한다.
const _cupertino = PageTransitionsTheme(
  builders: {
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.android: CupertinoPageTransitionsBuilder(),
  },
);

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Cora',
      debugShowCheckedModeBanner: false,
      theme: coraLightTheme.copyWith(
        pageTransitionsTheme: _cupertino,
        inputDecorationTheme: const InputDecorationThemeData(),
      ),
      darkTheme: coraDarkTheme.copyWith(
        pageTransitionsTheme: _cupertino,
        inputDecorationTheme: const InputDecorationThemeData(),
      ),
      // 라이트·다크는 기기 설정을 따른다.
      themeMode: ThemeMode.system,
      routerConfig: demoRouter,
    );
  }
}
