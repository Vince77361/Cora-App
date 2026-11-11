import 'package:flutter/material.dart';

/// 기획 캔버스에서 확정한 색 토큰. 위젯은 색을 직접 쓰지 않고 `context.colors`로 가져온다.
@immutable
class CoraColors extends ThemeExtension<CoraColors> {
  const CoraColors({
    required this.background,
    required this.text,
    required this.textSecondary,
    required this.accent,
    required this.onAccent,
    required this.surface,
    required this.surfaceSelected,
    required this.onSurfaceSelected,
    required this.surfaceMuted,
    required this.onSurfaceMuted,
    required this.line,
    required this.primaryAction,
    required this.onPrimaryAction,
    required this.selectionDot,
    required this.onSelectionDot,
    required this.glass,
    required this.scrim,
  });

  final Color background;
  final Color text;
  final Color textSecondary;
  final Color accent;
  final Color onAccent;
  final Color surface;
  final Color surfaceSelected;
  final Color onSurfaceSelected;
  final Color surfaceMuted;
  final Color onSurfaceMuted;
  final Color line;
  final Color primaryAction;
  final Color onPrimaryAction;
  final Color selectionDot;
  final Color onSelectionDot;

  /// 유리 카드(`CoraGlassCard`)의 반투명 채움. 뒤를 흐리게 비춘다.
  final Color glass;

  /// 화면 전환 중 뒤 화면을 어둡게 덮는 색과 시트 뒤 바탕색. 알파는 `CoraMotion`이 정한다.
  /// 다크에서 `text`(#F2F3F5)를 쓰면 오히려 밝아지므로 따로 둔다.
  final Color scrim;

  static const light = CoraColors(
    background: Color(0xFFFFFFFF),
    text: Color(0xFF17181C),
    textSecondary: Color(0xFF5C6068),
    accent: Color(0xFFC6FF3D),
    onAccent: Color(0xFF1F2A00),
    surface: Color(0xFFF8F9FA),
    surfaceSelected: Color(0xFFE3E5E9),
    onSurfaceSelected: Color(0xFF17181C),
    surfaceMuted: Color(0xFFF2F3F5),
    onSurfaceMuted: Color(0xFF17181C),
    line: Color(0xFFE6E8EB),
    primaryAction: Color(0xFFC6FF3D),
    onPrimaryAction: Color(0xFF1F2A00),
    selectionDot: Color(0xFFC6FF3D),
    onSelectionDot: Color(0xFF1F2A00),
    // Principles 유리 카드 rgba(255,255,255,0.75)
    glass: Color(0xBFFFFFFF),
    // 캔버스의 그림자·사진 덮개 잉크 rgba(23,24,28)
    scrim: Color(0xFF17181C),
  );

  // 다크의 surface, surfaceMuted, onAccent는 DarkPrinciples/DarkNEscrow/DarkNStoreHome에서
  // 라이트와 같은 자리에 쓰인 색을 그대로 옮겼다.
  // surfaceMuted는 다크에서도 밝은 채움(#F2F3F5)이다. DarkPrinciples `다시 고르기`
  // (background #F2F3F5, color #17181C)와 DarkNStoreHome `릴스로 찾기`가 다크에서도
  // 밝은 보조 버튼을 그대로 쓴다. 그래서 그 위 글자는 `text`(다크에서 #F2F3F5)가 아니라
  // 어두운 onSurfaceMuted(#17181C)여야 한다. `text`를 쓰면 글자가 안 보인다.
  static const dark = CoraColors(
    background: Color(0xFF0F1012),
    text: Color(0xFFF2F3F5),
    textSecondary: Color(0xFFA0A4AD),
    accent: Color(0xFFC6FF3D),
    onAccent: Color(0xFF1F2A00),
    surface: Color(0xFF1C1E22),
    surfaceSelected: Color(0xFFF2F3F5),
    onSurfaceSelected: Color(0xFF0F1012),
    surfaceMuted: Color(0xFFF2F3F5),
    onSurfaceMuted: Color(0xFF17181C),
    line: Color(0xFF2A2D33),
    primaryAction: Color(0xFFF2F3F5),
    onPrimaryAction: Color(0xFF17181C),
    selectionDot: Color(0xFF0F1012),
    onSelectionDot: Color(0xFFF2F3F5),
    // DarkPrinciples 유리 카드 rgba(28,30,34,0.85)
    glass: Color(0xD91C1E22),
    // 다크 배경(#0F1012)보다 어두워야 덮었을 때 어두워진다. 캔버스의 rgba(0,0,0,…) 그림자와 같은 검정.
    scrim: Color(0xFF000000),
  );

  @override
  CoraColors copyWith({
    Color? background,
    Color? text,
    Color? textSecondary,
    Color? accent,
    Color? onAccent,
    Color? surface,
    Color? surfaceSelected,
    Color? onSurfaceSelected,
    Color? surfaceMuted,
    Color? onSurfaceMuted,
    Color? line,
    Color? primaryAction,
    Color? onPrimaryAction,
    Color? selectionDot,
    Color? onSelectionDot,
    Color? glass,
    Color? scrim,
  }) {
    return CoraColors(
      background: background ?? this.background,
      text: text ?? this.text,
      textSecondary: textSecondary ?? this.textSecondary,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      surface: surface ?? this.surface,
      surfaceSelected: surfaceSelected ?? this.surfaceSelected,
      onSurfaceSelected: onSurfaceSelected ?? this.onSurfaceSelected,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      onSurfaceMuted: onSurfaceMuted ?? this.onSurfaceMuted,
      line: line ?? this.line,
      primaryAction: primaryAction ?? this.primaryAction,
      onPrimaryAction: onPrimaryAction ?? this.onPrimaryAction,
      selectionDot: selectionDot ?? this.selectionDot,
      onSelectionDot: onSelectionDot ?? this.onSelectionDot,
      glass: glass ?? this.glass,
      scrim: scrim ?? this.scrim,
    );
  }

  @override
  CoraColors lerp(ThemeExtension<CoraColors>? other, double t) {
    if (other is! CoraColors) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return CoraColors(
      background: mix(background, other.background),
      text: mix(text, other.text),
      textSecondary: mix(textSecondary, other.textSecondary),
      accent: mix(accent, other.accent),
      onAccent: mix(onAccent, other.onAccent),
      surface: mix(surface, other.surface),
      surfaceSelected: mix(surfaceSelected, other.surfaceSelected),
      onSurfaceSelected: mix(onSurfaceSelected, other.onSurfaceSelected),
      surfaceMuted: mix(surfaceMuted, other.surfaceMuted),
      onSurfaceMuted: mix(onSurfaceMuted, other.onSurfaceMuted),
      line: mix(line, other.line),
      primaryAction: mix(primaryAction, other.primaryAction),
      onPrimaryAction: mix(onPrimaryAction, other.onPrimaryAction),
      selectionDot: mix(selectionDot, other.selectionDot),
      onSelectionDot: mix(onSelectionDot, other.onSelectionDot),
      glass: mix(glass, other.glass),
      scrim: mix(scrim, other.scrim),
    );
  }
}

extension CoraThemeX on BuildContext {
  /// 현재 테마(라이트/다크)의 색 토큰.
  CoraColors get colors => Theme.of(this).extension<CoraColors>()!;
}
