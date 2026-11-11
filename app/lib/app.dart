import 'package:flutter/material.dart';

import 'core/theme/cora_theme.dart';

/// 임시 앱 껍데기. 라우팅과 화면은 Task 9에서 채운다.
class CoraApp extends StatelessWidget {
  const CoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cora',
      theme: coraLightTheme,
      darkTheme: coraDarkTheme,
      themeMode: ThemeMode.system,
      home: const Scaffold(),
    );
  }
}
