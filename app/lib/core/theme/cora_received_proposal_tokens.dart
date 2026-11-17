import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// 10 받은 제안(Proposal·DarkProposal)의 값 중 라이트·다크가 같은 것. 사진 위에 얹는 것이라 모드와 상관없다.
/// 모드마다 다른 색은 `CoraColors`에 있다(머리 글자·`text`, 첫 칸·`swipeProgressOn`, 알약·`accent`).
abstract final class CoraReceivedProposalTokens {
  /// 사진 카드의 바탕(사진이 뜨기 전, 사진이 없을 때) `#0F1012`.
  static const cardBackground = Color(0xFF0F1012);

  /// 사진 위 180을 어둡게 눕히는 덮개: `rgba(15,16,18,0.55)` → 투명.
  static const topScrimHeight = 180.0;
  static const topScrim = [Color(0x8C0F1012), Color(0x000F1012)];

  /// 사진 아래 520을 덮는 덮개: 0% 투명, 45% 0.55, 100% 0.85.
  static const bottomScrimHeight = 520.0;
  static const bottomScrim = [
    Color(0x000F1012),
    Color(0x8C0F1012),
    Color(0xD90F1012),
  ];
  static const bottomScrimStops = [0.0, 0.45, 1.0];

  /// 브랜드 사진 원(36) 바탕 `#2E5B43`.
  static const avatarPlaceholder = Color(0xFF2E5B43);

  /// 사진 위 보조 글자 `rgba(255,255,255,0.8)`(캠페인 줄), `0.85`(형식 줄).
  static const subtitle = Color(0xCCFFFFFF);
  static const formatLine = Color(0xD9FFFFFF);

  /// `브랜드가 좋아한 점` 말풍선: 바탕 `rgba(255,255,255,0.94)`, 글자 `#17181C`(라이트·다크 같음).
  static const noteBackground = Color(0xF0FFFFFF);
  static const noteInk = Color(0xFF17181C);

  /// 두 번째 알약(`조건부터 질문하기`)의 유리 바탕 `rgba(255,255,255,0.16)`, 한 줄 입력줄 바탕 `0.12`.
  static const glassPill = Color(0x29FFFFFF);
  static const glassField = Color(0x1FFFFFFF);

  /// 입력란 안내 글자 `rgba(255,255,255,0.7)`.
  static const fieldHint = Color(0xB3FFFFFF);

  /// 유리 바탕 뒤를 흐리는 정도(`backdrop-filter: blur(8px)`).
  static const glassBlur = 8.0;

  /// 말풍선을 기울이는 각도(-1.5deg).
  static const noteTilt = -1.5 * math.pi / 180;
}
