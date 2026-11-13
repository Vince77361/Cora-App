import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/cora_transitions.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../../../offer_terms/domain/proposal_draft.dart';
import '../../../offer_terms/presentation/pages/reward_budget_page.dart';
import '../../../offer_terms/presentation/viewmodels/proposal_draft_view_model.dart';
import '../../../offer_terms/presentation/widgets/offer_sheet_frame.dart';

/// F6 `희망 보상`을 눌렀을 때: F1의 세 줄(제공 혜택, 고정 현금, 조회수 수당)을 고치는 시트(캔버스 밖).
/// 고른 값은 바로 [target]의 초안에 반영되고, `확인`으로 닫는다.
Future<void> showHopeRewardSheet(BuildContext context, CounterTarget target) {
  FocusManager.instance.primaryFocus?.unfocus();
  return Navigator.of(context, rootNavigator: true).push<void>(
    CoraTransitions.sheet<void>(
      HopeRewardSheet(target: target),
    ).createRoute(context),
  );
}

class HopeRewardSheet extends ConsumerWidget {
  const HopeRewardSheet({super.key, required this.target});

  final CounterTarget target;

  static const title = '희망 보상';
  static const confirm = '확인';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final burden =
        ref
            .watch(proposalDraftViewModelProvider(target))
            .value
            ?.reward
            .maxCashBurden ??
        0;
    return OfferSheetFrame(
      title: title,
      fields: [
        RewardEditor(target: target),
        RewardBurdenBox(amount: burden),
      ],
      actions: [
        CoraPrimaryButton(
          label: confirm,
          onPressed: () => Navigator.of(context).pop(),
          look: CoraPrimaryButtonLook.accent,
        ),
      ],
    );
  }
}
