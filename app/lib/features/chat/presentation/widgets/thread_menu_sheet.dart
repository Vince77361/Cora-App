import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/cora_chat_tokens.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../chat_text.dart';

/// 대화 관리 시트에서 고른 것.
enum ThreadMenuAction { toggleMute, block, report, drop }

/// 머리의 점 셋이 여는 `대화 관리` 시트(캔버스 D3). 항목을 누르면 그 값을 돌려주며 닫히고, `닫기`나 시트 밖을 누르면
/// null이다. [canBlock]은 아직 차단하지 않았을 때, [canDrop]은 계약 전 협의를 그만둘 수 있을 때(`canDrop`)만 참이다.
/// `협의 그만두기`는 캔버스에 없는 항목이라 다른 항목과 같은 모양으로 `신고하기` 아래에 둔다.
Future<ThreadMenuAction?> showThreadMenuSheet(
  BuildContext context, {
  required bool muted,
  required bool canBlock,
  required bool canDrop,
}) {
  return showModalBottomSheet<ThreadMenuAction>(
    context: context,
    useSafeArea: true,
    // 바탕은 시트 안에서 칠한다. 시트가 열린 채 밝기가 바뀌어도 따라가게 한다.
    backgroundColor: Colors.transparent,
    barrierColor: CoraChatTokens.menuScrim,
    elevation: 0,
    showDragHandle: false,
    builder: (context) => DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(CoraRadius.xxl),
        ),
      ),
      child: ThreadMenuSheet(
        muted: muted,
        canBlock: canBlock,
        canDrop: canDrop,
      ),
    ),
  );
}

/// 안쪽 위 12·아래 28, 손잡이(40 x 5, 모서리 3, `line`), 항목 높이 56·좌우 24·16px, 아래 `닫기`(높이 52, 좌우 16).
class ThreadMenuSheet extends StatelessWidget {
  const ThreadMenuSheet({
    super.key,
    required this.muted,
    this.canBlock = true,
    this.canDrop = false,
  });

  final bool muted;
  final bool canBlock;
  final bool canDrop;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = math.max(28.0, MediaQuery.viewPaddingOf(context).bottom);
    return Semantics(
      container: true,
      label: ChatTexts.manage,
      child: Padding(
        padding: EdgeInsets.only(top: 12, bottom: bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ExcludeSemantics(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.line,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const SizedBox(width: 40, height: 5),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _Row(
              label: muted ? ChatTexts.unmute : ChatTexts.mute,
              onTap: () =>
                  Navigator.of(context).pop(ThreadMenuAction.toggleMute),
            ),
            if (canBlock)
              _Row(
                label: ChatTexts.block,
                onTap: () => Navigator.of(context).pop(ThreadMenuAction.block),
              ),
            _Row(
              label: ChatTexts.report,
              onTap: () => Navigator.of(context).pop(ThreadMenuAction.report),
            ),
            if (canDrop)
              _Row(
                label: ChatTexts.drop,
                onTap: () => Navigator.of(context).pop(ThreadMenuAction.drop),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Semantics(
                container: true,
                button: true,
                label: ChatTexts.menuClose,
                onTap: () => Navigator.of(context).pop(),
                child: ExcludeSemantics(
                  child: CoraPressable(
                    onTap: () => Navigator.of(context).pop(),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(CoraRadius.pill),
                      ),
                      child: SizedBox(
                        height: 52,
                        child: Center(
                          child: Text(
                            ChatTexts.menuClose,
                            style: CoraTextStyles.buttonMedium.copyWith(
                              color: c.text,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.onTap});

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
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: CoraTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w400,
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
