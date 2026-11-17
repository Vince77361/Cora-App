import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/text/utf16_length_limiting_formatter.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_field_box.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../received_proposals_text.dart';
import '../viewmodels/received_proposal_view_model.dart';

/// `조건부터 질문하기`가 여는 시트(캔버스에 없는 화면, 계획 Task 11의 문구). 질문을 적어(1,000자, 필수)
/// `질문 보내기`를 누르면 [onSubmit]이 보내고, 보냈으면 시트가 `true`로 닫힌다. 이미 질문했거나 보내지 못했으면
/// 시트를 닫지 않고 그 안내를 보인다. 그냥 닫으면 null이다.
Future<bool?> showInquirySheet(
  BuildContext context, {
  required Future<InquiryOutcome> Function(String message) onSubmit,
}) {
  final c = context.colors;
  return showModalBottomSheet<bool>(
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
      child: InquirySheet(onSubmit: onSubmit),
    ),
  );
}

class InquirySheet extends StatefulWidget {
  const InquirySheet({super.key, required this.onSubmit});

  final Future<InquiryOutcome> Function(String message) onSubmit;

  @visibleForTesting
  static const fieldKey = ValueKey<String>('inquiry.field');

  @override
  State<InquirySheet> createState() => _InquirySheetState();
}

class _InquirySheetState extends State<InquirySheet> {
  final _controller = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSend => !_sending && _controller.text.trim().isNotEmpty;

  Future<void> _send() async {
    if (!_canSend) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    final outcome = await widget.onSubmit(_controller.text);
    if (!mounted) return;
    switch (outcome) {
      case InquiryOutcome.sent:
        Navigator.of(context).pop(true);
      case InquiryOutcome.conflict:
        setState(() {
          _sending = false;
          _error = ReceivedProposalsTexts.inquiryConflict;
        });
      case InquiryOutcome.failed:
        setState(() {
          _sending = false;
          _error = ReceivedProposalsTexts.inquiryFailed;
        });
    }
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
                ReceivedProposalsTexts.inquiryTitle,
                style: CoraTextStyles.heading.copyWith(color: c.text),
              ),
            ),
          ),
          const SizedBox(height: 16),
          CoraFieldBox(
            fieldKey: InquirySheet.fieldKey,
            label: ReceivedProposalsTexts.inquiryField,
            controller: _controller,
            onChanged: (_) => setState(() => _error = null),
            inputFormatters: const [
              Utf16LengthLimitingFormatter(ReceivedProposalsTexts.inquiryMax),
            ],
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            minLines: 3,
            maxLines: 6,
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  _error!,
                  style: CoraTextStyles.bodySmall.copyWith(
                    color: c.textSecondary,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          CoraPrimaryButton(
            label: ReceivedProposalsTexts.inquirySend,
            look: CoraPrimaryButtonLook.accent,
            onPressed: _canSend ? _send : null,
          ),
        ],
      ),
    );
  }
}
