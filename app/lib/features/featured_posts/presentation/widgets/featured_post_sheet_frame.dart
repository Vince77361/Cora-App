import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';

/// 대표 게시물 화면의 아래 시트 세 개(순서·교체, 나갈 때 묻기, 프로 계정 방법)가 같이 쓰는 틀. 시트 바탕은 시트 안에서
/// 칠해 시트가 열린 채 밝기가 바뀌어도 따라가게 하고, 위 모서리는 둥글게 한다. 시트 밖을 누르면 null로 닫힌다.
///
/// [barrierColor]를 주지 않으면 스크림 40%다(캔버스에 없는 시트들).
Future<T?> showFeaturedPostSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  Color? barrierColor,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: barrierColor ?? context.colors.scrim.withValues(alpha: 0.4),
    elevation: 0,
    showDragHandle: false,
    builder: (context) => DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(CoraRadius.xxl),
        ),
      ),
      child: builder(context),
    ),
  );
}
