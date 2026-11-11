import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_text_styles.dart';

/// 단계마다 위에 오는 제목과 설명(캔버스 NOffer: 위 28, 좌우 24, 제목 28/900, 설명 14).
class OfferStepIntro extends StatelessWidget {
  const OfferStepIntro({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: CoraTextStyles.headline.copyWith(color: c.text),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: CoraTextStyles.bodySmall.copyWith(color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}
