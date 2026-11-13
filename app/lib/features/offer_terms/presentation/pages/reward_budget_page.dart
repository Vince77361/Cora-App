import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/cora_transitions.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shadows.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../../../../core/ui/cora_step_header.dart';
import '../../../server_config/domain/server_config.dart';
import '../../../server_config/presentation/viewmodels/server_config_view_model.dart';
import '../../domain/offer_terms.dart';
import '../../domain/proposal_draft.dart';
import '../offer_terms_text.dart';
import '../viewmodels/proposal_draft_view_model.dart';
import '../widgets/benefit_edit_sheet.dart';
import '../widgets/fixed_cash_sheet.dart';
import '../widgets/view_pay_sheet.dart';
import 'review_send_page.dart';

/// F1 보상·예산 설정(NBudget / DarkNBudget). 제공 혜택, 고정 현금, 조회수 수당을 따로 정하고 아래에
/// 최대 현금 부담을 바로 보여 준다. `검토하고 보내기`를 누르면 F2([ReviewSendPage])가 열린다.
///
/// 고르는 값은 [target]의 [proposalDraftViewModelProvider]가 들고 있어 F2에서 `고치기`로 돌아와도 그대로다.
/// [onSend]는 F2의 마지막 버튼이 부른다.
class RewardBudgetPage extends ConsumerWidget {
  const RewardBudgetPage({
    super.key,
    required this.target,
    required this.onSend,
  });

  final ProposalTarget target;
  final Future<void> Function(OfferTerms terms) onSend;

