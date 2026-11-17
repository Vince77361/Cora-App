import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/time/clock.dart';
import '../../../../core/time/kst.dart';
import '../../../../core/ui/cora_field_box.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../../../offer_terms/domain/offer_terms.dart';
import '../../../offer_terms/presentation/offer_terms_text.dart'
    show formatLabel, wonExact;
import '../../../offer_terms/presentation/pages/reward_budget_page.dart'
    show RewardEditor;
import '../../../offer_terms/presentation/viewmodels/proposal_draft_view_model.dart';
import '../../../offer_terms/presentation/widgets/choice_surface.dart';
import '../../../store_onboarding/presentation/widgets/option_sheet.dart';
import '../../domain/brand_usage_rights.dart';
import '../../domain/terms_version.dart';
import '../terms_text.dart';
import '../viewmodels/terms_proposal_view_model.dart';
import '../widgets/agreement_parts.dart';
import '../widgets/canvas_text.dart';

/// 조건 수정 제안(캔버스에 없는 화면): 최신 판본을 바탕으로 아홉 항목을 고쳐 새 판본으로 보낸다. 제품 제공·제작비·성과
/// 추가는 F1의 보상 편집 위젯([RewardEditor])을 브랜드 이름으로 끼워 쓰고, 그 아래에 최대 현금 부담을 보인다. 하나 이상
/// 바꿔야 `제안 보내기`가 켜진다. 모양은 12의 값과 F1·F2의 위젯을 빌렸다.
///
/// 12에서 열면 `extra`가 [AppRoutes.fromAgreement]라 보낸 뒤 12로 돌아가고, 대화방·06에서 열면 12를 그 자리에 연다.
class TermsProposalPage extends ConsumerStatefulWidget {
  const TermsProposalPage({
    super.key,
    required this.collaborationId,
    this.fromAgreement = false,
  });

  final String collaborationId;
  final bool fromAgreement;

  @override
  ConsumerState<TermsProposalPage> createState() => _TermsProposalPageState();
}

