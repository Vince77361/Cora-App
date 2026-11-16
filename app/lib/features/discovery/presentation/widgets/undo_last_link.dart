import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../discovery_text.dart';

/// 다 봤을 때 F8 카드 아래의 `마지막 카드 되돌리기`(캔버스 01·08). 글자는 `text` 색 밑줄(캔버스는 라임이지만
/// 흰 바탕에서 읽히지 않는다)이고, 되돌릴 결정이 없으면 흐리게 보인다.
class UndoLastLink extends StatelessWidget {
  const UndoLastLink({super.key, required this.canUndo, required this.onUndo});

  final bool canUndo;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Semantics(
          container: true,
          button: true,
          enabled: canUndo,
          onTap: canUndo ? onUndo : null,
          child: ExcludeSemantics(
            child: CoraPressable(
              onTap: onUndo,
              child: Opacity(
                opacity: canUndo ? 1 : 0.45,
                child: SizedBox(
                  height: 44,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: 1,
                    child: Text(
                      DiscoveryTexts.undoLast,
                      style: CoraTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w500,
                        color: c.text,
                        decoration: TextDecoration.underline,
                        decorationColor: c.text,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
