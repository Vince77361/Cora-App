import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/navigation/cora_transitions.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_network_photo.dart';
import '../../../../core/ui/cora_page_header.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../../../offer_terms/domain/offer_terms.dart';
import '../../../offer_terms/domain/proposal_draft.dart';
import '../../../offer_terms/presentation/pages/reward_budget_page.dart';
import '../../../offer_terms/presentation/pages/review_send_page.dart';
import '../../../offer_terms/presentation/viewmodels/proposal_draft_view_model.dart';
import '../../../store_browse/domain/store_detail.dart';
import '../../../store_browse/presentation/viewmodels/store_detail_view_model.dart';
import '../../domain/creator_series.dart';
import '../counter_proposal_text.dart';
import '../viewmodels/counter_proposal_view_model.dart';
import '../widgets/hope_reward_sheet.dart';
import '../widgets/principles_sheet.dart';
import '../widgets/series_add_sheet.dart';

/// F6 크리에이터 역제안(NCounter / DarkNCounter). 가게의 모집 조건을 내 방식으로 바꿔 제안한다. 시리즈(또는
/// 형식), 아이디어, 희망 보상, 표현 원칙을 정하고 `검토하고 보내기`로 F2를 연다. 가게와 열린 오퍼가 있고
/// 내 차례이면 그 오퍼의 다음 판본을 낸다.
///
/// [pitch]는 D2에서 쓴 한 줄이고 아이디어의 처음 값이 된다.
class CounterProposalPage extends ConsumerWidget {
  const CounterProposalPage({
    super.key,
    required this.storeId,
    this.pitch = '',
  });

  final String storeId;
  final String pitch;

