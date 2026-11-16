import 'package:flutter/painting.dart';

import '../../../../core/theme/cora_text_styles.dart';

/// 캔버스 `font-size`·`font-weight`·`letter-spacing`(em)을 글자 모양으로 옮긴다(06·07). 줄 높이를 안 적은
/// 곳은 CSS `normal`(1.448)이다.
TextStyle canvasText(
  double size,
  FontWeight weight,
  Color color, {
  double spacingEm = 0,
  double height = 1.448,
}) => CoraTextStyles.label.copyWith(
  fontSize: size,
  fontWeight: weight,
  letterSpacing: spacingEm * size,
  height: height,
  color: color,
);
