import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_field_box.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../discovery_text.dart';

/// 크리에이터 상세의 `관심 보내기`가 여는 시트(캔버스에 없는 화면, 계획의 문구). 좋았던 점을 한 줄
/// (100자까지) 남기거나 비워 두고 `관심 보내기`를 누르면 그 글(비었으면 null)을 돌려준다. 시트를
/// 그냥 닫으면 아무것도 보내지 않는다는 뜻으로 [LikeNoteResult]를 돌려주지 않는다(null).
Future<LikeNoteResult?> showLikeNoteSheet(BuildContext context) {
  final c = context.colors;
  return showModalBottomSheet<LikeNoteResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // 바탕은 시트 안에서 칠한다. 시트가 열린 채 밝기가 바뀌어도 따라가게 한다.
    backgroundColor: Colors.transparent,
    barrierColor: c.scrim.withValues(alpha: 0.4),
    elevation: 0,
    showDragHandle: false,
    builder: (context) => DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(CoraRadius.xxl),
        ),
      ),
      child: const LikeNoteSheet(),
    ),
  );
}

/// 시트가 돌려주는 값. [note]는 비웠으면 null.
class LikeNoteResult {
  const LikeNoteResult(this.note);

  final String? note;
}

class LikeNoteSheet extends StatefulWidget {
  const LikeNoteSheet({super.key});

  /// 서버가 브랜드의 글로 받는 최대 길이(설계 7장, 계획 P9).
  static const maxLength = 100;

  @visibleForTesting
  static const fieldKey = ValueKey<String>('likeNote.field');

  @override
  State<LikeNoteSheet> createState() => _LikeNoteSheetState();
}

class _LikeNoteSheetState extends State<LikeNoteSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    Navigator.of(context).pop(LikeNoteResult(text.isEmpty ? null : text));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        28,
        16,
        bottom + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Semantics(
              header: true,
              child: Text(
                DiscoveryTexts.noteTitle,
                style: CoraTextStyles.heading.copyWith(color: c.text),
              ),
            ),
          ),
          const SizedBox(height: 16),
          CoraFieldBox(
            fieldKey: LikeNoteSheet.fieldKey,
            label: DiscoveryTexts.noteLabel,
            controller: _controller,
            onChanged: (_) {},
            maxLength: LikeNoteSheet.maxLength,
            onSubmitted: (_) => _send(),
          ),
          const SizedBox(height: 16),
          CoraPrimaryButton(
            label: DiscoveryTexts.noteSend,
            look: CoraPrimaryButtonLook.accent,
            onPressed: _send,
          ),
        ],
      ),
    );
  }
}
