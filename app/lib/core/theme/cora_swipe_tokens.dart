import 'package:flutter/painting.dart';

import 'cora_shadows.dart';

/// 카드 넘기기 카드(캔버스 01 발견, 08 크리에이터의 발견)의 사진 위 덮개와 도장 값.
/// 사진 위에 얹는 것이라 라이트·다크가 같다(DarkMain도 같은 값). 그래서 `CoraColors`가 아니라
/// 상수로 둔다. 글자색(`onPhoto`, `onPhotoSecondary`)과 제작비 줄(`accent`)은 `CoraColors`에서 가져온다.
abstract final class CoraSwipeTokens {
  /// 사진 상자의 바탕(사진이 뜨기 전). 캔버스 `#E6E8EB`.
  static const backdrop = Color(0xFFE6E8EB);

  /// 사진 위쪽 120px을 어둡게 눕히는 그라데이션: rgba(23,24,28,0.38) → 투명.
  static const topScrimHeight = 120.0;
  static const topScrim = [Color(0x6117181C), Color(0x0017181C)];

  /// 08(크리에이터의 발견)의 다크 카드 영역 바탕. 캔버스 DarkCreatorDiscover `#2A2D33`.
  /// 라이트는 [backdrop]이고, 01의 다크는 화면 바탕(`#0F1012`)이다.
  static const creatorBackdropDark = Color(0xFF2A2D33);

  /// 카드 위쪽 진행 막대에서 아직 채우지 않은 칸: 흰색 40%. 채운 첫 칸은 테마의 `swipeProgressOn`이다.
  static const progressIdle = Color(0x66FFFFFF);

  /// 08 머리 알약에서 고른 `크리에이터` 칸. 캔버스가 라이트·다크 모두 `#FFFFFF`에 글자 `#17181C`,
  /// 그림자 `0 2px 8px rgba(23,24,28,0.10)`이다(01의 다크는 `#F2F3F5`라서 따로 둔다).
  static const creatorPillSelected = Color(0xFFFFFFFF);
  static const creatorPillOn = Color(0xFF17181C);
  static const creatorPillShadow = Color(0x1A17181C);

  /// 넘기기·보류·관심·되돌리기 버튼의 흰 아이콘(사진 위에 얹어 라이트·다크가 같다)과 그 그림자
  /// `0 2px 6px rgba(0,0,0,0.55)`. 관심 아이콘만 테마의 `accent`다.
  static const actionIcon = Color(0xFFFFFFFF);
  static const actionIconShadow = Color(0x8C000000);

  /// 시트(02 넘기기 이유, 보류, 05 서로 관심) 뒤 덮개. 캔버스 Pass의 rgba(15,16,18,0.45)로 두 모드가 같다.
  static const sheetBarrier = Color(0x730F1012);

  /// 08 알림 문구의 다크 그림자 `0 8px 24px rgba(23,24,28,0.16)`.
  static const creatorToastShadowDark = Color(0x2917181C);

  /// D1 사진 아래 160의 덮개: 위 투명 → 아래 `rgba(23,24,28,0.8)`.
  static const detailPhotoScrim = [Color(0x0017181C), Color(0xCC17181C)];

  /// 아래쪽 글자 덮개: 0%, 35%, 70%, 100%에서 rgba(23,24,28)의 알파 0, 0.2, 0.48, 0.66.
  static const bottomScrim = [
    Color(0x0017181C),
    Color(0x3317181C),
    Color(0x7A17181C),
    Color(0xA817181C),
  ];
  static const bottomScrimStops = [0.0, 0.35, 0.70, 1.0];

  /// 아래쪽 글자 덮개의 안쪽 여백. 위 300은 그라데이션이 퍼질 높이, 아래 116은 카드 위에 겹쳐 놓는
  /// 버튼 줄(되돌리기·넘기기·보류·관심)이 글자를 가리지 않게 비우는 높이다.
  static const textInsetTop = 300.0;
  static const textInsetSide = 22.0;
  static const textInsetBottom = 116.0;

  /// 글자 그림자: 0 1px 14px rgba(0,0,0,0.28).
  static final textShadow = Shadow(
    color: const Color.fromRGBO(0, 0, 0, 0.28),
    offset: const Offset(0, 1),
    blurRadius: CoraShadows.blurRadiusFor(14),
  );

  /// 사진 가운데 기준점: object-position 50% 30%.
  static const photoAlignment = Alignment(0, -0.4);

  /// 도장(`관심`·`넘김`·`보류`): 테두리 5, 모서리 12, 글자 40·900. `관심`만 라임이고 나머지는 흰색이다.
  static const stampBorder = 5.0;
  static const stampRadius = 12.0;
  static const stampFontSize = 40.0;
  static const stampTilt = 14.0;
  static const holdStampWidth = 124.0;
  static const likeStampFill = Color(0x8C1F2A00);
  static const stampFill = Color(0x8C17181C);

  /// 도장 자리(카드 안): 관심은 왼쪽 위, 넘김은 오른쪽 위, 보류는 가운데 아래쪽.
  static const stampSideInset = 22.0;
  static const stampTop = 70.0;
  static const holdStampTop = 170.0;
}
