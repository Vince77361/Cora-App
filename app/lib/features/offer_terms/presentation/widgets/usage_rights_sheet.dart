import 'package:flutter/widgets.dart';

import '../../../store_onboarding/presentation/widgets/option_sheet.dart';
import '../../domain/offer_terms.dart';
import '../offer_terms_text.dart';

/// F2 `사용권` 줄을 눌렀을 때 세 선택지를 보인다(캔버스 밖). 고른 값을, 그냥 닫으면 null을 돌려준다.
Future<UsageRights?> showUsageRightsSheet(
  BuildContext context, {
  required UsageRights selected,
}) => showStoreOptionSheet<UsageRights>(
  context,
  title: '사용권',
  options: UsageRights.values,
  labelOf: usageRightsLabel,
  selected: selected,
);
