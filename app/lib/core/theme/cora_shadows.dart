import 'package:flutter/painting.dart';

/// 캔버스의 box-shadow. 색은 rgba(23,24,28,a)다.
abstract final class CoraShadows {
  /// CSS blur B는 가우시안 시그마가 B/2이고, Flutter `blurRadius` r은 시그마가
  /// 0.57735*r + 0.5다. 그대로 옮기면 그림자가 20% 정도 더 퍼지므로, 시그마가
  /// 같아지도록 r = (B/2 - 0.5) / 0.57735로 바꿔 쓴다.
  static double blurRadiusFor(double cssBlur) => (cssBlur / 2 - 0.5) / 0.57735;

  // 괄호 안은 캔버스(CSS)의 blur 값이다.
  /// 0 8px 24px, 알파 0.06
  static final card = [
    BoxShadow(
      color: const Color.fromRGBO(23, 24, 28, 0.06),
      offset: const Offset(0, 8),
      blurRadius: blurRadiusFor(24),
    ),
  ];

  /// 0 16px 40px, 알파 0.08
  static final floating = [
    BoxShadow(
      color: const Color.fromRGBO(23, 24, 28, 0.08),
      offset: const Offset(0, 16),
      blurRadius: blurRadiusFor(40),
    ),
  ];

  /// 0 -12px 32px, 알파 0.10. 바텀시트는 아래에서 올라오므로 그림자가 위쪽(-12)으로 퍼진다.
  static final sheet = [
    BoxShadow(
      color: const Color.fromRGBO(23, 24, 28, 0.10),
      offset: const Offset(0, -12),
      blurRadius: blurRadiusFor(32),
    ),
  ];

  /// 단계 머리글 알약: 0 2px 8px. 색은 테마의 `stepPillShadow`(라이트 알파 0.10, 다크 투명).
  static List<BoxShadow> stepPill(Color color) => [
    BoxShadow(
      color: color,
      offset: const Offset(0, 2),
      blurRadius: blurRadiusFor(8),
    ),
  ];

  /// 프로필 사진 위 `사진 바꾸기` 버튼: 0 2px 8px. 색은 테마의 `avatarEditShadow`.
  static List<BoxShadow> avatarEdit(Color color) => [
    BoxShadow(
      color: color,
      offset: const Offset(0, 2),
      blurRadius: blurRadiusFor(8),
    ),
  ];

  /// 하단 메뉴: 0 12px 32px. 색은 테마의 `navShadow`(라이트 알파 0.12, 다크 0.28).
  static List<BoxShadow> bottomNav(Color color) => [
    BoxShadow(
      color: color,
      offset: const Offset(0, 12),
      blurRadius: blurRadiusFor(32),
    ),
  ];

  /// A6 받은 오퍼 카드: 0 16px 40px, 알파 0.14. 라이트·다크가 같다.
  static final offerCard = [
    BoxShadow(
      color: const Color.fromRGBO(23, 24, 28, 0.14),
      offset: const Offset(0, 16),
      blurRadius: blurRadiusFor(40),
    ),
  ];

  /// E5 스위치 손잡이: 0 1px 3px rgba(0,0,0,0.2). 라이트·다크가 같다.
  static final switchKnob = [
    BoxShadow(
      color: const Color.fromRGBO(0, 0, 0, 0.2),
      offset: const Offset(0, 1),
      blurRadius: blurRadiusFor(3),
    ),
  ];
}
