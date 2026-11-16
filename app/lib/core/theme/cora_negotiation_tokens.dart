import 'package:flutter/painting.dart';

/// 조건 협의(06)와 진행 단계(07)의 값 중 라이트·다크가 같은 것. 모드마다 다른 색은 `CoraColors`에 있다.
abstract final class CoraNegotiationTokens {
  /// 06 사진 아래 글자를 받치는 덮개: 위 투명 → 아래 `rgba(23,24,28,0.85)`(Terms).
  static const termsPhotoScrim = [Color(0x0017181C), Color(0xD917181C)];
}
