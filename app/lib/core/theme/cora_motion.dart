import 'package:flutter/widgets.dart';

/// 움직임 토큰. 전환 길이와 곡선은 작성자의 제안이고, 소유자가 실제 기기에서
/// 모션 갤러리를 보고 고친다(기초 계획 Task 8 Step 5). 값을 바꾸면 테스트도 같이 바꾼다.
abstract final class CoraMotion {
  /// 다음 화면으로 들어가기.
  static const pushDuration = Duration(milliseconds: 320);

  /// 아래에서 올라오는 화면.
  static const sheetDuration = Duration(milliseconds: 380);

  /// 탭 전환, 로그인 전후.
  static const fadeDuration = Duration(milliseconds: 200);

  /// 선택, 켜짐·꺼짐 같은 위젯 상태 변화.
  static const stateDuration = Duration(milliseconds: 200);

  /// 누르는 동안 살짝 줄어드는 반응. 손을 대자마자 보여야 해서 짧다.
  static const pressDuration = Duration(milliseconds: 100);

  /// 빨리 출발해 부드럽게 멈춘다. 되돌아갈 때는 [Curve.flipped]를 써서
  /// 닫힘도 같은 느낌(빨리 출발)으로 움직인다.
  static const Curve standardCurve = Curves.easeOutCubic;

  /// 누르는 동안의 크기. 잉크 번짐 대신 쓴다.
  static const pressedScale = 0.98;

  /// push: 들어오는 화면이 출발하는 위치(화면 너비 비율, 오른쪽).
  static const pushEnterOffset = 0.24;

  /// push: 밑에 깔리는 화면이 왼쪽으로 밀리는 거리(화면 너비 비율).
  static const pushUnderlayOffset = 0.08;

  /// push: 밑에 깔리는 화면을 덮는 `scrim`의 최대 불투명도.
  static const pushUnderlayDim = 0.10;

  /// sheet: 뒤 화면이 줄어드는 크기.
  static const sheetUnderlayScale = 0.96;

  /// sheet: 뒤 화면을 덮는 `scrim`의 최대 불투명도.
  static const sheetUnderlayDim = 0.16;

  /// 기기에서 '동작 줄이기'를 켰는지.
  static bool reduceMotion(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// 동작 줄이기를 켰으면 움직임 없이 바로 바뀌도록 0을 돌려준다.
  static Duration resolve(BuildContext context, Duration duration) =>
      reduceMotion(context) ? Duration.zero : duration;
}
