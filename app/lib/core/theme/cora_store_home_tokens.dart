import 'package:flutter/painting.dart';

/// 사장님 첫 화면(M19G4*)에서 새로 쓰인 값 가운데 라이트·다크가 같은 것. 라이트·다크가 다른 색은
/// `CoraColors`에서 가져온다.
abstract final class CoraStoreHomeTokens {
  /// 사진이 없는 추천 칸의 바탕. 캔버스가 두 톤을 번갈아 쓴다(160도 그라데이션).
  static const avatarTones = [
    LinearGradient(
      begin: Alignment(-0.34, -0.94),
      end: Alignment(0.34, 0.94),
      colors: [Color(0xFFEBD7B9), Color(0xFFD3B084)],
    ),
    LinearGradient(
      begin: Alignment(-0.34, -0.94),
      end: Alignment(0.34, 0.94),
      colors: [Color(0xFFE8DDCB), Color(0xFFCBB593)],
    ),
  ];

  /// 사진이 없는 추천 칸 가운데의 이름 첫 글자 rgba(23,24,28,0.35).
  static const avatarInitial = Color(0x5917181C);
}
