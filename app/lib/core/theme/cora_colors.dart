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
    required this.photoPlaceholder,
    required this.onPhoto,
    required this.photoChip,
    required this.onPhotoChip,
    required this.photoScrim,
    required this.subtleAction,
    required this.onSubtleAction,
    required this.focusRing,
    required this.stepPill,
    required this.onStepPill,
    required this.stepPillShadow,
    required this.progressTrack,
    required this.progressFill,
    required this.navSurface,
    required this.navActive,
    required this.navInactive,
    required this.navShadow,
    required this.highlightAction,
    required this.onHighlightAction,
    required this.avatarPlaceholder,
    required this.avatarEditButton,
    required this.avatarEditShadow,
    required this.coverPlaceholder,
    required this.onPhotoSecondary,
    required this.softAction,
    required this.onSoftAction,
    required this.slideTint,
    required this.onSlideTint,
    required this.slideNeutral,
    required this.onSlideNeutral,
    required this.onSlidePhoto,
    this.creatorPhotoPlaceholder = const Color(0xFFF3E3D3),
    this.stepDotDone = const Color(0xFFE6E8EB),
    this.onStepDotDone = const Color(0xFF17181C),
    this.stepDotNow = const Color(0xFFC6FF3D),
    this.onStepDotNow = const Color(0xFF1F2A00),
    this.chipAction = const Color(0xFFFFFFFF),
    this.onChipAction = const Color(0xFF17181C),
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

  /// 사진이 뜨기 전 사진 상자의 바탕(NLogin). 라이트·다크가 같다.
  final Color photoPlaceholder;

  /// 사진 위에 얹는 글자(NLogin 사진 아래 문구). 사진은 모드와 상관없이 같으므로 늘 흰색이다.
  final Color onPhoto;

  /// 사진 위의 알약 바탕(NLogin `#민의옷장기록 · 릴스 0:30`)과 그 위 글자.
  final Color photoChip;
  final Color onPhotoChip;

  /// 사진 아래쪽을 어둡게 눕히는 그라데이션의 끝 색(NLogin). 시작은 같은 색의 투명이다.
  final Color photoScrim;

  /// 작은 보조 버튼의 채움과 그 위 글자(NVerify `다시 보내기`). `surfaceMuted`와 달리
  /// 다크에서는 어두운 채움(#2A2D33)에 밝은 글자다.
  final Color subtleAction;
  final Color onSubtleAction;

  /// 지금 입력할 칸의 안쪽 테두리(NVerify 인증번호 칸). 캔버스가 다크에서도 #17181C를 그대로
  /// 써서 다크에서는 거의 보이지 않는다. 캔버스를 그대로 옮긴 값이다.
  final Color focusRing;

  /// 단계 머리글(`CoraStepHeader`) 가운데 알약의 바탕, 그 위 글자, 그림자 색(NStoreLink).
  /// 라이트는 흰 알약에 그림자 rgba(23,24,28,0.10), 다크는 밝은 알약에 그림자가 없다.
  final Color stepPill;
  final Color onStepPill;
  final Color stepPillShadow;

  /// 단계 진행 막대의 바탕과 채움(NStoreLink). 다크의 채움(#0F1012)은 바탕(#2A2D33)보다
  /// 어둡다. 캔버스 그대로다.
  final Color progressTrack;
  final Color progressFill;

  /// 하단 메뉴(`CoraBottomNav`)의 바탕, 선택된 항목, 꺼진 항목, 그림자 색(NStoreHome).
  /// 다크는 선택 항목이 라임이고 그림자가 더 진하다(rgba(23,24,28,0.28)).
  final Color navSurface;
  final Color navActive;
  final Color navInactive;
  final Color navShadow;

  /// 목록 줄 오른쪽 버튼 중 강조하는 것(NStoreHome `오퍼 보내기`)의 채움과 글자.
  /// 라이트는 라임, 다크는 밝은 회색이다.
  final Color highlightAction;
  final Color onHighlightAction;

  /// A3 대표 사진 상자와 A4 사진 장면의 바탕(사진이 뜨기 전, 사진이 없을 때). 라이트·다크가 같다.
  final Color coverPlaceholder;

  /// 사진 위의 보조 글자(NStorePage `라멘집, 성수동`). 사진은 모드와 상관없이 같아서 라이트·다크가 같다.
  final Color onPhotoSecondary;

  /// 카드 안의 작은 알약 버튼(NStorePage `고치기`)의 채움 rgba(31,42,0,0.08)과 글자. 다크에서도 채움이 같고 글자만 밝은 라임(#E4FFB0)이다.
  final Color softAction;
  final Color onSoftAction;

  /// A4 사진 없는 슬라이드의 두 톤(NStoreAI `tones`). 첫 톤은 라이트·다크가 같고, 둘째 톤은 라이트가 연한 회색, 다크가 밝은 회색이다. 사진 위 글자(`onSlidePhoto`)는 다크에서 #0F1012다(캔버스 그대로).
  final Color slideTint;
  final Color onSlideTint;
  final Color slideNeutral;
  final Color onSlideNeutral;
  final Color onSlidePhoto;

  /// A8 결제 화면 머리의 크리에이터 사진이 뜨기 전·없을 때의 바탕(NPay). 라이트·다크가 같다.
  final Color creatorPhotoPlaceholder;

  /// A7 협업 진행의 단계 점(NEscrow): 끝난 단계와 지금 단계의 바탕과 그 안의 글자. 남은 단계는
  /// `surface`/`textSecondary`다. 라이트는 끝남 #E6E8EB/#17181C, 지금 라임/#1F2A00이고, 다크는
  /// 끝남이 #F2F3F5에 라임 ✓, 지금이 #F2F3F5에 #0F1012다(DarkNEscrow).
  final Color stepDotDone;
  final Color onStepDotDone;
  final Color stepDotNow;
  final Color onStepDotNow;

  /// `surface` 카드 안의 작은 알약 버튼(NWallet `계좌 변경`). 라이트·다크 모두 흰 바탕에 #17181C 글자다.
  final Color chipAction;
  final Color onChipAction;

  /// 프로필 원형 사진 자리의 바탕, 그 위 `사진 바꾸기` 둥근 버튼의 채움과 그림자 색
  /// (NEditProfile). 사진 자리 바탕은 라이트·다크가 같다.
  final Color avatarPlaceholder;
  final Color avatarEditButton;
  final Color avatarEditShadow;

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
    // NLogin: 사진 상자 #E8DDCB, 알약 rgba(255,255,255,0.92), 그라데이션 끝 rgba(23,24,28,0.6)
    photoPlaceholder: Color(0xFFE8DDCB),
    onPhoto: Color(0xFFFFFFFF),
    photoChip: Color(0xEBFFFFFF),
    onPhotoChip: Color(0xFF17181C),
    photoScrim: Color(0x9917181C),
    // NVerify `다시 보내기` #F2F3F5 / #17181C, 입력 칸 테두리 #17181C
    subtleAction: Color(0xFFF2F3F5),
    onSubtleAction: Color(0xFF17181C),
    focusRing: Color(0xFF17181C),
    // NStoreLink 머리글 알약 #FFFFFF·#17181C·그림자 rgba(23,24,28,0.10), 막대 #E6E8EB/#17181C
    stepPill: Color(0xFFFFFFFF),
    onStepPill: Color(0xFF17181C),
    stepPillShadow: Color(0x1A17181C),
    progressTrack: Color(0xFFE6E8EB),
    progressFill: Color(0xFF17181C),
    // NStoreHome 하단 메뉴 #FFFFFF, 선택 #17181C, 꺼짐 #8B9099, 그림자 rgba(23,24,28,0.12)
    navSurface: Color(0xFFFFFFFF),
    navActive: Color(0xFF17181C),
    navInactive: Color(0xFF8B9099),
    navShadow: Color(0x1F17181C),
    // NStoreHome `오퍼 보내기` #C6FF3D/#1F2A00
    highlightAction: Color(0xFFC6FF3D),
    onHighlightAction: Color(0xFF1F2A00),
    avatarPlaceholder: Color(0xFFD9DCE6),
    avatarEditButton: Color(0xFFFFFFFF),
    avatarEditShadow: Color(0x2917181C),
    // NStorePage·NStoreAI 라이트
    coverPlaceholder: Color(0xFFF6E3C8),
    onPhotoSecondary: Color(0xFFE4E6EA),
    softAction: Color(0x141F2A00),
    onSoftAction: Color(0xFF1F2A00),
    slideTint: Color(0xFFF3FFD6),
    onSlideTint: Color(0xFF1F2A00),
    slideNeutral: Color(0xFFF8F9FA),
    onSlideNeutral: Color(0xFF17181C),
    onSlidePhoto: Color(0xFFFFFFFF),
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
    // DarkNLogin의 사진 상자·알약·그라데이션은 라이트와 같다.
    photoPlaceholder: Color(0xFFE8DDCB),
    onPhoto: Color(0xFFFFFFFF),
    photoChip: Color(0xEBFFFFFF),
    onPhotoChip: Color(0xFF17181C),
    photoScrim: Color(0x9917181C),
    // DarkNVerify `다시 보내기` #2A2D33 / #F2F3F5. 입력 칸 테두리는 캔버스 그대로 #17181C.
    subtleAction: Color(0xFF2A2D33),
    onSubtleAction: Color(0xFFF2F3F5),
    focusRing: Color(0xFF17181C),
    // DarkNStoreLink 머리글 알약 #F2F3F5·#17181C·그림자 없음, 막대 #2A2D33/#0F1012
    stepPill: Color(0xFFF2F3F5),
    onStepPill: Color(0xFF17181C),
    stepPillShadow: Color(0x0017181C),
    progressTrack: Color(0xFF2A2D33),
    progressFill: Color(0xFF0F1012),
    // DarkNStoreHome 하단 메뉴 #26282D, 선택 #C6FF3D, 꺼짐 #A0A4AD, 그림자 rgba(23,24,28,0.28)
    navSurface: Color(0xFF26282D),
    navActive: Color(0xFFC6FF3D),
    navInactive: Color(0xFFA0A4AD),
    navShadow: Color(0x4717181C),
    // DarkNStoreHome `오퍼 보내기` #F2F3F5/#0F1012
    highlightAction: Color(0xFFF2F3F5),
    onHighlightAction: Color(0xFF0F1012),
    avatarPlaceholder: Color(0xFFD9DCE6),
    avatarEditButton: Color(0xFF2A2D33),
    avatarEditShadow: Color(0x66000000),
    // DarkNStorePage·DarkNStoreAI
    coverPlaceholder: Color(0xFFF6E3C8),
    onPhotoSecondary: Color(0xFFE4E6EA),
    softAction: Color(0x141F2A00),
    onSoftAction: Color(0xFFE4FFB0),
    slideTint: Color(0xFFF3FFD6),
    onSlideTint: Color(0xFF1F2A00),
    slideNeutral: Color(0xFFF2F3F5),
    onSlideNeutral: Color(0xFF0F1012),
    onSlidePhoto: Color(0xFF0F1012),
    stepDotDone: Color(0xFFF2F3F5),
    onStepDotDone: Color(0xFFC6FF3D),
    stepDotNow: Color(0xFFF2F3F5),
    onStepDotNow: Color(0xFF0F1012),
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
    Color? photoPlaceholder,
    Color? onPhoto,
    Color? photoChip,
    Color? onPhotoChip,
    Color? photoScrim,
    Color? subtleAction,
    Color? onSubtleAction,
    Color? focusRing,
    Color? stepPill,
    Color? onStepPill,
    Color? stepPillShadow,
    Color? progressTrack,
    Color? progressFill,
    Color? navSurface,
    Color? navActive,
    Color? navInactive,
    Color? navShadow,
    Color? highlightAction,
    Color? onHighlightAction,
    Color? avatarPlaceholder,
    Color? avatarEditButton,
    Color? avatarEditShadow,
    Color? coverPlaceholder,
    Color? onPhotoSecondary,
    Color? softAction,
    Color? onSoftAction,
    Color? slideTint,
    Color? onSlideTint,
    Color? slideNeutral,
    Color? onSlideNeutral,
    Color? onSlidePhoto,
    Color? creatorPhotoPlaceholder,
    Color? stepDotDone,
    Color? onStepDotDone,
    Color? stepDotNow,
    Color? onStepDotNow,
    Color? chipAction,
    Color? onChipAction,
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
      photoPlaceholder: photoPlaceholder ?? this.photoPlaceholder,
      onPhoto: onPhoto ?? this.onPhoto,
      photoChip: photoChip ?? this.photoChip,
      onPhotoChip: onPhotoChip ?? this.onPhotoChip,
      photoScrim: photoScrim ?? this.photoScrim,
      subtleAction: subtleAction ?? this.subtleAction,
      onSubtleAction: onSubtleAction ?? this.onSubtleAction,
      focusRing: focusRing ?? this.focusRing,
      stepPill: stepPill ?? this.stepPill,
      onStepPill: onStepPill ?? this.onStepPill,
      stepPillShadow: stepPillShadow ?? this.stepPillShadow,
      progressTrack: progressTrack ?? this.progressTrack,
      progressFill: progressFill ?? this.progressFill,
      navSurface: navSurface ?? this.navSurface,
      navActive: navActive ?? this.navActive,
      navInactive: navInactive ?? this.navInactive,
      navShadow: navShadow ?? this.navShadow,
      highlightAction: highlightAction ?? this.highlightAction,
      onHighlightAction: onHighlightAction ?? this.onHighlightAction,
      avatarPlaceholder: avatarPlaceholder ?? this.avatarPlaceholder,
      avatarEditButton: avatarEditButton ?? this.avatarEditButton,
      avatarEditShadow: avatarEditShadow ?? this.avatarEditShadow,
      coverPlaceholder: coverPlaceholder ?? this.coverPlaceholder,
      onPhotoSecondary: onPhotoSecondary ?? this.onPhotoSecondary,
      softAction: softAction ?? this.softAction,
      onSoftAction: onSoftAction ?? this.onSoftAction,
      slideTint: slideTint ?? this.slideTint,
      onSlideTint: onSlideTint ?? this.onSlideTint,
      slideNeutral: slideNeutral ?? this.slideNeutral,
      onSlideNeutral: onSlideNeutral ?? this.onSlideNeutral,
      onSlidePhoto: onSlidePhoto ?? this.onSlidePhoto,
      creatorPhotoPlaceholder:
          creatorPhotoPlaceholder ?? this.creatorPhotoPlaceholder,
      stepDotDone: stepDotDone ?? this.stepDotDone,
      onStepDotDone: onStepDotDone ?? this.onStepDotDone,
      stepDotNow: stepDotNow ?? this.stepDotNow,
      onStepDotNow: onStepDotNow ?? this.onStepDotNow,
      chipAction: chipAction ?? this.chipAction,
      onChipAction: onChipAction ?? this.onChipAction,
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
      photoPlaceholder: mix(photoPlaceholder, other.photoPlaceholder),
      onPhoto: mix(onPhoto, other.onPhoto),
      photoChip: mix(photoChip, other.photoChip),
      onPhotoChip: mix(onPhotoChip, other.onPhotoChip),
      photoScrim: mix(photoScrim, other.photoScrim),
      subtleAction: mix(subtleAction, other.subtleAction),
      onSubtleAction: mix(onSubtleAction, other.onSubtleAction),
      focusRing: mix(focusRing, other.focusRing),
      stepPill: mix(stepPill, other.stepPill),
      onStepPill: mix(onStepPill, other.onStepPill),
      stepPillShadow: mix(stepPillShadow, other.stepPillShadow),
      progressTrack: mix(progressTrack, other.progressTrack),
      progressFill: mix(progressFill, other.progressFill),
      navSurface: mix(navSurface, other.navSurface),
      navActive: mix(navActive, other.navActive),
      navInactive: mix(navInactive, other.navInactive),
      navShadow: mix(navShadow, other.navShadow),
      highlightAction: mix(highlightAction, other.highlightAction),
      onHighlightAction: mix(onHighlightAction, other.onHighlightAction),
      avatarPlaceholder: mix(avatarPlaceholder, other.avatarPlaceholder),
      avatarEditButton: mix(avatarEditButton, other.avatarEditButton),
      avatarEditShadow: mix(avatarEditShadow, other.avatarEditShadow),
      coverPlaceholder: mix(coverPlaceholder, other.coverPlaceholder),
      onPhotoSecondary: mix(onPhotoSecondary, other.onPhotoSecondary),
      softAction: mix(softAction, other.softAction),
      onSoftAction: mix(onSoftAction, other.onSoftAction),
      slideTint: mix(slideTint, other.slideTint),
      onSlideTint: mix(onSlideTint, other.onSlideTint),
      slideNeutral: mix(slideNeutral, other.slideNeutral),
      onSlideNeutral: mix(onSlideNeutral, other.onSlideNeutral),
      onSlidePhoto: mix(onSlidePhoto, other.onSlidePhoto),
      creatorPhotoPlaceholder: mix(
        creatorPhotoPlaceholder,
        other.creatorPhotoPlaceholder,
      ),
      stepDotDone: mix(stepDotDone, other.stepDotDone),
      onStepDotDone: mix(onStepDotDone, other.onStepDotDone),
      stepDotNow: mix(stepDotNow, other.stepDotNow),
      onStepDotNow: mix(onStepDotNow, other.onStepDotNow),
      chipAction: mix(chipAction, other.chipAction),
      onChipAction: mix(onChipAction, other.onChipAction),
    );
  }
}

extension CoraThemeX on BuildContext {
  /// 현재 테마(라이트/다크)의 색 토큰.
  CoraColors get colors => Theme.of(this).extension<CoraColors>()!;
}
