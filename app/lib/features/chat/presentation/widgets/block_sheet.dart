import 'package:flutter/material.dart';

import '../../../../core/ui/cora_primary_button.dart';
import '../../../../core/ui/cora_secondary_button.dart';
import '../chat_text.dart';
import 'chat_sheet.dart';

/// `차단하기`를 누르면 올라오는 확인 시트(캔버스에 없는 화면). [onConfirm]은 성공하면 null, 실패하면 시트에 보일
/// 문구를 돌려준다. 성공하면 시트가 닫히며 true를 돌려주고, `취소`나 시트 밖을 누르면 null이다.
Future<bool?> showBlockSheet(
  BuildContext context, {
  required String name,
  required Future<String?> Function() onConfirm,
}) => showChatSheet<bool>(
  context,
  (_) => BlockSheet(name: name, onConfirm: onConfirm),
);

class BlockSheet extends StatefulWidget {
  const BlockSheet({super.key, required this.name, required this.onConfirm});

  final String name;
  final Future<String?> Function() onConfirm;

  @override
  State<BlockSheet> createState() => _BlockSheetState();
}

class _BlockSheetState extends State<BlockSheet> with ChatSheetAction {
  @override
  Widget build(BuildContext context) => ChatSheetBody(
    children: [
      ChatSheetHeading(
        title: ChatTexts.blockTitle(widget.name),
        body: ChatTexts.blockBody,
      ),
      const SizedBox(height: 20),
      if (error != null) ChatSheetError(text: error!),
      CoraPrimaryButton(
        label: ChatTexts.blockConfirm,
        onPressed: busy ? null : () => runAction(widget.onConfirm),
      ),
      const SizedBox(height: 8),
      CoraSecondaryButton(
        label: ChatTexts.blockCancel,
        onPressed: busy ? null : () => Navigator.of(context).pop(),
      ),
    ],
  );
}
