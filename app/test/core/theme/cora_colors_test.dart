import 'dart:ui';

import 'package:cora/core/theme/cora_colors.dart';
import 'package:flutter_test/flutter_test.dart';

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
    expect(c.line, const Color(0xFFE6E8EB));
    expect(c.primaryAction, const Color(0xFFC6FF3D));
    expect(c.onPrimaryAction, const Color(0xFF1F2A00));
    expect(c.selectionDot, const Color(0xFFC6FF3D));
    expect(c.onSelectionDot, const Color(0xFF1F2A00));
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
    expect(c.surfaceMuted, const Color(0xFFF2F3F5));
    expect(c.line, const Color(0xFF2A2D33));
    expect(c.primaryAction, const Color(0xFFF2F3F5));
    expect(c.onPrimaryAction, const Color(0xFF17181C));
    expect(c.selectionDot, const Color(0xFF0F1012));
    expect(c.onSelectionDot, const Color(0xFFF2F3F5));
  });

  test('copyWith replaces only the given field', () {
    final c = CoraColors.light.copyWith(accent: const Color(0xFF000000));
    expect(c.accent, const Color(0xFF000000));
    expect(c.text, CoraColors.light.text);
  });

  test('lerp returns the endpoints at t=0 and t=1', () {
    expect(CoraColors.light.lerp(CoraColors.dark, 0).background, CoraColors.light.background);
    expect(CoraColors.light.lerp(CoraColors.dark, 1).background, CoraColors.dark.background);
    expect(CoraColors.light.lerp(CoraColors.dark, 1).surface, CoraColors.dark.surface);
  });
}
