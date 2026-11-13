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
  'photoPlaceholder': c.photoPlaceholder,
  'onPhoto': c.onPhoto,
  'photoChip': c.photoChip,
  'onPhotoChip': c.onPhotoChip,
  'photoScrim': c.photoScrim,
  'subtleAction': c.subtleAction,
  'onSubtleAction': c.onSubtleAction,
  'focusRing': c.focusRing,
  'stepPill': c.stepPill,
  'onStepPill': c.onStepPill,
  'stepPillShadow': c.stepPillShadow,
  'progressTrack': c.progressTrack,
  'progressFill': c.progressFill,
  'navSurface': c.navSurface,
  'navActive': c.navActive,
  'navInactive': c.navInactive,
  'navShadow': c.navShadow,
  'highlightAction': c.highlightAction,
  'onHighlightAction': c.onHighlightAction,
  'avatarPlaceholder': c.avatarPlaceholder,
  'avatarEditButton': c.avatarEditButton,
  'avatarEditShadow': c.avatarEditShadow,
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
    case 'photoPlaceholder':
      return c.copyWith(photoPlaceholder: color);
    case 'onPhoto':
      return c.copyWith(onPhoto: color);
    case 'photoChip':
      return c.copyWith(photoChip: color);
    case 'onPhotoChip':
      return c.copyWith(onPhotoChip: color);
    case 'photoScrim':
      return c.copyWith(photoScrim: color);
    case 'subtleAction':
      return c.copyWith(subtleAction: color);
    case 'onSubtleAction':
      return c.copyWith(onSubtleAction: color);
    case 'focusRing':
      return c.copyWith(focusRing: color);
    case 'stepPill':
      return c.copyWith(stepPill: color);
    case 'onStepPill':
      return c.copyWith(onStepPill: color);
    case 'stepPillShadow':
      return c.copyWith(stepPillShadow: color);
    case 'progressTrack':
      return c.copyWith(progressTrack: color);
    case 'progressFill':
      return c.copyWith(progressFill: color);
    case 'navSurface':
      return c.copyWith(navSurface: color);
    case 'navActive':
      return c.copyWith(navActive: color);
    case 'navInactive':
      return c.copyWith(navInactive: color);
    case 'navShadow':
      return c.copyWith(navShadow: color);
    case 'highlightAction':
      return c.copyWith(highlightAction: color);
    case 'onHighlightAction':
      return c.copyWith(onHighlightAction: color);
    case 'avatarPlaceholder':
      return c.copyWith(avatarPlaceholder: color);
    case 'avatarEditButton':
      return c.copyWith(avatarEditButton: color);
    case 'avatarEditShadow':
      return c.copyWith(avatarEditShadow: color);
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
    // NLogin 사진 상자 바탕, 사진 위 글자와 알약, 아래 그라데이션 끝
    expect(c.photoPlaceholder, const Color(0xFFE8DDCB));
    expect(c.onPhoto, const Color(0xFFFFFFFF));
    expect(c.photoChip, const Color(0xEBFFFFFF)); // rgba(255,255,255,0.92)
    expect(c.onPhotoChip, const Color(0xFF17181C));
    expect(c.photoScrim, const Color(0x9917181C)); // rgba(23,24,28,0.6)
    // NVerify `다시 보내기`
    expect(c.subtleAction, const Color(0xFFF2F3F5));
    expect(c.onSubtleAction, const Color(0xFF17181C));
    // NVerify 지금 입력할 칸의 안쪽 테두리
    expect(
      c.focusRing,
      const Color(0xFF17181C),
    ); // NStoreLink 머리글 알약 #FFFFFF·#17181C·그림자 rgba(23,24,28,0.10), 막대 #E6E8EB/#17181C
    expect(c.stepPill, const Color(0xFFFFFFFF));
    expect(c.onStepPill, const Color(0xFF17181C));
    expect(c.stepPillShadow, const Color(0x1A17181C));
    expect(c.progressTrack, const Color(0xFFE6E8EB));
    expect(c.progressFill, const Color(0xFF17181C));
    // NStoreHome 하단 메뉴 #FFFFFF, 선택 #17181C, 꺼짐 #8B9099, 그림자 rgba(23,24,28,0.12)
    expect(c.navSurface, const Color(0xFFFFFFFF));
    expect(c.navActive, const Color(0xFF17181C));
    expect(c.navInactive, const Color(0xFF8B9099));
    expect(c.navShadow, const Color(0x1F17181C));
    // NStoreHome `오퍼 보내기` #C6FF3D/#1F2A00
    expect(c.highlightAction, const Color(0xFFC6FF3D));
    expect(c.onHighlightAction, const Color(0xFF1F2A00));
    // NEditProfile 사진 자리 #D9DCE6, 사진 바꾸기 버튼 #FFFFFF, 그림자 rgba(23,24,28,0.16)
    expect(c.avatarPlaceholder, const Color(0xFFD9DCE6));
    expect(c.avatarEditButton, const Color(0xFFFFFFFF));
    expect(c.avatarEditShadow, const Color(0x2917181C));
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
    // DarkNLogin의 사진 상자·알약·그라데이션은 라이트와 같다.
    expect(c.photoPlaceholder, const Color(0xFFE8DDCB));
    expect(c.onPhoto, const Color(0xFFFFFFFF));
    expect(c.photoChip, const Color(0xEBFFFFFF));
    expect(c.onPhotoChip, const Color(0xFF17181C));
    expect(c.photoScrim, const Color(0x9917181C));
    // DarkNVerify `다시 보내기` 바탕 #2A2D33, 글자 #F2F3F5
    expect(c.subtleAction, const Color(0xFF2A2D33));
    expect(c.onSubtleAction, const Color(0xFFF2F3F5));
    // 캔버스가 다크에서도 #17181C를 그대로 쓴다(어두운 바탕에서 거의 안 보인다).
    expect(
      c.focusRing,
      const Color(0xFF17181C),
    ); // DarkNStoreLink 머리글 알약 #F2F3F5·#17181C·그림자 없음, 막대 #2A2D33/#0F1012
    expect(c.stepPill, const Color(0xFFF2F3F5));
    expect(c.onStepPill, const Color(0xFF17181C));
    expect(c.stepPillShadow, const Color(0x0017181C));
    expect(c.progressTrack, const Color(0xFF2A2D33));
    expect(c.progressFill, const Color(0xFFF2F3F5));
    // DarkNStoreHome 하단 메뉴 #26282D, 선택 #C6FF3D, 꺼짐 #A0A4AD, 그림자 rgba(23,24,28,0.28)
    expect(c.navSurface, const Color(0xFF26282D));
    expect(c.navActive, const Color(0xFFC6FF3D));
    expect(c.navInactive, const Color(0xFFA0A4AD));
    expect(c.navShadow, const Color(0x4717181C));
    // DarkNStoreHome `오퍼 보내기` #F2F3F5/#0F1012
    // DarkNStoreHome(2026-11-12)는 라이트처럼 라임이다.
    expect(c.highlightAction, const Color(0xFFC6FF3D));
    expect(c.onHighlightAction, const Color(0xFF1F2A00));
    // DarkNEditProfile 사진 자리 #D9DCE6, 사진 바꾸기 버튼 #2A2D33, 그림자 rgba(0,0,0,0.4)
    expect(c.avatarPlaceholder, const Color(0xFFD9DCE6));
    expect(c.avatarEditButton, const Color(0xFF2A2D33));
    expect(c.avatarEditShadow, const Color(0x66000000));
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

  test('G1 compare bar matches NResult and DarkNResult', () {
    expect(CoraColors.light.compareBarNow, const Color(0xFF17181C));
    expect(CoraColors.dark.compareBarNow, const Color(0xFF0F1012));
    expect(
      CoraColors.light.lerp(CoraColors.dark, 1).compareBarNow,
      const Color(0xFF0F1012),
    );
    expect(
      CoraColors.light
          .copyWith(compareBarNow: const Color(0xFF123456))
          .compareBarNow,
      const Color(0xFF123456),
    );
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
