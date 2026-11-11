import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/navigation/cora_transitions.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../offer_terms_text.dart';

/// 식사권 이름과 금액을 고치는 시트. 저장하면 고친 값을 돌려주고, 그냥 닫으면 null이다.
///
/// 캔버스에 없는 화면이라 가게 정보 고치기의 입력 칸(NEditProfile)과 같은 모양으로 만들었다.
Future<({String name, int value})?> showVoucherEditSheet(
  BuildContext context, {
  required String name,
  required int value,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return Navigator.of(
    context,
    rootNavigator: true,
  ).push<({String name, int value})>(
    CoraTransitions.sheet<({String name, int value})>(
      VoucherEditSheet(initialName: name, initialValue: value),
    ).createRoute(context),
  );
}

class VoucherEditSheet extends StatefulWidget {
  const VoucherEditSheet({
    super.key,
    required this.initialName,
    required this.initialValue,
  });

  final String initialName;
  final int initialValue;

  static const title = '식사권 고치기';
  static const nameLabel = '이름';
  static const valueLabel = '금액 (원)';
  static const saveLabel = '저장';
  static const nameKey = ValueKey<String>('voucherEdit.name');
  static const valueKey = ValueKey<String>('voucherEdit.value');
  static const emptyNameMessage = '식사권 이름을 적어 주세요.';
  static const valueRangeMessage = '금액은 1,000원에서 1,000,000원 사이로 적어 주세요.';

  @override
  State<VoucherEditSheet> createState() => _VoucherEditSheetState();
}

class _VoucherEditSheetState extends State<VoucherEditSheet> {
  late final _name = TextEditingController(text: widget.initialName);
  late final _value = TextEditingController(
    text: widget.initialValue.toString(),
  );
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _value.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    final value = int.tryParse(_value.text.trim());
    if (name.isEmpty) {
      setState(() => _error = VoucherEditSheet.emptyNameMessage);
      return;
    }
    if (value == null || value < voucherValueMin || value > voucherValueMax) {
      setState(() => _error = VoucherEditSheet.valueRangeMessage);
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop((name: name, value: value));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final media = MediaQuery.of(context);
    // 키보드가 올라오면 버튼이 키보드 위에 오고, 아니면 안전 영역 위에 오되 최소 32를 둔다.
    final bottom = media.viewInsets.bottom > 0
        ? media.viewInsets.bottom + 16
        : math.max(32.0, media.viewPadding.bottom);
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
              child: Semantics(
                header: true,
                child: Text(
                  VoucherEditSheet.title,
                  style: CoraTextStyles.heading.copyWith(color: c.text),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 10,
                  children: [
                    _Field(
                      fieldKey: VoucherEditSheet.nameKey,
                      label: VoucherEditSheet.nameLabel,
                      controller: _name,
                      onChanged: (_) => setState(() => _error = null),
                      formatters: [
                        LengthLimitingTextInputFormatter(voucherNameMaxLength),
                      ],
                      keyboardType: TextInputType.text,
                    ),
                    _Field(
                      fieldKey: VoucherEditSheet.valueKey,
                      label: VoucherEditSheet.valueLabel,
                      controller: _value,
                      onChanged: (_) => setState(() => _error = null),
                      formatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        // 100만 원이 일곱 자리다.
                        LengthLimitingTextInputFormatter(7),
                      ],
                      keyboardType: TextInputType.number,
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            _error!,
                            style: CoraTextStyles.meta.copyWith(color: c.text),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, bottom),
              child: CoraPrimaryButton(
                label: VoucherEditSheet.saveLabel,
                onPressed: _save,
                look: CoraPrimaryButtonLook.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 입력 칸(NEditProfile): 모서리 20, `surface` 바탕, 안쪽 14/18, 라벨 12 보조색 → 4 → 값 16.
class _Field extends StatelessWidget {
  const _Field({
    required this.fieldKey,
    required this.label,
    required this.controller,
    required this.onChanged,
    required this.formatters,
    required this.keyboardType,
  });

  final Key fieldKey;
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final List<TextInputFormatter> formatters;
  final TextInputType keyboardType;

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
                keyboardType: keyboardType,
                textInputAction: TextInputAction.next,
                style: CoraTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w400,
                  color: c.text,
                ),
                cursorColor: c.text,
                inputFormatters: formatters,
                // 앱 테마의 입력칸 테두리를 쓰지 않는다. 칸 모양은 바깥 상자가 그린다.
                // `InputDecoration.collapsed`도 테마의 테두리를 물려받아 직접 끈다.
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
