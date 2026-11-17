import 'package:flutter/material.dart';

import '../../../../core/ui/cora_primary_button.dart';
import '../../../../core/ui/cora_secondary_button.dart';
import '../../../negotiation/domain/negotiation_repository.dart'
    show DropReason;
import '../chat_text.dart';
import 'chat_sheet.dart';

/// `협의 그만두기`를 누르면 올라오는 시트(캔버스에 없는 화면): 이유 넷 중 하나를 고르고 `그만두기`. [onConfirm]은
/// 성공하면 null, 실패하면 시트에 보일 문구를 돌려준다. 성공하면 시트가 닫히며 true를 돌려주고,
/// `계속 협의하기`나 시트 밖을 누르면 null이다.
Future<bool?> showDropSheet(
  BuildContext context, {
  required Future<String?> Function(DropReason reason) onConfirm,
}) => showChatSheet<bool>(context, (_) => DropSheet(onConfirm: onConfirm));

class DropSheet extends StatefulWidget {
  const DropSheet({super.key, required this.onConfirm});

  final Future<String?> Function(DropReason reason) onConfirm;

  @override
  State<DropSheet> createState() => _DropSheetState();
}

class _DropSheetState extends State<DropSheet> {
  DropReason? _reason;
  bool _busy = false;
  String? _error;

  Future<void> _confirm() async {
    final reason = _reason;
    if (reason == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await widget.onConfirm(reason);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _busy = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) => ChatSheetBody(
    children: [
      const ChatSheetHeading(
        title: ChatTexts.dropTitle,
        body: ChatTexts.dropBody,
      ),
      const SizedBox(height: 8),
      for (final reason in DropReason.values)
        ChatReasonRow(
          label: dropReasonLabel(reason),
          picked: _reason == reason,
          onTap: _busy ? null : () => setState(() => _reason = reason),
        ),
      const SizedBox(height: 12),
      if (_error != null) ChatSheetError(text: _error!),
      CoraPrimaryButton(
        label: ChatTexts.dropConfirm,
        onPressed: _reason == null || _busy ? null : _confirm,
      ),
      const SizedBox(height: 8),
      CoraSecondaryButton(
        label: ChatTexts.dropKeep,
        onPressed: _busy ? null : () => Navigator.of(context).pop(),
      ),
    ],
  );
}
