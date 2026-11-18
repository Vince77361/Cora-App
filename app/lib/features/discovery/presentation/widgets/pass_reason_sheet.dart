import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_swipe_tokens.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../domain/pass_reason.dart';
import '../discovery_text.dart';

/// 02 넘기기 이유. 아래에서 올라오는 시트로, 이미 넘긴 **뒤에** 알림의 `이유 남기기`를 눌렀을 때만 뜬다.
/// 넘김은 시트가 뜨기 전에 저장돼 있다.
///
/// - [onSave]: 이유를 골랐고 `이유 남기고 다음 보기`를 눌렀을 때. 실패하면 던지고 시트는 열려 있다.
///   고른 이유가 없으면 이 버튼은 꺼진 모양이다.
/// - `건너뛰기`를 누르거나 시트를 내려 닫으면 아무것도 저장하지 않는다(둘이 같다).
/// - 되돌리기는 시트가 아니라 카드 아래 버튼 줄이 맡는다(2026-11-19 설계 4.2장).
Future<void> showPassReasonSheet(
  BuildContext context, {
  required Future<void> Function(PassReason reason) onSave,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    // 바탕은 시트 안에서 칠한다. 시트가 열린 채 밝기가 바뀌어도 따라가게 한다.
    backgroundColor: Colors.transparent,
    // 캔버스 Pass의 뒤 덮개 rgba(15,16,18,0.45). 두 모드가 같다.
    barrierColor: CoraSwipeTokens.sheetBarrier,
    elevation: 0,
    showDragHandle: false,
    builder: (context) => DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: PassReasonSheet(onSave: onSave),
    ),
  );
}

class PassReasonSheet extends StatefulWidget {
  const PassReasonSheet({super.key, required this.onSave});

  final Future<void> Function(PassReason reason) onSave;

  @override
  State<PassReasonSheet> createState() => _PassReasonSheetState();
}

class _PassReasonSheetState extends State<PassReasonSheet> {
  PassReason? _picked;
  bool _busy = false;
  String? _message;

  Future<void> _save() async {
    // 저장하는 동안의 연타가 두 번 저장하거나 시트를 두 번 닫지 않게 한다.
    final reason = _picked;
    if (_busy || reason == null) return;
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

  void _skip() {
    if (_busy) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // 저장하는 동안에도 모양은 켜진 채로 둔다. 누름만 `_save`가 막는다.
    final canSave = _picked != null;
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
                  enabled: canSave && !_busy,
                  onTap: canSave && !_busy ? _save : null,
                  child: ExcludeSemantics(
                    child: CoraPressable(
                      onTap: canSave ? _save : null,
                      child: Container(
                        height: 56,
                        alignment: Alignment.center,
                        // 고른 이유가 없으면 꺼진 모양(`accent` 버튼이 꺼질 때와 같은 `surface` 바탕).
                        decoration: BoxDecoration(
                          color: canSave ? c.accent : c.surface,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          DiscoveryTexts.reasonSave,
                          style: CoraTextStyles.button.copyWith(
                            color: canSave ? c.onAccent : c.textSecondary,
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
                  onTap: _busy ? null : _skip,
                  child: ExcludeSemantics(
                    child: CoraPressable(
                      onTap: _busy ? () {} : _skip,
                      child: Container(
                        height: 44,
                        alignment: Alignment.center,
                        child: Text(
                          DiscoveryTexts.reasonSkip,
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
