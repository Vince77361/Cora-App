import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../../../../core/ui/cora_secondary_button.dart';

/// 오른쪽 위 메뉴의 `협업 그만두기`를 누르면 아래에서 올라오는 시트(캔버스에 없는 화면). 누르면 같은 시트
/// 안에서 확인 문구로 바뀐다. 시트는 자기만 닫고 [onConfirm]의 결과(성공이면 true)를 돌려준다. 시트를
/// 닫은 뒤에 화면을 떠날지는 부른 쪽이 정한다(실패하면 false, `계속하기`·바깥을 누르면 null).
///
/// 사장님의 `협업 취소 요청`도 같은 시트다: 글자만 [menu]·[confirmTitle]·[confirm]·[keep]으로 바꾼다.
Future<bool?> showCancelCollaborationSheet(
  BuildContext context, {
  required Future<bool> Function() onConfirm,
  String menu = CancelCollaborationSheet.menu,
  String confirmTitle = CancelCollaborationSheet.confirmTitle,
  String confirm = CancelCollaborationSheet.confirm,
  String keep = CancelCollaborationSheet.keep,
}) {
  final c = context.colors;
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: c.background,
    barrierColor: c.scrim.withValues(alpha: 0.4),
    elevation: 0,
    showDragHandle: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(CoraRadius.xxl)),
    ),
    builder: (_) => CancelCollaborationSheet(
      onConfirm: onConfirm,
      menuLabel: menu,
      confirmText: confirmTitle,
      confirmLabel: confirm,
      keepLabel: keep,
    ),
  );
}

class CancelCollaborationSheet extends StatefulWidget {
  const CancelCollaborationSheet({
    super.key,
    required this.onConfirm,
    this.menuLabel = menu,
    this.confirmText = confirmTitle,
    this.confirmLabel = confirm,
    this.keepLabel = keep,
  });

  final Future<bool> Function() onConfirm;
  final String menuLabel;
  final String confirmText;
  final String confirmLabel;
  final String keepLabel;

  static const menu = '협업 그만두기';
  static const confirmTitle = '협업을 그만둘까요? 가게에 결제 금액을 모두 돌려드려요.';
  static const confirm = '그만두기';
  static const keep = '계속하기';

  @override
  State<CancelCollaborationSheet> createState() =>
      _CancelCollaborationSheetState();
}

class _CancelCollaborationSheetState extends State<CancelCollaborationSheet> {
  bool _confirming = false;
  bool _busy = false;

  Future<void> _confirm() async {
    setState(() => _busy = true);
    final done = await widget.onConfirm();
    if (mounted) Navigator.of(context).pop(done);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 28, 16, bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_confirming)
            CoraSecondaryButton(
              label: widget.menuLabel,
              tone: CoraSecondaryTone.muted,
              onPressed: () => setState(() => _confirming = true),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Semantics(
                header: true,
                liveRegion: true,
                child: Text(
                  widget.confirmText,
                  style: CoraTextStyles.heading.copyWith(color: c.text),
                ),
              ),
            ),
            const SizedBox(height: 20),
            CoraPrimaryButton(
              label: widget.confirmLabel,
              onPressed: _busy ? null : _confirm,
            ),
            const SizedBox(height: 8),
            CoraSecondaryButton(
              label: widget.keepLabel,
              onPressed: _busy ? null : () => Navigator.of(context).pop(),
            ),
          ],
        ],
      ),
    );
  }
}
