import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../creator_discovery_text.dart';

/// 협업 원칙을 정하지 않은 크리에이터의 08 화면 위 띠(캔버스 밖, 계획의 문구).
/// `surface` 바탕의 둥근 상자에 안내와 `정하기`가 있다.
class PrinciplesBanner extends StatelessWidget {
  const PrinciplesBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            spacing: 10,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    CreatorDiscoveryTexts.principlesBanner,
                    style: CoraTextStyles.bodySmall.copyWith(color: c.text),
                  ),
                ),
              ),
              Semantics(
                container: true,
                button: true,
                onTap: onTap,
                child: ExcludeSemantics(
                  child: CoraPressable(
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        CreatorDiscoveryTexts.principlesBannerAction,
                        style: CoraTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: c.text,
                          decoration: TextDecoration.underline,
                          decorationColor: c.text,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
