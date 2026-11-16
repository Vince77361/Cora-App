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
