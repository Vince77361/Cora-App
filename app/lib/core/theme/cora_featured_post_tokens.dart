import 'package:flutter/painting.dart';

/// 대표 게시물 화면(M19G6*)에서 새로 쓰인 값 가운데 라이트·다크가 같은 것. 라이트·다크가 다른 색은 `CoraColors`에서 가져온다.
abstract final class CoraFeaturedPostTokens {
  /// 게시물 카드 아래쪽을 어둡게 눕히는 그라데이션의 시작(투명한 rgba(23,24,28,0))과 끝 rgba(23,24,28,0.7). 높이 100.
  /// 시작을 검정이 아닌 같은 색의 투명으로 두어 중간 색이 회색으로 번지지 않게 한다.
  static const photoScrimStart = Color(0x0017181C);
  static const photoScrimEnd = Color(0xB317181C);

  /// 카드 위 한 줄 글자 그림자 rgba(0,0,0,0.5)(0 1 4).
  static const captionShadow = Color(0x80000000);

  /// 순서·교체 시트 뒤를 덮는 rgba(15,16,18,0.45).
  static const sheetBarrier = Color(0x730F1012);

  /// 인스타에서 고르기 격자의 번호 동그라미 테두리 rgba(255,255,255,0.9)와, 고르지 않은 동그라미의 채움 rgba(23,24,28,0.15).
  static const pickRing = Color(0xE6FFFFFF);
  static const pickIdleFill = Color(0x2617181C);

  /// 가져온 칸을 눌러 흐리게 덮는 색(캔버스 밖).
  static const importedDim = Color(0x8017181C);
}
