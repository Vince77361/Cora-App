import 'package:flutter/material.dart';

import '../../../../core/text/utf16_length_limiting_formatter.dart';
import '../../../../core/ui/cora_field_box.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../../domain/chat_repository.dart' show ReportReason;
import '../chat_text.dart';
import 'chat_sheet.dart';

/// `신고하기`를 누르면 올라오는 시트(캔버스에 없는 화면): 사유 넷 중 하나, 자세한 내용(선택), `신고하기`.
/// [onSubmit]은 성공하면 null, 실패하면 시트에 보일 문구를 돌려준다(이미 신고했으면 그 문구). 성공하면 시트가
/// 닫히며 true를 돌려주고, 시트 밖을 누르면 null이다.
Future<bool?> showReportSheet(
  BuildContext context, {
  required Future<String?> Function(ReportReason reason, String detail)
  onSubmit,
}) => showChatSheet<bool>(context, (_) => ReportSheet(onSubmit: onSubmit));

class ReportSheet extends StatefulWidget {
  const ReportSheet({super.key, required this.onSubmit});

  final Future<String?> Function(ReportReason reason, String detail) onSubmit;

  @override
  State<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<ReportSheet> with ChatSheetAction {
  final _detail = TextEditingController();
  ReportReason? _reason;
  @override
  void dispose() {
    _detail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ChatSheetBody(
    children: [
      const ChatSheetHeading(title: ChatTexts.reportTitle),
      const SizedBox(height: 8),
      for (final reason in ReportReason.values)
        ChatReasonRow(
          label: reportReasonLabel(reason),
          picked: _reason == reason,
          onTap: busy ? null : () => setState(() => _reason = reason),
        ),
      const SizedBox(height: 12),
      CoraFieldBox(
        label: ChatTexts.reportDetail,
        controller: _detail,
        enabled: !busy,
        inputFormatters: const [
          Utf16LengthLimitingFormatter(ChatTexts.reportDetailMax),
        ],
        minLines: 3,
        maxLines: 5,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        onChanged: (_) {},
      ),
      const SizedBox(height: 20),
      if (error != null) ChatSheetError(text: error!),
      CoraPrimaryButton(
        label: ChatTexts.reportSubmit,
        onPressed: _reason == null || busy
            ? null
            : () => runAction(() => widget.onSubmit(_reason!, _detail.text)),
      ),
    ],
  );
}
