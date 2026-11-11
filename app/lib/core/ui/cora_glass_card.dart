import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/cora_colors.dart';
import '../theme/cora_shadows.dart';
import '../theme/cora_shapes.dart';

/// 뒤를 흐리게 비추는 유리 카드(캔버스 Principles의 질문 카드).
///
/// 채움은 `glass` 토큰(라이트 75%, 다크 85%), 배경 흐림은 CSS `blur(16px)`,
/// 모서리 28, 그림자 `CoraShadows.floating`.
class CoraGlassCard extends StatelessWidget {
  const CoraGlassCard({
    super.key,
    required this.child,
    this.padding = canvasPadding,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Principles 카드의 안쪽 여백 `22px 18px 18px`.
  static const canvasPadding = EdgeInsets.fromLTRB(18, 22, 18, 18);

  /// CSS `backdrop-filter: blur(16px)`의 16은 가우시안 표준편차(시그마)다.
  /// 그림자의 blur(시그마의 2배)와 달리 그대로 옮긴다.
  static const double blurSigma = 16;

  static final _radius = BorderRadius.circular(CoraRadius.xxl);

  @override
  Widget build(BuildContext context) {
    // 그림자는 잘리지 않게 바깥에, 흐림은 둥근 모서리 안에만 퍼지게 안쪽에서 자른다.
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: _radius,
        boxShadow: CoraShadows.floating,
      ),
      child: ClipRRect(
        borderRadius: _radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: ColoredBox(
            color: context.colors.glass,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
