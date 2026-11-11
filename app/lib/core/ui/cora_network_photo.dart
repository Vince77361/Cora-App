import 'package:flutter/material.dart';

import '../theme/cora_colors.dart';

/// 주소로 불러오는 사진. 부모가 정한 크기를 채운다. 불러오는 동안, 주소가 없을 때, 불러오기에
/// 실패했을 때는 `surface` 바탕만 보인다(깨진 그림 표시를 띄우지 않는다).
///
/// 모양(원, 둥근 모서리)은 부모가 자른다.
class CoraNetworkPhoto extends StatelessWidget {
  const CoraNetworkPhoto({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
  });

  final String? url;
  final BoxFit fit;

  /// 캔버스 `object-position`(예: 50% 25%는 `Alignment(0, -0.5)`).
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final address = url;
    return ColoredBox(
      color: c.surface,
      child: address == null || address.isEmpty
          ? const SizedBox.expand()
          : SizedBox.expand(
              child: Image.network(
                address,
                fit: fit,
                alignment: alignment,
                gaplessPlayback: true,
                excludeFromSemantics: true,
                errorBuilder: (context, error, stack) =>
                    const SizedBox.expand(),
              ),
            ),
    );
  }
}
