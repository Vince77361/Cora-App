import 'package:flutter/widgets.dart';

import '../../../server_config/domain/server_config.dart';
import '../../../store_onboarding/presentation/widgets/option_sheet.dart';
import '../offer_terms_text.dart';

/// F1 `단가` 줄을 눌렀을 때: 서버 설정의 범위 안에서 1,000회당 금액을 고른다(캔버스 밖).
/// 고른 값을, 그냥 닫으면 null을 돌려준다.
Future<int?> showRateSheet(
  BuildContext context, {
  required StepRange range,
  required int selected,
}) => showStoreOptionSheet<int>(
  context,
  title: '단가',
  options: range.values,
  labelOf: rateLabel,
  selected: selected,
);

/// F1 `1인 상한` 줄을 눌렀을 때: 서버 설정의 범위 안에서 상한을 고른다(캔버스 밖).
Future<int?> showCapSheet(
  BuildContext context, {
  required StepRange range,
  required int selected,
}) => showStoreOptionSheet<int>(
  context,
  title: '1인 상한',
  options: range.values,
  labelOf: capLabel,
  selected: selected,
);
