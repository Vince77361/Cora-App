import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/cora_transitions.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../../../../core/ui/cora_step_header.dart';
import '../../../server_config/domain/server_config.dart';
import '../../../server_config/presentation/viewmodels/server_config_view_model.dart';
import '../../domain/offer_terms.dart';
import '../../domain/proposal_draft.dart';
import '../pages/review_send_page.dart';
import '../pages/reward_budget_page.dart';
import '../viewmodels/offer_terms_wizard_view_model.dart';
import '../viewmodels/proposal_draft_view_model.dart';
import 'confirm_step.dart';
import 'format_step.dart';
import 'reward_preset_step.dart';

/// 오퍼 보내기(A5)의 세 단계(형식 → 보상 → 확인). 고르는 조건은 [target]의 초안
/// ([proposalDraftViewModelProvider])이 들고 있어 `자세히 설정`(F1)과 `검토하고 보내기`(F2)가 같은 값을 본다.
///
/// 처음 값은 가게의 모집 조건이다. 형식 다음에 보상이 빠른 조합 셋 중 어느 것에도 맞지 않으면(F1에서 요소를
/// 따로 고른 모집 조건) 보상 단계를 건너뛰고 F1로 바로 간다. 마지막 단계의 버튼은 F2를 열고, F2의 마지막 버튼이
/// [onSend]를 부른다([onSend]가 던진 [ProposalSendFailure]의 문구는 F2가 보인다).
///
/// 머리글에는 화면 이름을 그리지 않는다(소유자가 2026-11-12에 뺐다). [pageLabel]은 화면 읽기
/// 프로그램용 이름이다.
class OfferTermsWizard extends ConsumerStatefulWidget {
  const OfferTermsWizard({
    super.key,
    required this.target,
    required this.pageLabel,
    required this.storeName,
    required this.onSend,
    this.recipientPhotoUrl,
    this.openDetailsFirst = false,
  });

  final NewOfferTarget target;
  final String pageLabel;
  final String storeName;
  final Future<void> Function(OfferTerms) onSend;

  /// F2의 받는 사람 사진.
  final String? recipientPhotoUrl;

  /// 처음 그린 뒤 바로 `자세히 설정`(F1)을 연다. 지난 조건이 채워진 오퍼(G1 `다시 만나기`)가 쓴다.
  final bool openDetailsFirst;

  static const nextLabel = '다음';
  static const reviewLabel = '검토하고 보내기';
  static const confirmTitle = '이 오퍼를\n보낼까요?';
  static const confirmDescription = '상대가 수락하면 그때 결제해요.';
  static const loadFailed = '조건을 불러오지 못했어요.';
  static const totalSteps = 3;

  @override
  ConsumerState<OfferTermsWizard> createState() => _OfferTermsWizardState();
}

class _OfferTermsWizardState extends ConsumerState<OfferTermsWizard> {
  @override
  void initState() {
    super.initState();
    if (widget.openDetailsFirst) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openDetails();
      });
    }
  }

  OfferTermsWizardViewModel get _vm =>
      ref.read(offerTermsWizardViewModelProvider(widget.target).notifier);

  ProposalDraftViewModel get _draft =>
      ref.read(proposalDraftViewModelProvider(widget.target).notifier);

  void _push(Widget page) {
    Navigator.of(
      context,
      rootNavigator: true,
    ).push(CoraTransitions.push(page).createRoute(context));
  }

  void _openDetails() => _push(
    RewardBudgetPage(
      target: widget.target,
      onSend: widget.onSend,
      recipientPhotoUrl: widget.recipientPhotoUrl,
    ),
  );

  void _openReview() => _push(
    ReviewSendPage(
      target: widget.target,
      onSend: widget.onSend,
      recipientPhotoUrl: widget.recipientPhotoUrl,
    ),
  );

  /// 형식 다음. 빠른 조합에 맞지 않는 보상이면 보상 단계 대신 F1로 간다.
  void _afterFormat(OfferTerms terms) {
    final reward = terms.reward;
    if (!reward.isEmpty && presetOf(reward) == null) {
      _openDetails();
    } else {
      _vm.next();
    }
  }

  void _pickPreset(RewardPreset preset) {
    _vm.setCashChosen(preset == RewardPreset.fixedCash);
    _draft.pickPreset(preset);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(offerTermsWizardViewModelProvider(widget.target));
    final config = ref.watch(serverConfigViewModelProvider);
    final draft = ref.watch(proposalDraftViewModelProvider(widget.target));
    final header = CoraStepHeader(
      pageLabel: widget.pageLabel,
      step: state.step + 1,
      total: OfferTermsWizard.totalSteps,
      onBack: _vm.back,
      // 첫 단계의 이전 버튼은 흐리고 아무 일도 하지 않는다(캔버스 NOffer).
      backDimmed: state.step == 0,
    );
    final terms = draft.value;
    final limits = config.value;
    if (terms == null || limits == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          Expanded(
            child: config.hasError || draft.hasError
                ? CoraStateView.loadFailed(
                    title: OfferTermsWizard.loadFailed,
                    onRetry: () {
                      ref.invalidate(serverConfigViewModelProvider);
                      ref.invalidate(
                        proposalDraftViewModelProvider(widget.target),
                      );
                    },
                  )
                : const CoraStateView.loading(),
          ),
        ],
      );
    }
    return _steps(context, state, terms, limits, header);
  }

  Widget _steps(
    BuildContext context,
    OfferTermsWizardState state,
    OfferTerms terms,
    ServerConfig config,
    Widget header,
  ) {
    final reward = terms.reward;
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    final duration = CoraMotion.resolve(context, CoraMotion.fadeDuration);
    // 고정 현금을 눌렀는데 금액이 아직 없으면 보상은 비어 있어도 그 조합이 골라진 것으로 본다.
    final selected =
        presetOf(reward) ??
        (state.cashChosen && reward.isEmpty ? RewardPreset.fixedCash : null);

    final Widget content = switch (state.step) {
      0 => FormatStep(selected: terms.format, onPick: _draft.setFormat),
      1 => RewardPresetStep(
        selected: selected,
        reward: reward,
        base: _draft.presetBase,
        viewPayAllowed: terms.viewPayAllowed,
        cashMax: config.reward.fixedCash.storeMax,
        cashStep: config.reward.fixedCash.step,
        onPick: _pickPreset,
        onCashChanged: _draft.setFixedCash,
        onDetails: _openDetails,
      ),
      _ => ConfirmStep(
        title: OfferTermsWizard.confirmTitle,
        description: OfferTermsWizard.confirmDescription,
        storeName: widget.storeName,
        terms: terms,
      ),
    };

    // 보상이 비어 있으면(고정 현금 금액 없음, 블로그로 바꿔 조회수 수당만 남았던 경우) 다음으로 갈 수 없다.
    final canNext = state.step != 1 || !reward.isEmpty;

    return PopScope(
      // 시스템 뒤로 가기(스와이프)도 첫 단계가 아니면 앞 단계로 간다.
      canPop: state.step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _vm.back();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
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
            // 캔버스(NOffer, DarkNOffer)의 `다음`과 `검토하고 보내기`는 다크에서도 라임이다.
            child: CoraPrimaryButton(
              label: state.isLastStep
                  ? OfferTermsWizard.reviewLabel
                  : OfferTermsWizard.nextLabel,
              onPressed: state.isLastStep
                  ? _openReview
                  : canNext
                  ? () => state.step == 0 ? _afterFormat(terms) : _vm.next()
                  : null,
              look: CoraPrimaryButtonLook.accent,
            ),
          ),
        ],
      ),
    );
  }
}
