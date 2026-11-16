import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/time/clock.dart';
import '../../../../core/time/kst.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_field_box.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../../../../core/ui/cora_secondary_button.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../../../../core/ui/cora_step_header.dart';
import '../../../offer_terms/domain/offer_terms.dart' show ContentFormat;
import '../../../offer_terms/presentation/offer_terms_text.dart'
    show formatLabel;
import '../../../principles/domain/principles.dart' show ProductTrialDays;
import '../../../store_onboarding/presentation/widgets/option_sheet.dart';
import '../../domain/campaign.dart';
import '../brand_onboarding_text.dart';
import '../viewmodels/campaign_form_view_model.dart';
import '../widgets/brand_form_widgets.dart';
import '../widgets/close_campaign_sheet.dart';

/// 캠페인 만들기와 고치기(같은 화면). 이 화면은 기획 캔버스에 없다(설계 "브랜드 시작과 캠페인 만들기"). 모양은
/// 브랜드 프로필 만들기와 같다. 만들기는 `캠페인 시작하기`, 고치기는 `저장`과 `캠페인 마감`이 아래에 있다.
///
/// 캠페인 한 줄, 제작비, 캠페인 예산, 형식, 시작 가능한 날이 있어야 저장 단추가 켜진다. 서버가 입력을
/// 거절하면 그 문구를 그대로 보여 준다.
class CampaignFormPage extends ConsumerStatefulWidget {
  const CampaignFormPage({super.key, this.editing = false});

  /// 진행 중인 캠페인을 고치는 중인지(아니면 새로 만든다).
  final bool editing;

  @visibleForTesting
  static const headlineFieldKey = ValueKey<String>('campaignForm.headline');
  @visibleForTesting
  static const feeFieldKey = ValueKey<String>('campaignForm.fee');
  @visibleForTesting
  static const budgetFieldKey = ValueKey<String>('campaignForm.budget');
  @visibleForTesting
  static const startFromListKey = ValueKey<String>(
    'campaignForm.startFromList',
  );
  @visibleForTesting
  static ValueKey<String> mustIncludeFieldKey(int index) =>
      ValueKey<String>('campaignForm.mustInclude.$index');

  @override
  ConsumerState<CampaignFormPage> createState() => _CampaignFormPageState();
}

class _CampaignFormPageState extends ConsumerState<CampaignFormPage> {
  final _headline = TextEditingController();
  final _fee = TextEditingController();
  final _budget = TextEditingController();
  final _mustInclude = [
    for (var i = 0; i < CampaignRules.mustIncludeMax; i++)
      TextEditingController(),
  ];

  // 고치기는 불러온 값을 입력 칸에 한 번만 채운다.
  bool _seeded = false;

  @override
  void dispose() {
    _headline.dispose();
    _fee.dispose();
    _budget.dispose();
    for (final c in _mustInclude) {
      c.dispose();
    }
    super.dispose();
  }

  void _seed(CampaignFormState s) {
    if (_seeded) return;
    _seeded = true;
    _headline.text = s.headline;
    _fee.text = s.feeText;
    _budget.text = s.budgetText;
    for (var i = 0; i < _mustInclude.length; i++) {
      _mustInclude[i].text = s.mustInclude[i];
    }
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else if (widget.editing) {
      context.go(AppRoutes.brand);
    } else {
      context.go(AppRoutes.role);
    }
  }