  static const title = '내 방식으로 제안';
  static const loadFailed = '제안 화면을 불러오지 못했어요.';

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.creatorStore(storeId));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = storeDetailViewModelProvider(storeId);
    final async = ref.watch(provider);
    final Widget body = switch (async) {
      AsyncData(:final value) => _Loaded(
        storeId: storeId,
        detail: value.detail,
        pitch: pitch,
      ),
      AsyncError() => CoraStateView.loadFailed(
        title: loadFailed,
        onRetry: () => ref.invalidate(provider),
      ),
      _ => const CoraStateView.loading(),
    };
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CoraPageHeader(
              title: title,
              onBack: () => _back(context),
              extent: 64,
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class _Loaded extends ConsumerWidget {
  const _Loaded({
    required this.storeId,
    required this.detail,
    required this.pitch,
  });

  final String storeId;
  final StoreDetail detail;
  final String pitch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = detail.myOpenOffer;
    final target = CounterTarget(
      storeId: open == null ? storeId : null,
      offerId: open?.offerId,
      storeName: detail.summary.name,
      nextVersion: open == null ? 2 : open.latestVersion + 1,
      start: detail.summary.defaultTerms,
    );
    final args = CounterProposalArgs(target: target, pitch: pitch);
    final waiting = open != null && !open.myTurn;
    final async = ref.watch(counterProposalViewModelProvider(args));
    final draft = ref.watch(proposalDraftViewModelProvider(target));
    if (async.hasError || draft.hasError) {
      return CoraStateView.loadFailed(
        title: CounterProposalPage.loadFailed,
        onRetry: () {
          ref.invalidate(counterProposalViewModelProvider(args));
          ref.invalidate(proposalDraftViewModelProvider(target));
        },
      );
    }
    final state = async.value;
    final terms = draft.value;
    if (state == null || terms == null) return const CoraStateView.loading();
    return _Body(
      storeId: storeId,
      detail: detail,
      target: target,
      args: args,
      state: state,
      terms: terms,
      waiting: waiting,
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({
    required this.storeId,
    required this.detail,
    required this.target,
    required this.args,
    required this.state,
    required this.terms,
    required this.waiting,
  });

  final String storeId;
  final StoreDetail detail;
  final CounterTarget target;
  final CounterProposalArgs args;
  final CounterProposalState state;
  final OfferTerms terms;
  final bool waiting;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  late final _idea = TextEditingController(text: widget.state.idea);

  static const sent = '제안을 보냈어요.';
  static const waitingNote = '사장님의 답을 기다리고 있어요.';

  @override
  void dispose() {
    _idea.dispose();
    super.dispose();
  }

  CounterProposalViewModel get _vm =>
      ref.read(counterProposalViewModelProvider(widget.args).notifier);

  /// F2의 마지막 버튼이 부른다. 보내면 가게 상세로 돌아가(F2와 이 화면이 함께 닫힌다) 안내를 보인다.
  Future<void> _send(OfferTerms terms) async {
    await _vm.send(terms);
    if (!mounted) return;
    ref.read(storeDetailNoticeProvider.notifier).show(sent);
    // 가게 상세는 같은 주소라 그대로 남는다. 방금 만든 열린 제안(`myOpenOffer`)이 보이게 다시 읽는다.
    ref.invalidate(storeDetailViewModelProvider(widget.storeId));
    context.go(AppRoutes.creatorStore(widget.storeId));
  }

  void _review() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context, rootNavigator: true).push(
      CoraTransitions.push(
        ReviewSendPage(
          target: widget.target,
          onSend: _send,
          recipientPhotoUrl: widget.detail.summary.coverPhotoUrl,
          failureMessage: counterProposalSendFailed,
        ),
      ).createRoute(context),
    );
  }

  Future<void> _editPrinciples() async {
    final picked = await showPrinciplesSheet(
      context,
      initial: widget.state.principles,
    );
    if (picked != null) _vm.setPrinciples(picked);
  }

  Future<void> _addSeries() => showSeriesAddSheet(
    context,
    initialFormat: widget.terms.format,
    onAdd: (name, format, note) =>
        _vm.addSeries(name: name, format: format, note: note),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final store = widget.detail.summary;
    final terms = widget.terms;
    final state = widget.state;
    final reward = terms.reward;
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    final canSend = !widget.waiting && !reward.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: _StoreCard(
                    name: store.name,
                    photoUrl: store.coverPhotoUrl,
                    subtitle: storeCardSubtitle(
                      neighborhood: store.neighborhood,
                      bestShootingTime: widget.detail.bestShootingTime,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _ConditionBox(
                    text: storeConditionLine(
                      store.defaultTerms,
                      reward.maxCashBurden,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
                  child: Semantics(
                    header: true,
                    child: Text(
                      '내 시리즈로 만들기',
                      style: CoraTextStyles.label.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                ),
                _SeriesRow(
                  series: state.series,
                  selectedId: state.seriesId,
                  onPick: _vm.selectSeries,
                  onAdd: state.series.length >= CreatorSeries.maxCount
                      ? null
                      : _addSeries,
                ),
                if (state.series.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: FormatPicker(
                      selected: terms.format,
                      onPick: ref
                          .read(
                            proposalDraftViewModelProvider(
                              widget.target,
                            ).notifier,
                          )
                          .setFormat,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _IdeaBox(controller: _idea, onChanged: _vm.setIdea),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 8,
                      children: [
                        Expanded(
                          child: _ValueTile(
                            label: '희망 보상',
                            value: hopeRewardSummary(reward),
                            onTap: () =>
                                showHopeRewardSheet(context, widget.target),
                          ),
                        ),
                        Expanded(
                          child: _ValueTile(
                            label: '표현 원칙',
                            value: principlesLabel(state.principles),
                            onTap: _editPrinciples,
                          ),
                        ),
                      ],
                    ),
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
            spacing: 10,
            children: [
              if (widget.waiting || reward.isEmpty)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    widget.waiting ? waitingNote : RewardBudgetPage.emptyNote,
                    textAlign: TextAlign.center,
                    style: CoraTextStyles.meta.copyWith(color: c.textSecondary),
                  ),
                ),
              CoraPrimaryButton(
                label: '검토하고 보내기',
                onPressed: canSend ? _review : null,
                look: CoraPrimaryButtonLook.accent,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 가게 카드(캔버스 첫 상자): 반경 22, 안쪽 14, 사진 52(반경 16) + 이름 16/700 + 둘째 줄 12 보조색.
class _StoreCard extends StatelessWidget {
  const _StoreCard({
    required this.name,
    required this.photoUrl,
    required this.subtitle,
  });

  final String name;
  final String? photoUrl;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return MergeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(CoraRadius.panel),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            spacing: 12,
            children: [
              ExcludeSemantics(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(CoraRadius.md),
                  child: SizedBox.square(
                    dimension: 52,
                    child: CoraNetworkPhoto(
                      url: photoUrl,
                      background: c.coverPlaceholder,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: CoraTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: c.text,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: CoraTextStyles.fieldLabel.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 가게 조건 요약(캔버스 둘째 상자): 반경 18, 안쪽 12/16, 13 줄 높이 1.6 보조색.
class _ConditionBox extends StatelessWidget {
  const _ConditionBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(CoraRadius.lg),
      ),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            text,
            style: CoraTextStyles.meta.copyWith(
              height: 1.6,
              color: c.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// 시리즈 카드 줄: 가로로 밀린다. 카드는 너비 140, 반경 20, 안쪽 12, 고른 것은 `notifyTabSelected`,
/// 아닌 것은 `surface`. 끝에 `시리즈 추가` 카드가 있다.
class _SeriesRow extends StatelessWidget {
  const _SeriesRow({
    required this.series,
    required this.selectedId,
    required this.onPick,
    required this.onAdd,
  });

  final List<CreatorSeries> series;
  final String? selectedId;
  final ValueChanged<CreatorSeries> onPick;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            for (final s in series)
              _SeriesCard(
                title: s.name,
                subtitle: seriesSubtitle(s.note, s.format),
                selected: s.id == selectedId,
                onTap: () => onPick(s),
              ),
            if (onAdd != null)
              _SeriesCard(title: '시리즈 추가', selected: false, onTap: onAdd!),
          ],
        ),
      ),
    );
  }
}

class _SeriesCard extends StatelessWidget {
  const _SeriesCard({
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      onTap: onTap,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: selected ? c.notifyTabSelected : c.surface,
              borderRadius: BorderRadius.circular(CoraRadius.field),
            ),
            child: SizedBox(
              width: 140,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: CoraTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: c.text,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: CoraTextStyles.fieldLabel.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 아이디어 입력란(캔버스 `label`): 반경 20, 안쪽 14/18, 라벨 12 보조색, 3줄 입력 15 줄 높이 1.55.
class _IdeaBox extends StatelessWidget {
  const _IdeaBox({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(CoraRadius.field),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '아이디어',
                style: CoraTextStyles.fieldLabel.copyWith(
                  color: c.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                key: const ValueKey<String>('counter.idea'),
                controller: controller,
                onChanged: onChanged,
                minLines: 3,
                maxLines: 3,
                keyboardType: TextInputType.multiline,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(
                    CounterProposal.ideaMaxLength,
                  ),
                ],
                style: CoraTextStyles.buttonMedium.copyWith(
                  fontWeight: FontWeight.w400,
                  height: 1.55,
                  color: c.text,
                ),
                cursorColor: c.text,
                decoration: const InputDecoration(
                  isCollapsed: true,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 값 칸(`희망 보상`, `표현 원칙`): 반경 18, 안쪽 12/14, 라벨 12 보조색, 값 15/500. 누르면 고친다.
class _ValueTile extends StatelessWidget {
  const _ValueTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      label: '$label, $value',
      onTap: onTap,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(CoraRadius.lg),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: CoraTextStyles.fieldLabel.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: CoraTextStyles.buttonMedium.copyWith(color: c.text),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
