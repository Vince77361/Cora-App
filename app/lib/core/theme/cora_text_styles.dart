import 'package:flutter/painting.dart';

/// 글자 스타일 토큰. 색은 넣지 않는다. 위젯이 `context.colors`로 입힌다.
/// 자간은 캔버스의 em 값에 글자 크기를 곱한 논리 픽셀이고, 줄 높이는 배수다.
///
/// 모든 스타일의 자간과 줄 높이를 직접 정한다. 비워 두면 Material 글자 스케일이
/// 값을 채워 넣어(예: label은 자간 +0.5) 캔버스보다 느슨하거나 커진다.
abstract final class CoraTextStyles {
  static const _family = 'NotoSansKR';

  /// 캔버스에 줄 높이가 없는 곳은 CSS `line-height: normal`이다. Noto Sans KR의
  /// hhea (ascender 1160 + descender 288) / 1000 = 1.448과 같다.
  static const _normal = 1.448;

  // CSS의 반 줄 간격(half-leading)과 같게 위아래로 고르게 나눈다. 문맥에 따라
  // 달라지지 않도록 직접 지정한다.
  static const _even = TextLeadingDistribution.even;

  static const display = TextStyle(
    fontFamily: _family,
    fontSize: 32,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.6,
    height: 1.25,
    leadingDistribution: _even,
  );
  static const title = TextStyle(
    fontFamily: _family,
    fontSize: 26,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.17,
    height: 1.3,
    leadingDistribution: _even,
  );
  static const heading = TextStyle(
    fontFamily: _family,
    fontSize: 19,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.38,
    height: _normal,
    leadingDistribution: _even,
  );
  static const bodyLarge = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: _normal,
    leadingDistribution: _even,
  );
  static const body = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.6,
    leadingDistribution: _even,
  );
  static const label = TextStyle(
    fontFamily: _family,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: _normal,
    leadingDistribution: _even,
  );
  static const caption = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: _normal,
    leadingDistribution: _even,
  );
  static const button = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: _normal,
    leadingDistribution: _even,
  );

  /// 로고 글자 "cora". A1의 26px, 900, -0.05em.
  static const wordmark = TextStyle(
    fontFamily: _family,
    fontSize: 26,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.3,
    height: _normal,
    leadingDistribution: _even,
  );

  // 아래는 NLogin(E1)·NVerify(E2)에서 새로 쓰인 크기다.

  /// E2 제목. 28px, 900, -0.05em.
  static const headline = TextStyle(
    fontFamily: _family,
    fontSize: 28,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.4,
    height: 1.3,
    leadingDistribution: _even,
  );

  /// 입력 칸에 들어간 값(휴대폰 번호). 17px.
  static const fieldValue = TextStyle(
    fontFamily: _family,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: _normal,
    leadingDistribution: _even,
  );

  /// 입력 칸 위의 이름. 12px, 보통 굵기(`caption`은 500).
  static const fieldLabel = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: _normal,
    leadingDistribution: _even,
  );

  /// 인증번호 한 칸의 숫자. 24px, 700.
  static const digit = TextStyle(
    fontFamily: _family,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: _normal,
    leadingDistribution: _even,
  );

  /// 숫자 키패드의 키. 22px, 500.
  static const keypad = TextStyle(
    fontFamily: _family,
    fontSize: 22,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: _normal,
    leadingDistribution: _even,
  );

  /// 제목 아래 설명. 14px.
  static const bodySmall = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: _normal,
    leadingDistribution: _even,
  );

  /// 남은 시간처럼 곁들이는 작은 글자. 13px, 보통 굵기(`label`은 500).
  static const meta = TextStyle(
    fontFamily: _family,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: _normal,
    leadingDistribution: _even,
  );

  /// 카카오·네이버 버튼. 15px, 500.
  static const buttonMedium = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: _normal,
    leadingDistribution: _even,
  );

  /// 약관 문구. 12px, 줄 높이 1.6.
  static const legal = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.6,
    leadingDistribution: _even,
  );

  /// 사진 위 문구. 15px, 줄 높이 1.5.
  static const photoCaption = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
    leadingDistribution: _even,
  );
}
