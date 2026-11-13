import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/navigation/cora_transitions.dart';
import '../../../../core/ui/cora_field_box.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../../../../core/ui/cora_secondary_button.dart';
import '../../../server_config/domain/server_config.dart';
import '../../domain/offer_terms.dart';
import '../offer_terms_text.dart';
import 'offer_sheet_frame.dart';

/// 제공 혜택 시트가 돌려주는 값. [voucher]가 null이면 `혜택 없음`을 골랐다는 뜻이다.
/// 그냥 닫으면 시트 자체가 null을 돌려준다.
typedef BenefitEdit = ({Voucher? voucher});

/// F1 `제공 혜택`을 고치는 시트: 이름, 금액, 인원을 적거나 `혜택 없음`을 고른다.
/// 캔버스에 없는 화면이라 식사권 고치기와 같은 모양으로 만들었다.
Future<BenefitEdit?> showBenefitEditSheet(
  BuildContext context, {
  required Voucher? initial,
  required VoucherDefaults defaults,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return Navigator.of(context, rootNavigator: true).push<BenefitEdit>(
    CoraTransitions.sheet<BenefitEdit>(
      BenefitEditSheet(initial: initial, defaults: defaults),
    ).createRoute(context),
  );
}

class BenefitEditSheet extends StatefulWidget {
  const BenefitEditSheet({
    super.key,
    required this.initial,
    required this.defaults,
  });

  /// 지금 혜택. 없으면(`혜택 없음`) 서버 설정의 기본값을 채워 연다.
  final Voucher? initial;
  final VoucherDefaults defaults;

  static const title = '제공 혜택';
  static const nameLabel = '이름';
  static const valueLabel = '금액 (원)';
  static const peopleLabel = '인원';
  static const saveLabel = '저장';
  static const noneLabel = '혜택 없음';
  static const nameKey = ValueKey<String>('benefitEdit.name');
  static const valueKey = ValueKey<String>('benefitEdit.value');
  static const peopleKey = ValueKey<String>('benefitEdit.people');
  static const emptyNameMessage = '식사권 이름을 적어 주세요.';
  static const valueRangeMessage = '금액은 1,000원에서 1,000,000원 사이로 적어 주세요.';
  static String peopleRangeMessage(int max) => '인원은 1명에서 $max명 사이로 적어 주세요.';

  @override
  State<BenefitEditSheet> createState() => _BenefitEditSheetState();
}

class _BenefitEditSheetState extends State<BenefitEditSheet> {
  late final _name = TextEditingController(
    text: widget.initial?.name ?? widget.defaults.name,
  );
  late final _value = TextEditingController(
    text: (widget.initial?.value ?? widget.defaults.value).toString(),
  );
  late final _people = TextEditingController(
    text: (widget.initial?.people ?? widget.defaults.people).toString(),
  );
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _value.dispose();
    _people.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    final value = int.tryParse(_value.text.trim());
    final people = int.tryParse(_people.text.trim());
    final maxPeople = widget.defaults.maxPeople;
    if (name.isEmpty) {
      setState(() => _error = BenefitEditSheet.emptyNameMessage);
      return;
    }
    if (value == null || value < voucherValueMin || value > voucherValueMax) {
      setState(() => _error = BenefitEditSheet.valueRangeMessage);
      return;
    }
    if (people == null || people < 1 || people > maxPeople) {
      setState(() => _error = BenefitEditSheet.peopleRangeMessage(maxPeople));
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop<BenefitEdit>((
      voucher: Voucher(name: name, value: value, people: people),
    ));
  }

  void _none() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop<BenefitEdit>((voucher: null));
  }

  @override
  Widget build(BuildContext context) {
    void clearError(String _) => setState(() => _error = null);
    return OfferSheetFrame(
      title: BenefitEditSheet.title,
      error: _error,
      fields: [
        CoraFieldBox(
          fieldKey: BenefitEditSheet.nameKey,
          label: BenefitEditSheet.nameLabel,
          controller: _name,
          onChanged: clearError,
          maxLength: voucherNameMaxLength,
          textInputAction: TextInputAction.next,
        ),
        CoraFieldBox(
          fieldKey: BenefitEditSheet.valueKey,
          label: BenefitEditSheet.valueLabel,
          controller: _value,
          onChanged: clearError,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            // 100만 원이 일곱 자리다.
            LengthLimitingTextInputFormatter(7),
          ],
          textInputAction: TextInputAction.next,
        ),
        CoraFieldBox(
          fieldKey: BenefitEditSheet.peopleKey,
          label: BenefitEditSheet.peopleLabel,
          controller: _people,
          onChanged: clearError,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(2),
          ],
        ),
      ],
      actions: [
        CoraPrimaryButton(
          label: BenefitEditSheet.saveLabel,
          onPressed: _save,
          look: CoraPrimaryButtonLook.accent,
        ),
        CoraSecondaryButton(
          label: BenefitEditSheet.noneLabel,
          onPressed: _none,
        ),
      ],
    );
  }
}
