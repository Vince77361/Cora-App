import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/cora_colors.dart';
import '../theme/cora_shapes.dart';
import '../theme/cora_text_styles.dart';
import 'cora_pressable.dart';

/// 입력 칸(NEditProfile 칸과 같은 모양): 모서리 20, `surface` 바탕, 안쪽 14/18, 라벨 12 보조색 →
/// 4 → 값 16. 캔버스에 없는 화면(링크 제출, 계좌, 인스타그램 아이디)이 같은 칸을 쓴다.
class CoraFieldBox extends StatelessWidget {
  const CoraFieldBox({
    super.key,
    required this.label,
    required this.controller,
    required this.onChanged,
    this.fieldKey,
    this.maxLength,
    this.keyboardType = TextInputType.text,
    this.inputFormatters = const [],
    this.autofillHints,
    this.enabled = true,
    this.onSubmitted,
    this.textInputAction = TextInputAction.done,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final Key? fieldKey;
  final int? maxLength;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final Iterable<String>? autofillHints;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(CoraRadius.field),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: CoraTextStyles.fieldLabel.copyWith(
                  color: c.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                key: fieldKey,
                controller: controller,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                enabled: enabled,
                keyboardType: keyboardType,
                textInputAction: textInputAction,
                autofillHints: autofillHints,
                style: CoraTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w400,
                  color: c.text,
                ),
                cursorColor: c.text,
                inputFormatters: [
                  ?(maxLength == null
                      ? null
                      : LengthLimitingTextInputFormatter(maxLength)),
                  ...inputFormatters,
                ],
                decoration: const InputDecoration(
                  isCollapsed: true,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 목록에서 고르는 칸. [CoraFieldBox]와 같은 모양이고 오른쪽에 아래 화살표가 있다.
class CoraPickBox extends StatelessWidget {
  const CoraPickBox({
    super.key,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final valueStyle = CoraTextStyles.bodyLarge.copyWith(
      fontWeight: FontWeight.w400,
      color: value == null ? c.textSecondary : c.text,
    );
    return Semantics(
      container: true,
      button: true,
      enabled: onTap != null,
      onTap: onTap,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(CoraRadius.field),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: CoraTextStyles.fieldLabel.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(value ?? placeholder, style: valueStyle),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  CustomPaint(
                    size: const Size.square(18),
                    painter: _ChevronDownPainter(c.textSecondary),
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

/// SVG `M6 9l6 6 6-6`(viewBox 24, 선 2.2, 둥근 끝)을 18로 줄여 그린다.
class _ChevronDownPainter extends CustomPainter {
  const _ChevronDownPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    canvas.drawPath(
      Path()
        ..moveTo(6, 9)
        ..lineTo(12, 15)
        ..lineTo(18, 9),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_ChevronDownPainter old) => old.color != color;
}