class _TermsProposalPageState extends ConsumerState<TermsProposalPage> {
  TermsProposalViewModel get _vm =>
      ref.read(termsProposalViewModelProvider(widget.collaborationId).notifier);

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.chats);
    }
  }

  /// 보낸 뒤나 상대가 먼저 냈을 때 12를 새로 읽어 연다.
  void _toAgreement() {
    if (widget.fromAgreement && context.canPop()) {
      context.pop();
    } else {
      context.pushReplacement(
        AppRoutes.collaborationAgreement(widget.collaborationId),
      );
    }
  }

  /// 알림은 화면 위쪽에 띄운다: 아래에는 12의 버튼 막대가 있어 겹친다.
  void _toast(String text) {
    final c = context.colors;
    final media = MediaQuery.of(context);
    final bottom = math.max(16.0, media.size.height - media.padding.top - 72);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(16, 0, 16, bottom),
          backgroundColor: c.text,
          duration: const Duration(seconds: 3),
          shape: const StadiumBorder(),
          content: Text(
            text,
            textAlign: TextAlign.center,
            style: canvasText(14, FontWeight.w400, c.background),
          ),
        ),
      );
  }

  Future<void> _send(OfferTerms draft) async {
    final outcome = await _vm.send(draft);
    if (!mounted) return;
    switch (outcome) {
      case TermsProposalSent(:final version):
        _toast(proposedToast(version));
        _toAgreement();
      case TermsProposalStale():
        // 수락이 아니라서 F8 화면이 아니라 이 안내를 보이고, 고치던 값은 버린 채 12를 새로 읽는다.
        _toast(AgreementTexts.staleProposal);
        _toAgreement();
      case TermsProposalFailed():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = termsProposalViewModelProvider(widget.collaborationId);
    final async = ref.watch(provider);
    final value = async.value;
    final Widget body;
    if (value != null) {
      body = _Form(
        key: ValueKey(value.base.version),
        collaborationId: widget.collaborationId,
        state: value,
        onSend: _send,
      );
    } else if (async.hasError) {
      body = CoraStateView.loadFailed(
        title: AgreementTexts.loadFailed,
        onRetry: () => ref.invalidate(provider),
      );
    } else {
      body = const CoraStateView.loading();
    }
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AgreementHeader(
              onBack: _leave,
              title: AgreementTexts.proposalTitle,
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class _Form extends ConsumerStatefulWidget {
  const _Form({
    super.key,
    required this.collaborationId,
    required this.state,
    required this.onSend,
  });

  final String collaborationId;
  final TermsProposalState state;
  final Future<void> Function(OfferTerms draft) onSend;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

/// 제작 시작으로 고를 수 있는 날 수(오늘부터).
const _startDays = 180;

class _FormState extends ConsumerState<_Form> {
  late final TextEditingController _title = TextEditingController(
    text: widget.state.base.title,
  );

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  TermsProposalViewModel get _vm =>
      ref.read(termsProposalViewModelProvider(widget.collaborationId).notifier);

  /// `제작 시작`: 오늘(한국 시간)부터 [_startDays]일 안에서 고른다. 앱에 한국어 달력 지역 설정이 없어서 달력 대신 다른 고르기
  /// 시트와 같은 목록 시트를 쓴다.
  Future<void> _pickStart(DateTime current) async {
    final today = toKst(ref.read(clockProvider).now());
    final first = DateTime(today.year, today.month, today.day);
    final picked = await showStoreOptionSheet<DateTime>(
      context,
      title: cellName(TermsField.startDate),
      options: [
        for (var i = 0; i < _startDays; i++)
          DateTime(first.year, first.month, first.day + i),
      ],
      labelOf: startDateOptionLabel,
      selected: current,
    );
    if (picked != null) _vm.setStartDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // 화면이 보는 값은 provider의 최신 값이다(widget.state는 처음 값이라 쓰지 않는다).
    final state =
        ref
            .watch(termsProposalViewModelProvider(widget.collaborationId))
            .value ??
        widget.state;
    final draftAsync = ref.watch(proposalDraftViewModelProvider(state.target));
    final draft = draftAsync.value;
    if (draft == null) {
      return draftAsync.hasError
          ? CoraStateView.loadFailed(
              title: AgreementTexts.loadFailed,
              onRetry: () =>
                  ref.invalidate(proposalDraftViewModelProvider(state.target)),
            )
          : const CoraStateView.loading();
    }
    final changed = state.changedWith(draft).toSet();
    final rewardChanged = [
      for (final f in [
        TermsField.product,
        TermsField.fee,
        TermsField.performance,
      ])
        if (changed.contains(f)) fieldName(f),
    ];
    final bottom = math.max(24.0, MediaQuery.viewPaddingOf(context).bottom);
    final formatDraft = ref.read(
      proposalDraftViewModelProvider(state.target).notifier,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 20,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                  child: Text(
                    proposalBasis(state.base.version),
                    style: canvasText(13, FontWeight.w400, c.textSecondary),
                  ),
                ),
                _Section(
                  label: fieldName(TermsField.title),
                  changed: changed.contains(TermsField.title),
                  child: CoraFieldBox(
                    label: AgreementTexts.titleHelp,
                    controller: _title,
                    maxLength: 40,
                    onChanged: _vm.setTitle,
                  ),
                ),
                _Section(
                  label: fieldName(TermsField.deliverable),
                  changed: changed.contains(TermsField.deliverable),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 8,
                    children: [
                      _Choices<ContentFormat>(
                        values: ContentFormat.values,
                        selected: draft.format,
                        label: formatLabel,
                        onPick: formatDraft.setFormat,
                      ),
                      _Choices<int>(
                        values: const [1, 2, 3],
                        selected: state.pieces,
                        label: (n) => '$n편',
                        onPick: _vm.setPieces,
                      ),
                    ],
                  ),
                ),
                // 제품 제공·제작비·성과 추가: F1의 보상 편집 위젯을 브랜드 이름(`혜택`, `현금 고정비`, `성과 추가`)으로 끼운다.
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 8,
                  children: [
                    if (rewardChanged.isNotEmpty)
                      _ChangedLine(text: rewardChanged.join(' · ')),
                    RewardEditor(
                      target: state.target,
                      // 성과 추가의 측정 기간은 지급 조건과 같다(따로 고르지 않는다).
                      countingDays: state.payoutDays,
                    ),
                    MaxCashRow(
                      value: wonExact(draft.reward.maxCashBurden),
                      bottomGap: 0,
                    ),
                  ],
                ),
                _Section(
                  label: cellName(TermsField.startDate),
                  changed: changed.contains(TermsField.startDate),
                  child: CoraPickBox(
                    label: AgreementTexts.startPick,
                    value: monthDayLabel(state.startDate),
                    placeholder: AgreementTexts.startPick,
                    onTap: () => _pickStart(state.startDate),
                  ),
                ),
                _Section(
                  label: fieldName(TermsField.revision),
                  changed: changed.contains(TermsField.revision),
                  child: _Choices<RevisionScope>(
                    values: RevisionScope.values,
                    selected: state.revisionScope,
                    label: revisionLabel,
                    onPick: _vm.setRevision,
                  ),
                ),
                _Section(
                  label: fieldName(TermsField.usage),
                  changed: changed.contains(TermsField.usage),
                  child: _Choices<BrandUsageRights>(
                    values: BrandUsageRights.values,
                    selected: state.usageRights,
                    label: usageLabel,
                    onPick: _vm.setUsage,
                  ),
                ),
                _Section(
                  label: fieldName(TermsField.payout),
                  changed: changed.contains(TermsField.payout),
                  child: _Choices<int>(
                    values: const [7, 14],
                    selected: state.payoutDays,
                    label: payoutTermLabel,
                    onPick: _vm.setPayoutDays,
                  ),
                ),
                // 광고 표시는 고정이라 고르지 않고 보이기만 한다.
                TermsCell(
                  name: AgreementTexts.adMark,
                  value: AgreementTexts.adMarkValue,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              if (state.error != null)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    state.error!,
                    textAlign: TextAlign.center,
                    style: canvasText(12, FontWeight.w400, c.text),
                  ),
                ),
              CoraPrimaryButton(
                label: AgreementTexts.send,
                look: CoraPrimaryButtonLook.accent,
                onPressed: !state.canSendWith(draft) || state.busy
                    ? null
                    : () => widget.onSend(draft),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 항목 이름과 그 아래 고르는 것. 이번에 바꾼 항목이면 이름 앞에 점이 붙는다.
class _Section extends StatelessWidget {
  const _Section({
    required this.label,
    required this.changed,
    required this.child,
  });

  final String label;
  final bool changed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            spacing: 6,
            children: [
              if (changed) _Dot(label: AgreementTexts.changedDot),
              Flexible(
                child: Semantics(
                  header: true,
                  child: Text(
                    label,
                    style: canvasText(14, FontWeight.w500, c.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
        child,
      ],
    );
  }
}

/// 보상 묶음에서 바뀐 항목 이름을 알리는 줄.
class _ChangedLine extends StatelessWidget {
  const _ChangedLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        spacing: 6,
        children: [
          _Dot(label: AgreementTexts.changedDot),
          Flexible(
            child: Text(
              text,
              style: canvasText(14, FontWeight.w500, c.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: ExcludeSemantics(
      child: SizedBox.square(
        dimension: 8,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.colors.progressRing,
          ),
        ),
      ),
    ),
  );
}

/// 값 몇 개 중 하나를 고르는 알약 줄. 형식과 편 수, 수정 범위, 활용 권한, 지급 조건이 쓴다. 고르는 면은 F1·형식
/// 카드의 선택 면([OfferChoiceSurface])이다.
class _Choices<T> extends StatelessWidget {
  const _Choices({
    required this.values,
    required this.selected,
    required this.label,
    required this.onPick,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) label;
  final ValueChanged<T> onPick;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in values)
          OfferChoiceSurface(
            selected: value == selected,
            onTap: () => onPick(value),
            minHeight: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            semanticLabel: label(value),
            builder: (context, foreground, _) => Text(
              label(value),
              style: canvasText(
                15,
                value == selected ? FontWeight.w700 : FontWeight.w500,
                foreground,
              ),
            ),
          ),
      ],
    );
  }
}
