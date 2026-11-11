import 'package:cora/core/theme/cora_theme.dart';
import 'package:flutter/material.dart';

/// 공용 위젯을 Cora 테마 안에 띄운다. 글자 배율과 움직임 줄이기는 기기 설정처럼
/// MediaQuery로 넣는다.
Widget coraTestApp(
  Widget child, {
  ThemeData? theme,
  TextScaler? textScaler,
  bool disableAnimations = false,
}) {
  return MaterialApp(
    theme: theme ?? coraLightTheme,
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: textScaler, disableAnimations: disableAnimations),
      child: app!,
    ),
    home: Scaffold(
      body: Center(
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );
}
