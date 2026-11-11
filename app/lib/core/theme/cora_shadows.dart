import 'package:flutter/painting.dart';

/// 캔버스의 box-shadow. 색은 rgba(23,24,28,a)다.
abstract final class CoraShadows {
  static const card = [
    BoxShadow(color: Color.fromRGBO(23, 24, 28, 0.06), offset: Offset(0, 8), blurRadius: 24),
  ];
  static const floating = [
    BoxShadow(color: Color.fromRGBO(23, 24, 28, 0.08), offset: Offset(0, 16), blurRadius: 40),
  ];
  // 바텀시트는 아래에서 올라오므로 그림자가 위쪽(-12)으로 퍼진다.
  static const sheet = [
    BoxShadow(color: Color.fromRGBO(23, 24, 28, 0.10), offset: Offset(0, -12), blurRadius: 32),
  ];
}
