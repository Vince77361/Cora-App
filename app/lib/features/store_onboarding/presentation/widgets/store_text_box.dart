import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_pressable.dart';
import 'store_icons.dart';

/// 가게 정보 고치기의 입력 칸(NEditProfile): 모서리 20, `surface` 바탕, 안쪽 14/18, 라벨 12
/// 보조색 → 4 → 값 16(여러 줄은 15에 줄 높이 1.55).
class StoreTextBox extends StatelessWidget {
  const StoreTextBox({
    super.key,
    required this.label,
    required this.controller,
    required this.onChanged,
    required this.maxLength,
    this.fieldKey,
    this.focusNode,
    this.multiline = false,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final int maxLength;
  final Key? fieldKey;
  final FocusNode? focusNode;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // 값 글자: 한 줄은 16, 여러 줄(소개)은 15에 줄 높이 1.55. 캔버스는 입력에 줄 높이를 따로 주지
    // 않아(`normal`) 한 줄은 1.448이다.
    final valueStyle = multiline
        ? CoraTextStyles.body.copyWith(height: 1.55, color: c.text)
        : CoraTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w400,
            color: c.text,
          );
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
                focusNode: focusNode,
                onChanged: onChanged,
                minLines: multiline ? 3 : 1,
                maxLines: multiline ? 3 : 1,
                keyboardType: multiline
                    ? TextInputType.multiline
                    : TextInputType.text,
                textInputAction: multiline
                    ? TextInputAction.newline
                    : TextInputAction.next,
                style: valueStyle,
                cursorColor: c.text,
                inputFormatters: [LengthLimitingTextInputFormatter(maxLength)],
                decoration: storeFieldDecoration(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 목록에서 고르는 칸(업종 분류, 시·도). 입력 칸과 같은 모양이고 오른쪽에 아래 화살표가 있다.
class StorePickBox extends StatelessWidget {
  const StorePickBox({
    super.key,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final valueStyle = CoraTextStyles.bodyLarge.copyWith(
      fontWeight: FontWeight.w400,
    );
    return Semantics(
      container: true,
      button: true,
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
                        Text(
                          value ?? placeholder,
                          style: valueStyle.copyWith(
                            color: value == null ? c.textSecondary : c.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StoreIcon(
                    StoreIconPainter.chevronDown(c.textSecondary),
                    size: 18,
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

/// 바깥 상자가 칸 모양을 그리므로 입력란 자체는 테두리와 안쪽 여백이 없다. `InputDecoration.collapsed`도
/// 앱 테마의 입력칸 테두리를 물려받아 직접 모두 끈다.
InputDecoration storeFieldDecoration({String? hint, TextStyle? hintStyle}) =>
    InputDecoration(
      isCollapsed: true,
      isDense: true,
      contentPadding: EdgeInsets.zero,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      hintText: hint,
      hintStyle: hintStyle,
    );
