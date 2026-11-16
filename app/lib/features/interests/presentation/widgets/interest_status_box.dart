import 'package:flutter/material.dart';

import '../../../../core/text/josa.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../domain/interest_card.dart';
import '../interests_text.dart';

/// 03 목록 아래 상자(캔버스 Likes): 안쪽 12 · 14, 모서리 12, `surface` 바탕. 서로 관심이 있으면 `{이름}과 서로
/// 관심`과 오른쪽 `협업 조건 확인`(06)이, 응답을 기다리는 후보가 있으면 그 아래 `{이름}은 상대의 응답을 기다리고
/// 있어요.`가 한 줄씩 나온다.
class InterestStatusBox extends StatelessWidget {
  const InterestStatusBox({
    super.key,
    required this.mutual,
    required this.waiting,
    required this.onOpenTerms,
  });

  final List<InterestCard> mutual;
  final List<InterestCard> waiting;

  /// `협업 조건 확인`. 서로 관심인 카드를 넘긴다.
  final void Function(InterestCard card) onOpenTerms;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            for (final card in mutual)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                spacing: 12,
                children: [
                  Expanded(
                    child: Text(
                      '${josa(card.name, JosaPair.gwaWa)} 서로 관심',
                      style: CoraTextStyles.label.copyWith(color: c.text),
                    ),
                  ),
                  Semantics(
                    container: true,
                    button: true,
                    onTap: () => onOpenTerms(card),
                    child: ExcludeSemantics(
                      child: CoraPressable(
                        onTap: () => onOpenTerms(card),
                        child: Text(
                          InterestsTexts.openTerms,
                          style: CoraTextStyles.label.copyWith(color: c.text),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            for (final card in waiting)
              Text(
                '${josa(card.name, JosaPair.eunNeun)} 상대의 응답을 기다리고 있어요.',
                style: CoraTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w400,
                  color: c.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
