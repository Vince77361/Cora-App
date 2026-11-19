import 'package:flutter/painting.dart';

import 'cora_shadows.dart';

/// 이상형 월드컵(M19G3*)에서 새로 쓰인 값 가운데 라이트·다크가 같은 것. 라이트·다크가 다른 색은 `CoraColors`에서
/// 가져온다.
abstract final class CoraWorldCupTokens {
  /// 카드 아래쪽을 어둡게 눕히는 그라데이션: 위 투명 → 45%에서 rgba(23,24,28,0.55) → 아래 rgba(23,24,28,0.88).
  static const scrim = [
    Color(0x0017181C),
    Color(0x8C17181C),
    Color(0xE017181C),
  ];
  static const scrimStops = [0.0, 0.45, 1.0];

  /// 대결 카드(높이 338) 아래 덮개 높이와 결과 카드(높이 470) 아래 덮개 높이.
  static const matchScrimHeight = 230.0;
  static const resultScrimHeight = 280.0;

  /// 가운데 `VS` 동그라미의 바깥 그림자 `0 8px 24px rgba(23,24,28,0.2)`. 안쪽 4px 테두리는 화면 바탕색이라 테마에서
  /// 가져온다([vsShadows]).
  static const vsDiameter = 56.0;

  static List<BoxShadow> vsShadows(Color ring) => [
    BoxShadow(color: ring, spreadRadius: 4),
    BoxShadow(
      color: const Color(0x3317181C),
      offset: const Offset(0, 8),
      blurRadius: CoraShadows.blurRadiusFor(24),
    ),
  ];
}
