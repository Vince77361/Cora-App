import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/navigation/cora_transitions.dart';
import '../../../../core/text/josa.dart';
import '../../../../core/ui/cora_field_box.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../offer_terms_text.dart';
import 'offer_sheet_frame.dart';

/// F1 `고정 현금 (선택)`의 `직접 입력` 시트(캔버스 밖). 원 단위 숫자를 적고, 눈금([step], 1만 원)에
/// 맞는 [max]까지 받는다. 저장하면 금액을, 그냥 닫으면 null을 돌려준다.
Future<int?> showFixedCashSheet(
  BuildContext context, {
  required int initial,
  required int max,
  required int step,
  String name = FixedCashSheet.title,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return Navigator.of(context, rootNavigator: true).push<int>(
    CoraTransitions.sheet<int>(
      FixedCashSheet(initial: initial, max: max, step: step, name: name),
    ).createRoute(context),
  );
}

class FixedCashSheet extends StatefulWidget {
  const FixedCashSheet({
    super.key,
    required this.initial,
    required this.max,
    required this.step,
    this.name = title,
  });

  final int initial;
  final int max;
  final int step;

  /// 시트의 이름이자 범위 안내 문장의 주어. 가게는 `고정 현금`, 브랜드는 `현금 고정비`(캔버스 밖)다.
  final String name;

  static const title = '고정 현금';
  static const valueLabel = '금액 (원)';
  static const saveLabel = '저장';
  static const valueKey = ValueKey<String>('fixedCash.value');
  static String rangeMessage(int step, int max, {String name = title}) =>
      '${josa(name, JosaPair.eunNeun)} ${wonExact(step)} 단위로, ${wonExact(max)}까지 적어 주세요.';

  @override
  State<FixedCashSheet> createState() => _FixedCashSheetState();
}

class _FixedCashSheetState extends State<FixedCashSheet> {
  late final _value = TextEditingController(
    text: widget.initial == 0 ? '' : widget.initial.toString(),
  );
  String? _error;

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  void _save() {
    final value = int.tryParse(_value.text.trim());
    if (value == null ||
        value <= 0 ||
        value > widget.max ||
        value % widget.step != 0) {
      setState(
        () => _error = FixedCashSheet.rangeMessage(
          widget.step,
          widget.max,
          name: widget.name,
        ),
      );
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop<int>(value);
  }

  @override
  Widget build(BuildContext context) {
    return OfferSheetFrame(
      title: widget.name,
      error: _error,
      fields: [
        CoraFieldBox(
          fieldKey: FixedCashSheet.valueKey,
          label: FixedCashSheet.valueLabel,
          controller: _value,
          onChanged: (_) => setState(() => _error = null),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(8),
          ],
          onSubmitted: (_) => _save(),
        ),
      ],
      actions: [
        CoraPrimaryButton(
          label: FixedCashSheet.saveLabel,
          onPressed: _save,
          look: CoraPrimaryButtonLook.accent,
        ),
      ],
    );
  }
}
