import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../domain/pass_reason.dart';
import '../../domain/undo_result.dart';
import '../discovery_text.dart';

/// 02 넘기기 이유. 아래에서 올라오는 시트로, 이미 넘긴 **뒤에** 알림의 `이유 남기기`를 눌렀을 때만 뜬다.
/// 넘김은 시트가 뜨기 전에 저장돼 있다.
///
/// - [onSave]: 이유를 골랐고 `이유 남기고 다음 보기`를 눌렀을 때. 실패하면 던지고 시트는 열려 있다.
/// - [onUndo]: `되돌리기`. 되돌렸으면 시트를 닫고, 되돌릴 수 없으면 시트 안에 안내를 보인다.
/// - 고르지 않고 `이유 없이 다음 보기`를 누르거나 시트를 내려 닫으면 아무것도 저장하지 않는다.
Future<void> showPassReasonSheet(
  BuildContext context, {
  required Future<void> Function(PassReason reason) onSave,
  required Future<UndoResult> Function() onUndo,
}) {
  final c = context.colors;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: c.background,
    // 캔버스 Pass의 뒤 덮개 rgba(15,16,18,0.45). 두 모드가 같다.
    barrierColor: const Color(0x730F1012),
    elevation: 0,
    showDragHandle: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => PassReasonSheet(onSave: onSave, onUndo: onUndo),
  );
}

class PassReasonSheet extends StatefulWidget {
  const PassReasonSheet({
    super.key,
    required this.onSave,
    required this.onUndo,
  });

  final Future<void> Function(PassReason reason) onSave;
  final Future<UndoResult> Function() onUndo;

  @override
  State<PassReasonSheet> createState() => _PassReasonSheetState();
}

class _PassReasonSheetState extends State<PassReasonSheet> {
  PassReason? _picked;
  bool _busy = false;
  String? _message;

  Future<void> _primary() async {
    final reason = _picked;
    if (reason == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await widget.onSave(reason);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = DiscoveryTexts.retryLater;
      });
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _undo() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    final result = await widget.onUndo();
    if (!mounted) return;
    if (result == UndoResult.undone) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _busy = false;
      _message = result == UndoResult.nothing
          ? DiscoveryTexts.undoTooLate
          : DiscoveryTexts.retryLater;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 12, 0, bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.line,
                borderRadius: BorderRadius.circular(3),
              ),
              child: const SizedBox(width: 40, height: 5),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    DiscoveryTexts.reasonTitle,
                    style: CoraTextStyles.bodyLarge.copyWith(
                      fontSize: 20,
                      letterSpacing: -0.4,
                      color: c.text,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  DiscoveryTexts.reasonBody,
                  style: CoraTextStyles.bodySmall.copyWith(
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          for (final reason in PassReason.values)
            _ReasonRow(
              reason: reason,
              picked: _picked == reason,
              // 고른 것을 다시 누르면 풀린다.
              onTap: _busy
                  ? null
                  : () => setState(
                      () => _picked = _picked == reason ? null : reason,
                    ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 4,
              children: [
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        _message!,
                        textAlign: TextAlign.center,
                        style: CoraTextStyles.meta.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                  ),
                Semantics(
                  container: true,
                  button: true,
                  enabled: !_busy,
                  onTap: _busy ? null : _primary,
                  child: ExcludeSemantics(
                    child: CoraPressable(
                      onTap: _busy ? () {} : _primary,
                      child: Container(
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c.accent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _picked == null
                              ? DiscoveryTexts.reasonSkip
                              : DiscoveryTexts.reasonSave,
                          style: CoraTextStyles.button.copyWith(
                            color: c.onAccent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Semantics(
                  container: true,
                  button: true,
                  enabled: !_busy,
                  onTap: _busy ? null : _undo,
                  child: ExcludeSemantics(
                    child: CoraPressable(
                      onTap: _busy ? () {} : _undo,
                      child: Container(
                        height: 44,
                        alignment: Alignment.center,
                        child: Text(
                          DiscoveryTexts.reasonUndo,
                          style: CoraTextStyles.buttonMedium.copyWith(
                            fontSize: 14,
                            color: c.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonRow extends StatelessWidget {
  const _ReasonRow({
    required this.reason,
    required this.picked,
    required this.onTap,
  });

  final PassReason reason;
  final bool picked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      selected: picked,
      label: reason.label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onTap ?? () {},
          child: SizedBox(
            height: 60,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                spacing: 14,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: picked ? c.accent : c.surface,
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox.square(
                      dimension: 40,
                      child: Center(
                        child: CustomPaint(
                          size: const Size.square(18),
                          painter: _ReasonIconPainter(
                            reason,
                            picked ? c.onAccent : c.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      reason.label,
                      style: CoraTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w400,
                        color: c.text,
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: picked ? c.accent : c.line,
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox.square(
                      dimension: 22,
                      child: Center(
                        child: picked
                            ? CustomPaint(
                                size: const Size.square(12),
                                painter: _CheckPainter(c.onAccent),
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 캔버스 Pass의 선 그림(24칸, 선 2, 둥근 끝).
class _ReasonIconPainter extends CustomPainter {
  const _ReasonIconPainter(this.reason, this.color);

  final PassReason reason;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (reason) {
      case PassReason.mood:
        canvas.drawCircle(const Offset(12, 12), 9, paint);
        canvas.drawPath(
          Path()
            ..moveTo(8, 14)
            ..cubicTo(8, 14, 9.5, 16, 12, 16)
            ..cubicTo(14.5, 16, 16, 14, 16, 14),
          paint,
        );
      case PassReason.region:
        canvas.drawPath(
          Path()
            ..moveTo(12, 21)
            ..cubicTo(12, 21, 6, 15.6, 6, 10)
            ..arcToPoint(const Offset(18, 10), radius: const Radius.circular(6))
            ..cubicTo(18, 15.6, 12, 21, 12, 21)
            ..close(),
          paint,
        );
        canvas.drawCircle(const Offset(12, 10), 2, paint);
      case PassReason.fee:
        canvas.drawLine(const Offset(12, 2), const Offset(12, 22), paint);
        canvas.drawPath(
          Path()
            ..moveTo(17, 6)
            ..lineTo(9.5, 6)
            ..arcToPoint(
              const Offset(9.5, 13),
              radius: const Radius.circular(3.5),
              clockwise: false,
            )
            ..lineTo(14.5, 13)
            ..arcToPoint(
              const Offset(14.5, 20),
              radius: const Radius.circular(3.5),
            )
            ..lineTo(6, 20),
          paint,
        );
      case PassReason.field:
        canvas.drawLine(const Offset(4, 6), const Offset(20, 6), paint);
        canvas.drawLine(const Offset(4, 12), const Offset(20, 12), paint);
        canvas.drawLine(const Offset(4, 18), const Offset(14, 18), paint);
    }
  }

  @override
  bool shouldRepaint(_ReasonIconPainter old) =>
      old.reason != reason || old.color != color;
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    canvas.drawPath(
      Path()
        ..moveTo(5, 12)
        ..lineTo(10, 17)
        ..lineTo(19, 7),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.color != color;
}
