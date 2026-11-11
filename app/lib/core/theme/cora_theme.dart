import 'package:flutter/material.dart';

import 'cora_colors.dart';
import 'cora_text_styles.dart';

ThemeData _build(Brightness brightness, CoraColors c) {
  // 색은 텍스트 스타일에 굽지 않고 여기서 기본 글자색으로만 입힌다.
  final textTheme = TextTheme(
    displayLarge: CoraTextStyles.display,
    headlineLarge: CoraTextStyles.title,
    titleLarge: CoraTextStyles.heading,
    bodyLarge: CoraTextStyles.bodyLarge,
    bodyMedium: CoraTextStyles.body,
    labelLarge: CoraTextStyles.button,
    labelMedium: CoraTextStyles.label,
    labelSmall: CoraTextStyles.caption,
  ).apply(fontFamily: 'NotoSansKR', bodyColor: c.text, displayColor: c.text);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: 'NotoSansKR',
    scaffoldBackgroundColor: c.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: c.accent,
      brightness: brightness,
    ).copyWith(
      surface: c.background,
      onSurface: c.text,
      primary: c.primaryAction,
      onPrimary: c.onPrimaryAction,
      outlineVariant: c.line,
    ),
    textTheme: textTheme,
    dividerColor: c.line,
    extensions: [c],
  );
}

final ThemeData coraLightTheme = _build(Brightness.light, CoraColors.light);
final ThemeData coraDarkTheme = _build(Brightness.dark, CoraColors.dark);
