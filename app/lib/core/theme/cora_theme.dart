import 'package:flutter/material.dart';

import 'cora_colors.dart';
import 'cora_shapes.dart';
import 'cora_text_styles.dart';

/// 입력칸 모양. 테두리 실선 하나에 모서리 16. 오류 문구는 입력칸 밖에 따로 보여 주므로
/// 오류 테두리(기본값은 시드에서 나온 빨강)는 쓰지 않는다.
InputDecorationThemeData _inputDecoration(CoraColors c) {
  OutlineInputBorder outline(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(CoraRadius.md),
        borderSide: BorderSide(color: color, width: width),
      );
  // 떠오른 라벨은 이 크기에서 0.75배로 줄어든다. 크기를 같게 둬야 줄어든 뒤 12px가 된다.
  final label = CoraTextStyles.bodyLarge.copyWith(color: c.textSecondary);
  return InputDecorationThemeData(
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    labelStyle: label,
    floatingLabelStyle: label,
    hintStyle: label,
    border: outline(c.line),
    enabledBorder: outline(c.line),
    disabledBorder: outline(c.line),
    focusedBorder: outline(c.text, 1.5),
  );
}

/// 시드(라임)에서 파생되는 색이 화면에 나오지 않게 Material 역할을 모두 토큰으로 덮는다.
/// 입력칸·다이얼로그·시트·스낵바 같은 기본 위젯이 이 역할을 읽는다.
/// 캔버스에는 오류 빨강이 없다(오류는 글자색으로 보여 준다). 그래서 error 계열도 토큰이다.
ColorScheme _colorScheme(Brightness brightness, CoraColors c) {
  return ColorScheme(
    brightness: brightness,
    primary: c.primaryAction,
    onPrimary: c.onPrimaryAction,
    primaryContainer: c.surfaceMuted,
    onPrimaryContainer: c.onSurfaceMuted,
    secondary: c.text,
    onSecondary: c.background,
    secondaryContainer: c.surfaceSelected,
    onSecondaryContainer: c.onSurfaceSelected,
    tertiary: c.accent,
    onTertiary: c.onAccent,
    tertiaryContainer: c.accent,
    onTertiaryContainer: c.onAccent,
    error: c.text,
    onError: c.background,
    errorContainer: c.surface,
    onErrorContainer: c.text,
    surface: c.background,
    onSurface: c.text,
    onSurfaceVariant: c.textSecondary,
    surfaceDim: c.background,
    surfaceBright: c.background,
    surfaceContainerLowest: c.background,
    surfaceContainerLow: c.surface,
    surfaceContainer: c.surface,
    surfaceContainerHigh: c.surface,
    surfaceContainerHighest: c.line,
    outline: c.textSecondary,
    outlineVariant: c.line,
    shadow: c.scrim,
    scrim: c.scrim,
    inverseSurface: c.text,
    onInverseSurface: c.background,
    inversePrimary: c.accent,
    surfaceTint: Colors.transparent,
  );
}

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
    colorScheme: _colorScheme(brightness, c),
    textTheme: textTheme,
    inputDecorationTheme: _inputDecoration(c),
    // 기본 커서색은 colorScheme.primary(라이트에서 라임)라 흰 바탕에서 거의 안 보인다.
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.text,
      selectionHandleColor: c.text,
    ),
    dividerColor: c.line,
    extensions: [c],
  );
}

final ThemeData coraLightTheme = _build(Brightness.light, CoraColors.light);
final ThemeData coraDarkTheme = _build(Brightness.dark, CoraColors.dark);
