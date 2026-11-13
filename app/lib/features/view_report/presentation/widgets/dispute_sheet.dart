import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/text/utf16_length_limiting_formatter.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_field_box.dart';
import '../../../../core/ui/cora_primary_button.dart';

/// 이의 사유의 최대 글자 수(서버 검증과 같다, `VIEW_REPORT_POLICY`). 서버가 UTF-16 단위로 세므로 앱도 그렇게 센다.
const disputeReasonMaxLength = 200;

/// F4의 `이의 제기`를 누르면 아래에서 올라오는 시트(캔버스에 없는 화면): 사유 입력, 안내, `제기하기`.
/// [onSubmit]은 성공하면 null, 실패하면 시트에 보일 문구를 돌려준다. 성공하면 시트가 닫히고 true를
/// 돌려준다(바깥을 눌러 닫으면 null).
Future<bool?> showDisputeSheet(
  BuildContext context, {
  required Future<String?> Function(String reason) onSubmit,
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
    builder: (_) => DisputeSheet(onSubmit: onSubmit),
  );
}

class DisputeSheet extends StatefulWidget {
  const DisputeSheet({super.key, required this.onSubmit});

  final Future<String?> Function(String reason) onSubmit;

  static const title = '이의 제기';
  static const field = '이의 사유';
  static const note = '이의를 제기하면 운영팀이 확인할 때까지 지급이 멈춰요.';
  static const submit = '제기하기';

  @override
  State<DisputeSheet> createState() => _DisputeSheetState();
}

class _DisputeSheetState extends State<DisputeSheet> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSubmit => _controller.text.trim().isNotEmpty && !_busy;

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await widget.onSubmit(_controller.text);
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
  Widget build(BuildContext context) {
    final c = context.colors;
    final media = MediaQuery.of(context);
    final bottom = math.max(32.0, media.viewPadding.bottom);
    return Padding(
      // 키보드가 올라오면 그만큼 시트가 밀려 올라간다.
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 28, 16, bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Semantics(
                header: true,
                child: Text(
                  DisputeSheet.title,
                  style: CoraTextStyles.heading.copyWith(color: c.text),
                ),
              ),
            ),
            const SizedBox(height: 16),
            CoraFieldBox(
              label: DisputeSheet.field,
              controller: _controller,
              enabled: !_busy,
              inputFormatters: const [
                Utf16LengthLimitingFormatter(disputeReasonMaxLength),
              ],
              minLines: 3,
              maxLines: 5,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: [
                  Expanded(
                    child: Text(
                      DisputeSheet.note,
                      style: CoraTextStyles.meta.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    '${_controller.text.length}/$disputeReasonMaxLength',
                    style: CoraTextStyles.meta.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: CoraTextStyles.meta.copyWith(color: c.text),
                  ),
                ),
              ),
            CoraPrimaryButton(
              label: DisputeSheet.submit,
              onPressed: _canSubmit ? _submit : null,
              look: CoraPrimaryButtonLook.accent,
            ),
          ],
        ),
      ),
    );
  }
}