  static const pageLabel = '제안 만들기';
  static const step = 2;
  static const totalSteps = 3;
  static const title = '보상을 정해요.';
  static const description = '식사권과 현금은 따로 계산해요.';
  static const benefitLabel = '제공 혜택';
  static const benefitHint = '현금과 더하지 않아요';
  static const benefitNone = '없음';
  static const fixedCashLabel = '고정 현금 (선택)';
  static const customLabel = '직접 입력';
  static const viewPayLabel = '조회수 수당';
  static const viewPayHint = '조회수만큼 더 드려요 · 기본으로 켜져 있어요';
  static const rateRowLabel = '단가';
  static const capRowLabel = '1인 상한';
  static const periodRowLabel = '측정 기간';
  static String periodValue(int days) => '게시 후 $days일';
  static const blogNote = '블로그 글은 조회수를 셀 수 없어요.';
  static const burdenLabel = '최대 현금 부담 · 남으면 환불';
  static const reviewLabel = '검토하고 보내기';
  static const emptyNote = '보상을 하나 이상 정해 주세요.';
  static const loadFailed = '보상 설정을 불러오지 못했어요.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(serverConfigViewModelProvider);
    final draft = ref.watch(proposalDraftViewModelProvider(target));
    final Widget body;
    if (config.value != null && draft.value != null) {
      body = _Body(
        target: target,
        config: config.value!,
        terms: draft.value!,
        onSend: onSend,
      );
    } else if (config.hasError || draft.hasError) {
      body = CoraStateView.loadFailed(
        title: loadFailed,
        onRetry: () {
          ref.invalidate(serverConfigViewModelProvider);
          ref.invalidate(proposalDraftViewModelProvider(target));
        },
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
            CoraStepHeader(
              pageLabel: pageLabel,
              step: step,
              total: totalSteps,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.target,
    required this.config,
    required this.terms,
    required this.onSend,
  });

  final ProposalTarget target;
  final ServerConfig config;
  final OfferTerms terms;
  final Future<void> Function(OfferTerms) onSend;

  ProposalDraftViewModel _vm(WidgetRef ref) =>
      ref.read(proposalDraftViewModelProvider(target).notifier);

  Future<void> _editBenefit(BuildContext context, WidgetRef ref) async {
    final edit = await showBenefitEditSheet(
      context,
      initial: terms.reward.voucher,
      defaults: config.reward.voucher,
    );
    if (edit == null) return;
    _vm(ref).setVoucher(edit.voucher);
  }

  Future<void> _customCash(BuildContext context, WidgetRef ref) async {
    final limits = config.reward.fixedCash;
    final amount = await showFixedCashSheet(
      context,
      initial: terms.reward.fixedCash,
      max: limits.storeMax,
      step: limits.step,
    );
    if (amount == null) return;
    _vm(ref).setFixedCash(amount);
  }

  Future<void> _pickRate(BuildContext context, WidgetRef ref) async {
    final current = terms.reward.viewPay;
    if (current == null) return;
    final picked = await showRateSheet(
      context,
      range: config.reward.viewRate,
      selected: current.ratePerThousand,
    );
    if (picked != null) _vm(ref).setRate(picked);
  }

  Future<void> _pickCap(BuildContext context, WidgetRef ref) async {
    final current = terms.reward.viewPay;
    if (current == null) return;
    final picked = await showCapSheet(
      context,
      range: config.reward.perViewCap,
      selected: current.cap,
    );
    if (picked != null) _vm(ref).setCap(picked);
  }

  void _review(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      CoraTransitions.push(
        ReviewSendPage(target: target, onSend: onSend),
      ).createRoute(context),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final reward = terms.reward;
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    final presets = config.reward.fixedCash.presets;
    final customCash =
        reward.fixedCash != 0 && !presets.contains(reward.fixedCash);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          RewardBudgetPage.title,
                          style: CoraTextStyles.title.copyWith(color: c.text),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        RewardBudgetPage.description,
                        style: CoraTextStyles.bodySmall.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 8,
                    children: [
                      _BenefitCard(
                        voucher: reward.voucher,
                        onTap: () => _editBenefit(context, ref),
                      ),
                      _FixedCashCard(
                        selected: reward.fixedCash,
                        presets: presets,
                        custom: customCash,
                        onPick: _vm(ref).setFixedCash,
                        onCustom: () => _customCash(context, ref),
                      ),
                      _ViewPayCard(
                        viewPay: reward.viewPay,
                        allowed: terms.viewPayAllowed,
                        countingDays: config.reward.countingDays,
                        onToggle: _vm(ref).setViewPayEnabled,
                        onRate: () => _pickRate(context, ref),
                        onCap: () => _pickCap(context, ref),
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
              if (reward.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      RewardBudgetPage.emptyNote,
                      style: CoraTextStyles.meta.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                ),
              _BurdenBox(amount: reward.maxCashBurden),
              const SizedBox(height: 12),
              CoraPrimaryButton(
                label: RewardBudgetPage.reviewLabel,
                onPressed: reward.isEmpty ? null : () => _review(context),
                look: CoraPrimaryButtonLook.accent,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 카드 하나: 모서리 20, `surface` 바탕, 안쪽 세로 14 가로 16.
class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(CoraRadius.field),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: child,
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({required this.voucher, required this.onTap});

  final Voucher? voucher;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final value = voucher == null
        ? RewardBudgetPage.benefitNone
        : benefitLine(voucher!);
    return Semantics(
      container: true,
      button: true,
      label: '${RewardBudgetPage.benefitLabel}, $value',
      onTap: onTap,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onTap,
          child: _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      RewardBudgetPage.benefitLabel,
                      style: CoraTextStyles.meta.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        RewardBudgetPage.benefitHint,
                        style: CoraTextStyles.fieldLabel.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: CoraTextStyles.bodyLarge.copyWith(
                    fontSize: 17,
                    color: c.text,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FixedCashCard extends StatelessWidget {
  const _FixedCashCard({
    required this.selected,
    required this.presets,
    required this.custom,
    required this.onPick,
    required this.onCustom,
  });

  final int selected;
  final List<int> presets;

  /// 알약에 없는 금액이 골라져 있다(직접 입력한 값).
  final bool custom;
  final ValueChanged<int> onPick;
  final VoidCallback onCustom;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            RewardBudgetPage.fixedCashLabel,
            style: CoraTextStyles.meta.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            spacing: 6,
            children: [
              for (final amount in presets)
                Expanded(
                  child: _Pill(
                    label: fixedCashChip(amount),
                    selected: amount == selected,
                    onTap: () => onPick(amount),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: _Pill(
              label: custom
                  ? '${RewardBudgetPage.customLabel} · ${won(selected)}'
                  : RewardBudgetPage.customLabel,
              selected: custom,
              onTap: onCustom,
              padded: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// 알약: 높이 40, 13/500. 고른 것은 `quietSelected` 바탕(라이트 흰색, 다크 #2A2D33), 나머지는 투명.
class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.padded = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// 알약이 글자 너비만큼만 차지한다(좌우 14).
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: selected ? c.quietSelected : Colors.transparent,
                borderRadius: BorderRadius.circular(CoraRadius.pill),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: padded ? 14 : 0),
                child: Center(
                  widthFactor: padded ? 1 : null,
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CoraTextStyles.label.copyWith(color: c.text),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ViewPayCard extends StatelessWidget {
  const _ViewPayCard({
    required this.viewPay,
    required this.allowed,
    required this.countingDays,
    required this.onToggle,
    required this.onRate,
    required this.onCap,
  });

  final ViewPay? viewPay;

  /// 블로그 글이면 false다. 스위치가 꺼져 있고 눌리지 않는다.
  final bool allowed;
  final int countingDays;
  final ValueChanged<bool> onToggle;
  final VoidCallback onRate;
  final VoidCallback onCap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final on = viewPay != null;
    final VoidCallback? toggle = allowed ? () => onToggle(!on) : null;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            container: true,
            toggled: on,
            enabled: allowed,
            label:
                '${RewardBudgetPage.viewPayLabel}, ${RewardBudgetPage.viewPayHint}',
            onTap: toggle,
            child: ExcludeSemantics(
              child: CoraPressable(
                onTap: toggle,
                child: Opacity(
                  opacity: allowed ? 1 : 0.4,
                  child: Row(
                    spacing: 12,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              RewardBudgetPage.viewPayLabel,
                              style: CoraTextStyles.listLabel.copyWith(
                                color: c.text,
                              ),
                            ),
                            Text(
                              RewardBudgetPage.viewPayHint,
                              style: CoraTextStyles.fieldLabel.copyWith(
                                color: c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _SwitchGraphic(on: on),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!allowed)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                RewardBudgetPage.blogNote,
                style: CoraTextStyles.fieldLabel.copyWith(
                  color: c.textSecondary,
                ),
              ),
            ),
          if (viewPay != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                children: [
                  _DetailRow(
                    label: RewardBudgetPage.rateRowLabel,
                    value: rateLabel(viewPay!.ratePerThousand),
                    onTap: onRate,
                  ),
                  _DetailRow(
                    label: RewardBudgetPage.capRowLabel,
                    value: capLabel(viewPay!.cap),
                    onTap: onCap,
                  ),
                  _DetailRow(
                    label: RewardBudgetPage.periodRowLabel,
                    value: RewardBudgetPage.periodValue(countingDays),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 스위치 그림 48 x 28(둥근 14). 켜짐은 `accent`, 꺼짐은 `switchTrackOff`. 손잡이 22는 위 3, 왼쪽
/// 켜짐 23 / 꺼짐 3이다. 손잡이 색은 캔버스가 라이트 #FFFFFF, 다크 #0F1012(= 화면 바탕)다.
class _SwitchGraphic extends StatelessWidget {
  const _SwitchGraphic({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final duration = CoraMotion.resolve(context, CoraMotion.stateDuration);
    return AnimatedContainer(
      duration: duration,
      curve: CoraMotion.standardCurve,
      width: 48,
      height: 28,
      decoration: BoxDecoration(
        color: on ? c.accent : c.switchTrackOff,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: duration,
            curve: CoraMotion.standardCurve,
            top: 3,
            left: on ? 23 : 3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.background,
                shape: BoxShape.circle,
                boxShadow: CoraShadows.switchKnob,
              ),
              child: const SizedBox.square(dimension: 22),
            ),
          ),
        ],
      ),
    );
  }
}

/// 조회수 수당 상세 한 줄: 위아래 8, 왼쪽 13 보조색, 오른쪽 14/500. [onTap]이 있으면 눌러서 고른다.
class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: CoraTextStyles.meta.copyWith(color: c.textSecondary),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: CoraTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
                color: c.text,
              ),
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return row;
    return Semantics(
      container: true,
      button: true,
      label: '$label, $value',
      onTap: onTap,
      child: ExcludeSemantics(
        child: CoraPressable(onTap: onTap, child: row),
      ),
    );
  }
}

/// 아래 고정: `최대 현금 부담 · 남으면 환불`과 금액(22/900). 모서리 20, `surface` 바탕, 안쪽 14/18.
class _BurdenBox extends StatelessWidget {
  const _BurdenBox({required this.amount});

  final int amount;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return MergeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(CoraRadius.field),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            spacing: 12,
            children: [
              Flexible(
                child: Text(
                  RewardBudgetPage.burdenLabel,
                  style: CoraTextStyles.meta.copyWith(color: c.textSecondary),
                ),
              ),
              Text(
                wonExact(amount),
                style: CoraTextStyles.title.copyWith(
                  fontSize: 22,
                  letterSpacing: -0.88,
                  height: 1.448,
                  color: c.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
