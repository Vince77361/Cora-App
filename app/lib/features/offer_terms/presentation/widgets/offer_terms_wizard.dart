import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_motion.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../../../../core/ui/cora_step_header.dart';
import '../../domain/offer_terms.dart';
import '../viewmodels/offer_terms_wizard_view_model.dart';
import 'confirm_step.dart';
import 'format_step.dart';
import 'reward_step.dart';
import 'voucher_edit_sheet.dart';

/// 오퍼 조건 3단계(형식 → 보상 → 확인). 기본 조건 화면과 오퍼 보내기(A5)가 함께 쓴다.
///
/// 머리글에는 화면 이름을 그리지 않는다(소유자가 2026-11-12에 뺐다). [pageLabel]은 화면 읽기
/// 프로그램용 이름이다.
/// 마지막 단계의 버튼은 [submitLabel]이고, 누르면 고른 조건으로 [onSubmit]을 부른다. [onSubmit]이
/// 예외(`Exception`)를 던지면 확인 단계에 머물며 [failureMessage]를 보인다.
class OfferTermsWizard extends ConsumerStatefulWidget {
  const OfferTermsWizard({
    super.key,
    required this.pageLabel,
    this.initial,
    required this.storeName,
    required this.confirmTitle,
    required this.confirmDescription,
    required this.submitLabel,
    required this.onSubmit,
    this.failureMessage = defaultFailureMessage,
  });

  final String pageLabel;

  /// 처음 고를 값. 없으면 릴스, 식사권 + 조회수다.
  final OfferTermsInput? initial;
  final String storeName;
  final String confirmTitle;
  final String confirmDescription;
  final String submitLabel;
  final Future<void> Function(OfferTermsInput) onSubmit;
  final String failureMessage;

  static const nextLabel = '다음';
  static const defaultFailureMessage = '잠시 문제가 생겼어요. 다시 시도해 주세요.';
  static const totalSteps = 3;

  @override
  ConsumerState<OfferTermsWizard> createState() => _OfferTermsWizardState();
}

class _OfferTermsWizardState extends ConsumerState<OfferTermsWizard> {
  // 한 번만 만든다. 부모가 다시 그려져 `initial`이 바뀌어도 고르던 상태는 그대로다.
  late final _seed = OfferTermsWizardSeed(widget.initial);

  OfferTermsWizardViewModel get _vm =>
      ref.read(offerTermsWizardViewModelProvider(_seed).notifier);

  Future<void> _editVoucher(OfferTermsWizardState state) async {
    final edited = await showVoucherEditSheet(
      context,
      name: state.voucherName,
      value: state.voucherValue,
    );
    if (edited == null || !mounted) return;
    _vm.setVoucher(name: edited.name, value: edited.value);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = ref.watch(offerTermsWizardViewModelProvider(_seed));
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    final duration = CoraMotion.resolve(context, CoraMotion.fadeDuration);

    final Widget content = switch (state.step) {
      0 => FormatStep(selected: state.format, onPick: _vm.pickFormat),
      1 => RewardStep(
        rewardType: state.rewardType,
        voucherName: state.voucherName,
        voucherValue: state.voucherValue,
        perViewAllowed: state.perViewAllowed,
        onPick: _vm.pickReward,
        onEditVoucher: () => _editVoucher(state),
      ),
      _ => ConfirmStep(
        title: widget.confirmTitle,
        description: widget.confirmDescription,
        storeName: widget.storeName,
        input: state.toInput(),
      ),
    };

    return PopScope(
      // 시스템 뒤로 가기(스와이프)도 첫 단계가 아니면 앞 단계로 간다.
      canPop: state.step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _vm.back();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CoraStepHeader(
            pageLabel: widget.pageLabel,
            step: state.step + 1,
            total: OfferTermsWizard.totalSteps,
            onBack: _vm.back,
            // 첫 단계의 이전 버튼은 흐리고 아무 일도 하지 않는다(캔버스 NOffer).
            backDimmed: state.step == 0,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: AnimatedSwitcher(
                duration: duration,
                switchInCurve: CoraMotion.standardCurve,
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.topCenter,
                  children: [...previous, ?current],
                ),
                child: KeyedSubtree(
                  key: ValueKey<int>(state.step),
                  child: content,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.submitFailed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        widget.failureMessage,
                        textAlign: TextAlign.center,
                        style: CoraTextStyles.meta.copyWith(color: c.text),
                      ),
                    ),
                  ),
                if (state.isLastStep)
                  // 캔버스의 마지막 단계 버튼은 다크에서도 라임이다.
                  CoraPrimaryButton(
                    label: widget.submitLabel,
                    onPressed: state.submitting
                        ? null
                        : () => _vm.submit(widget.onSubmit),
                    look: CoraPrimaryButtonLook.accent,
                  )
                else
                  CoraPrimaryButton(
                    label: OfferTermsWizard.nextLabel,
                    onPressed: _vm.next,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
