import 'package:flutter/painting.dart';

/// 글자 스타일 토큰. 색은 넣지 않는다. 위젯이 `context.colors`로 입힌다.
/// 자간은 캔버스의 em 값에 글자 크기를 곱한 논리 픽셀이고, 줄 높이는 배수다.
abstract final class CoraTextStyles {
  static const _family = 'NotoSansKR';

  static const display = TextStyle(
    fontFamily: _family, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.6, height: 1.25,
  );
  static const title = TextStyle(
    fontFamily: _family, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -1.17, height: 1.3,
  );
  static const heading = TextStyle(
    fontFamily: _family, fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: -0.38,
  );
  static const bodyLarge = TextStyle(
    fontFamily: _family, fontSize: 16, fontWeight: FontWeight.w500,
  );
  static const body = TextStyle(
    fontFamily: _family, fontSize: 15, fontWeight: FontWeight.w400, letterSpacing: 0, height: 1.6,
  );
  static const label = TextStyle(
    fontFamily: _family, fontSize: 13, fontWeight: FontWeight.w500,
  );
  static const caption = TextStyle(
    fontFamily: _family, fontSize: 12, fontWeight: FontWeight.w500,
  );
  static const button = TextStyle(
    fontFamily: _family, fontSize: 16, fontWeight: FontWeight.w700,
  );
}