  Future<void> _chooseStartFrom(CampaignFormState s) async {
    // 시각은 주입받은 Clock에서 한국 시간으로 읽는다(`today`는 만들 때 채워져 있어 보통 그 값을 쓴다).
    final today = s.today ?? _kstToday(ref.read(clockProvider).now());
    final days = [
      for (var i = 0; i < 60; i++)
        DateTime(today.year, today.month, today.day + i),
    ];
    final picked = await showStoreOptionSheet<DateTime>(
      context,
      title: BrandOnboardingTexts.startFromSheetTitle,
      options: days,
      labelOf: _dayLabel,
      selected: s.startFrom,
      listKey: CampaignFormPage.startFromListKey,
    );
    if (picked == null || !mounted) return;
    ref
        .read(campaignFormViewModelProvider(widget.editing).notifier)
        .setStartFrom(picked);
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final saved = await ref
        .read(campaignFormViewModelProvider(widget.editing).notifier)
        .submit();
    // 만들기가 끝나면 발견(01)이 열린다. 고치기는 온 곳으로 돌아간다.
    if (!saved || !mounted) return;
    if (widget.editing && context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.brand);
    }
  }

  Future<void> _close() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final confirmed = await showCloseCampaignSheet(context);
    if (confirmed != true || !mounted) return;
    final closed = await ref
        .read(campaignFormViewModelProvider(widget.editing).notifier)
        .close();
    // 마감하면 진행 중인 캠페인이 없으므로 진입 규칙이 캠페인 만들기로, 진행 중인 브랜드 협업이 있으면
    // 협업 탭으로 보낸다.
    if (closed && mounted) context.go(AppRoutes.brand);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final provider = campaignFormViewModelProvider(widget.editing);
    final async = ref.watch(provider);
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);

    final header = SizedBox(
      height: CoraStepHeader.rowHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: CoraBackButton(onPressed: _back),
        ),
      ),
    );

    final state = async.value;
    if (state == null) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              async.hasError
                  ? CoraStateView.loadFailed(
                      title: '캠페인을 불러오지 못했어요',
                      onRetry: () => ref.invalidate(provider),
                    )
                  : const CoraStateView.loading(),
            ],
          ),
        ),
      );
    }
    _seed(state);
    final vm = ref.read(provider.notifier);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            header,
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.only(top: 24, bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        BrandOnboardingTexts.campaignTitle,
                        style: CoraTextStyles.headline.copyWith(color: c.text),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 10,
                        children: [
                          CoraFieldBox(
                            fieldKey: CampaignFormPage.headlineFieldKey,
                            label: BrandOnboardingTexts.headline,
                            hint: BrandOnboardingTexts.headlineHint,
                            controller: _headline,
                            onChanged: vm.setHeadline,
                            maxLength: CampaignRules.headlineMax,
                            textInputAction: TextInputAction.next,
                          ),
                          CoraFieldBox(
                            fieldKey: CampaignFormPage.feeFieldKey,
                            label: BrandOnboardingTexts.fee,
                            controller: _fee,
                            onChanged: vm.setFee,
                            maxLength: 9,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            textInputAction: TextInputAction.next,
                          ),
                          if (state.feeError != null)
                            BrandFieldNote(state.feeError!),
                          CoraFieldBox(
                            fieldKey: CampaignFormPage.budgetFieldKey,
                            label: BrandOnboardingTexts.budget,
                            controller: _budget,
                            onChanged: vm.setBudget,
                            maxLength: 10,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            textInputAction: TextInputAction.next,
                          ),
                          if (state.budgetError != null)
                            BrandFieldNote(state.budgetError!),
                          BrandSwitchTile(
                            label: BrandOnboardingTexts.productProvided,
                            on: state.productProvided,
                            onChanged: vm.setProductProvided,
                          ),
                          const SizedBox(height: 6),
                          BrandChipGroup<ContentFormat>(
                            label: BrandOnboardingTexts.format,
                            options: ContentFormat.values,
                            labelOf: formatLabel,
                            isSelected: (f) => f == state.format,
                            onTap: vm.setFormat,
                          ),
                          const SizedBox(height: 6),
                          BrandFormTile(
                            label: BrandOnboardingTexts.startFrom,
                            value: state.startFrom == null
                                ? null
                                : _dayLabel(state.startFrom!),
                            placeholder:
                                BrandOnboardingTexts.startFromPlaceholder,
                            onTap: () => _chooseStartFrom(state),
                          ),
                          if (state.startFromError != null)
                            BrandFieldNote(state.startFromError!),
                          const SizedBox(height: 6),
                          BrandChipGroup<ProductTrialDays>(
                            label: BrandOnboardingTexts.trialDays,
                            options: ProductTrialDays.values,
                            labelOf: BrandOnboardingTexts.trialLabel,
                            isSelected: (d) => d == state.trialDays,
                            onTap: vm.setTrialDays,
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              BrandOnboardingTexts.mustInclude,
                              style: CoraTextStyles.label.copyWith(
                                color: c.textSecondary,
                              ),
                            ),
                          ),
                          for (var i = 0; i < _mustInclude.length; i++)
                            CoraFieldBox(
                              fieldKey: CampaignFormPage.mustIncludeFieldKey(i),
                              label: '${i + 1}줄',
                              controller: _mustInclude[i],
                              onChanged: (v) => vm.setMustInclude(i, v),
                              maxLength: CampaignRules.mustIncludeLength,
                              textInputAction: i == _mustInclude.length - 1
                                  ? TextInputAction.done
                                  : TextInputAction.next,
                            ),
                          const SizedBox(height: 6),
                          BrandChipGroup<NotRequired>(
                            label: BrandOnboardingTexts.notRequired,
                            options: NotRequired.values,
                            labelOf: (n) => n.label,
                            isSelected: state.notRequired.contains,
                            onTap: vm.toggleNotRequired,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          state.error!,
                          textAlign: TextAlign.center,
                          style: CoraTextStyles.meta.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  CoraPrimaryButton(
                    label: widget.editing
                        ? BrandOnboardingTexts.save
                        : BrandOnboardingTexts.start,
                    look: CoraPrimaryButtonLook.accent,
                    onPressed: state.canSubmit ? _submit : null,
                  ),
                  if (widget.editing) ...[
                    const SizedBox(height: 8),
                    CoraSecondaryButton(
                      label: BrandOnboardingTexts.close,
                      tone: CoraSecondaryTone.muted,
                      onPressed: state.saving ? null : _close,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

/// 한국 시간 기준 오늘 0시.
DateTime _kstToday(DateTime now) {
  final kst = toKst(now);
  return DateTime(kst.year, kst.month, kst.day);
}

/// `11월 20일 (금)`.
String _dayLabel(DateTime day) =>
    '${day.month}월 ${day.day}일 (${_weekdays[day.weekday - 1]})';
