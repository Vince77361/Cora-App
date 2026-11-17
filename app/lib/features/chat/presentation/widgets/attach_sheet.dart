import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shadows.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../chat_text.dart';

/// 더하기 버튼이 여는 메뉴(캔버스 D3 `보낼 카드`): 폭 220에 안쪽 여백 8, 모서리 20, 그림자 0 12px 32px. 줄은 높이 48,
/// 안쪽 12, 모서리 14, 15px 글자. 크리에이터이고 보낼 카드가 있으면 `내 콘텐츠 카드`, 조건 수정 제안을 보낼 수 있으면
/// `조건 수정 제안`이 있다.
class AttachMenu extends StatelessWidget {
  const AttachMenu({super.key, this.onContentCard, this.onProposeTerms});

  /// null이면 `내 콘텐츠 카드` 줄이 없다.
  final VoidCallback? onContentCard;

  /// null이면 `조건 수정 제안` 줄이 없다.
  final VoidCallback? onProposeTerms;

  /// 캔버스의 폭 220(안쪽 칸)에 양쪽 여백 8을 더한 폭.
  static const double width = 220 + 16;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      label: ChatTexts.attachMenuLabel,
      child: SizedBox(
        width: width,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.background,
            borderRadius: BorderRadius.circular(20),
            boxShadow: CoraShadows.attachMenu,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (onContentCard != null)
                  _Item(label: ChatTexts.attachMyCard, onTap: onContentCard!),
                if (onProposeTerms != null)
                  _Item(label: ChatTexts.attachTerms, onTap: onProposeTerms!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    button: true,
    label: label,
    onTap: onTap,
    child: ExcludeSemantics(
      child: CoraPressable(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: CoraTextStyles.body.copyWith(
                  height: 1.448,
                  color: context.colors.text,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
