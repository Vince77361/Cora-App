import 'dart:ui';

import 'package:cora/core/theme/cora_colors.dart';
import 'package:flutter_test/flutter_test.dart';

/// 모든 필드를 이름과 함께 나열한다. 필드가 바뀌어 짝이 어긋나면 아래 테스트가 잡는다.
Map<String, Color> _fields(CoraColors c) => {
  'background': c.background,
  'text': c.text,
  'textSecondary': c.textSecondary,
  'accent': c.accent,
  'onAccent': c.onAccent,
  'surface': c.surface,
  'surfaceSelected': c.surfaceSelected,
  'onSurfaceSelected': c.onSurfaceSelected,
  'surfaceMuted': c.surfaceMuted,
  'onSurfaceMuted': c.onSurfaceMuted,
  'line': c.line,
  'primaryAction': c.primaryAction,
  'onPrimaryAction': c.onPrimaryAction,
  'selectionDot': c.selectionDot,
  'onSelectionDot': c.onSelectionDot,
  'glass': c.glass,
  'scrim': c.scrim,
};

/// 이름으로 필드 하나만 [color]로 바꾼 사본을 만든다.
CoraColors _copyWithField(CoraColors c, String name, Color color) {
  switch (name) {
    case 'background':
      return c.copyWith(background: color);
    case 'text':
      return c.copyWith(text: color);
    case 'textSecondary':
      return c.copyWith(textSecondary: color);
    case 'accent':
      return c.copyWith(accent: color);
    case 'onAccent':
      return c.copyWith(onAccent: color);
    case 'surface':
      return c.copyWith(surface: color);
    case 'surfaceSelected':
      return c.copyWith(surfaceSelected: color);
    case 'onSurfaceSelected':
      return c.copyWith(onSurfaceSelected: color);
    case 'surfaceMuted':
      return c.copyWith(surfaceMuted: color);
    case 'onSurfaceMuted':
      return c.copyWith(onSurfaceMuted: color);
    case 'line':
      return c.copyWith(line: color);
    case 'primaryAction':
      return c.copyWith(primaryAction: color);
    case 'onPrimaryAction':
      return c.copyWith(onPrimaryAction: color);
    case 'selectionDot':
      return c.copyWith(selectionDot: color);
    case 'onSelectionDot':
      return c.copyWith(onSelectionDot: color);
    case 'glass':
      return c.copyWith(glass: color);
    case 'scrim':
      return c.copyWith(scrim: color);
  }
  throw ArgumentError(name);
}

void _expectSameFields(CoraColors actual, CoraColors expected) {
  final a = _fields(actual);
  final e = _fields(expected);
  for (final name in e.keys) {
    expect(a[name], e[name], reason: name);
  }
}

void main() {
  test('light palette matches the design canvas', () {
    const c = CoraColors.light;
    expect(c.background, const Color(0xFFFFFFFF));
    expect(c.text, const Color(0xFF17181C));
    expect(c.textSecondary, const Color(0xFF5C6068));
    expect(c.accent, const Color(0xFFC6FF3D));
    expect(c.onAccent, const Color(0xFF1F2A00));
    expect(c.surface, const Color(0xFFF8F9FA));
    expect(c.surfaceSelected, const Color(0xFFE3E5E9));
    expect(c.onSurfaceSelected, const Color(0xFF17181C));
    expect(c.surfaceMuted, const Color(0xFFF2F3F5));
    expect(c.onSurfaceMuted, const Color(0xFF17181C));
    expect(c.line, const Color(0xFFE6E8EB));
    expect(c.primaryAction, const Color(0xFFC6FF3D));
    expect(c.onPrimaryAction, const Color(0xFF1F2A00));
    expect(c.selectionDot, const Color(0xFFC6FF3D));
    expect(c.onSelectionDot, const Color(0xFF1F2A00));
    // Principles 유리 카드 rgba(255,255,255,0.75)
    expect(c.glass, const Color(0xBFFFFFFF));
    // 캔버스 그림자 잉크 rgba(23,24,28)
    expect(c.scrim, const Color(0xFF17181C));
  });

  test('dark palette matches the design canvas', () {
    const c = CoraColors.dark;
    expect(c.background, const Color(0xFF0F1012));
    expect(c.text, const Color(0xFFF2F3F5));
    expect(c.textSecondary, const Color(0xFFA0A4AD));
    expect(c.accent, const Color(0xFFC6FF3D));
    expect(c.onAccent, const Color(0xFF1F2A00));
    expect(c.surface, const Color(0xFF1C1E22));
    expect(c.surfaceSelected, const Color(0xFFF2F3F5));
    expect(c.onSurfaceSelected, const Color(0xFF0F1012));
    // 다크에서도 밝은 보조 버튼 채움(#F2F3F5)에 어두운 글자(#17181C)를 쓴다.
    expect(c.surfaceMuted, const Color(0xFFF2F3F5));
    expect(c.onSurfaceMuted, const Color(0xFF17181C));
    expect(c.line, const Color(0xFF2A2D33));
    expect(c.primaryAction, const Color(0xFFF2F3F5));
    expect(c.onPrimaryAction, const Color(0xFF17181C));
    expect(c.selectionDot, const Color(0xFF0F1012));
    expect(c.onSelectionDot, const Color(0xFFF2F3F5));
    // DarkPrinciples 유리 카드 rgba(28,30,34,0.85)
    expect(c.glass, const Color(0xD91C1E22));
    // 다크 배경(#0F1012)보다 어두워야 덮었을 때 화면이 어두워진다.
    expect(c.scrim, const Color(0xFF000000));
  });

  test('copyWith with no arguments keeps every field', () {
    _expectSameFields(CoraColors.light.copyWith(), CoraColors.light);
    _expectSameFields(CoraColors.dark.copyWith(), CoraColors.dark);
  });

  test('copyWith of each field changes only that field', () {
    const marker = Color(0xFF123456);
    final base = _fields(CoraColors.light);
    for (final name in base.keys) {
      final changed = _fields(_copyWithField(CoraColors.light, name, marker));
      for (final other in base.keys) {
        expect(
          changed[other],
          other == name ? marker : base[other],
          reason: 'copyWith($name) -> $other',
        );
      }
    }
  });

  test('lerp returns the endpoints field by field', () {
    _expectSameFields(
      CoraColors.light.lerp(CoraColors.dark, 0),
      CoraColors.light,
    );
    _expectSameFields(
      CoraColors.light.lerp(CoraColors.dark, 1),
      CoraColors.dark,
    );
  });

  test('lerp moves every field to the midpoint', () {
    final mid = _fields(CoraColors.light.lerp(CoraColors.dark, 0.5));
    final a = _fields(CoraColors.light);
    final b = _fields(CoraColors.dark);
    for (final name in a.keys) {
      expect(mid[name], Color.lerp(a[name], b[name], 0.5), reason: name);
    }
  });

  test('lerp with a different extension type returns this', () {
    expect(CoraColors.light.lerp(null, 0.5), same(CoraColors.light));
  });
}
