import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_bottom_nav.dart';
import '../../../../core/ui/cora_logo.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../../../../core/ui/swipe_deck/swipe_physics.dart' show SwipeOutcome;
import '../../../discovery/domain/discovery_card.dart' show CreatorCard;
import '../../../discovery/presentation/discovery_text.dart';
import '../../../discovery/presentation/widgets/brand_bottom_nav.dart';
import '../../../discovery/presentation/widgets/discovery_toast.dart';
import '../../../received_proposals/domain/received_proposal.dart';
import '../../../received_proposals/presentation/pages/received_proposal_page.dart'
    show ReceivedProposalResult;
import '../../../received_proposals/presentation/viewmodels/received_proposals_view_model.dart';
import '../../../received_proposals/presentation/widgets/received_proposals_group.dart';
import '../../../store_browse/presentation/widgets/creator_bottom_nav.dart';
import '../../domain/interest_card.dart';
import '../interests_text.dart';
import '../viewmodels/interests_view_model.dart';
import '../widgets/hold_sheet.dart';
import '../widgets/interest_grid_card.dart';
import '../widgets/interest_icons.dart';
import '../widgets/interest_status_box.dart';
import '../widgets/interest_tabs.dart';
import 'match_sheet.dart';

/// 03 관심·보류. 내가 저장한(관심 + 보류) 후보를 두 줄 격자로 보여 준다. 브랜드는 카드 오른쪽 위 동그라미로
/// 비교할 후보를 두 장까지 고르고 아래 버튼으로 04를 연다. 크리에이터의 03은 같은 화면이고 비교가 없다.
///
/// [matchId]가 있으면(토스트의 `확인하기`, 알림의 서로 관심) 화면이 열린 뒤 그 협업의 05를 시트로 연다.
class InterestsPage extends ConsumerStatefulWidget {
  const InterestsPage({
    super.key,
    required this.isBrand,
    this.initialTab = InterestTab.saved,
    this.matchId,
  });

  final bool isBrand;
  final InterestTab initialTab;
  final String? matchId;

  @override
  ConsumerState<InterestsPage> createState() => _InterestsPageState();
}

class _InterestsPageState extends ConsumerState<InterestsPage> {
  bool _deciding = false;

  /// 05의 내용을 읽는 동안 화면을 막는 표시. 읽는 데 몇 초 걸려도 아무 일도 없는 것처럼 보이지 않게 하고,
  /// 그사이 다른 카드를 눌러 화면을 밀지 못하게 한다.
  bool _openingMatch = false;

  InterestsScope get _scope =>
      (isBrand: widget.isBrand, tab: widget.initialTab);

  InterestsViewModel get _vm =>
      ref.read(interestsViewModelProvider(_scope).notifier);

  @override
  void initState() {
    super.initState();
    final id = widget.matchId;
    if (id != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // 서로 관심은 방금 닿은 변화라(10에서 관심을 보낸 직후 등) 같은 목록을 쓰는 앞 화면이 옛 값을 쥐고
        // 있을 수 있다. 시트 뒤의 목록을 새로 읽는다.
        unawaited(_refreshAfterReturn());
        _openMatch(id, closeOnDismiss: true);
      });
    }
  }

  /// 05를 시트로 연다. 링크로 열린 화면([closeOnDismiss])에서 시트를 그냥 닫으면(버튼으로 이동한 것이 아니면)
  /// 발견으로 돌아간다.
  Future<void> _openMatch(String id, {bool closeOnDismiss = false}) async {
    setState(() => _openingMatch = true);
    try {
      final info = await _vm.loadMatch(id);
      if (!mounted) return;
      // 읽는 사이 이 화면이 맨 위가 아니게 됐으면(다른 화면으로 갔으면) 그 위에 시트를 올리지 않는다.
      if (ModalRoute.of(context)?.isCurrent == false) return;
      setState(() => _openingMatch = false);
      final result = await showMatchSheet(context, info);
      if (!mounted) return;
      if (closeOnDismiss && result != MatchSheetResult.moved) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(widget.isBrand ? AppRoutes.brand : AppRoutes.creator);
        }
      }
    } catch (_) {
      if (mounted) _vm.showNotice(DiscoveryTexts.retryLater);
    } finally {
      if (mounted && _openingMatch) setState(() => _openingMatch = false);
    }
  }

  Future<void> _openCard(InterestCard card) async {
    if (card.state == InterestState.held) {
      final outcome = await showHoldSheet(context);
      if (outcome == null || !mounted) return;
      await _decideHeld(card, outcome);
      return;
    }
    if (!widget.isBrand) {
      await context.push(AppRoutes.creatorCampaign(card.id));
      await _refreshAfterReturn();
      return;
    }
    final band = card.feeBand;
    await context.push(
      AppRoutes.brandCreator(card.id),
      // 상세는 카드를 받으면 오늘 목록을 뒤지지 않는다(이미 결정한 카드는 오늘 목록에 없다).
      extra: band == null
          ? null
          : CreatorCard(
              creatorId: card.id,
              displayName: card.name,
              headline: card.headline,
              photoUrl: card.photoUrl,
              feeBand: band,
            ),
    );
    await _refreshAfterReturn();
  }

  /// 04·상세·06에서 돌아오면 그 사이 바뀐 결정(서로 관심 등)이 03에 보이도록 목록을 다시 읽는다. 크리에이터는
  /// 받은 제안도 다시 읽는다(관심을 보내거나 질문한 캠페인은 목록에서 빠진다).
  Future<void> _refreshAfterReturn() async {
    if (!mounted) return;
    if (!widget.isBrand) {
      ref.read(receivedProposalsViewModelProvider.notifier).refresh();
    }
    await _vm.refresh();
  }

  /// 받은 제안(10)을 연다. 10이 닫히면서 돌려주는 안내 문구를 띄우고, 서로 관심이 닿았으면 이 화면이 05를 연다.
  Future<void> _openProposal(ReceivedProposal proposal) async {
    final result = await context.push<ReceivedProposalResult>(
      AppRoutes.creatorReceivedProposal(proposal.campaignId),
    );
    if (!mounted) return;
    final notice = result?.notice;
    if (notice != null) _vm.showNotice(notice);
    // 관심을 보낸 캠페인은 받은 제안에서 빠졌다. 05 뒤의 목록이 옛 묶음을 쥐지 않게 새로 읽되, 05 내용을
    // 읽는 일을 그 뒤로 미루지 않고 나란히 시작한다(원격 왕복이 줄지어 서면 시트가 몇 초 늦게 뜬다).
    unawaited(_refreshAfterReturn());
    final matchId = result?.matchCollaborationId;
    if (matchId != null) await _openMatch(matchId);
  }

  Future<void> _decideHeld(InterestCard card, SwipeOutcome outcome) async {
    if (_deciding) return;
    _deciding = true;
    try {
      final matchId = await _vm.decideHeld(
        card,
        outcome,
        message: outcome == SwipeOutcome.like
            ? DiscoveryTexts.likeToast
            : (widget.isBrand
                  ? DiscoveryTexts.passToast
                  : InterestsTexts.passedForCreator),
      );
      if (matchId != null && mounted) await _openMatch(matchId);
    } catch (_) {
      if (mounted) _vm.showNotice(DiscoveryTexts.retryLater);
    } finally {
      _deciding = false;
    }
  }

  Future<void> _compare(InterestsState state) async {
    if (!state.canCompare) return;
    final [a, b] = state.selected;
    await context.push(AppRoutes.brandCompare(a, b));
    await _refreshAfterReturn();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(interestsViewModelProvider(_scope));
    final state = async.value;
    final c = context.colors;
    // 크리에이터의 받은 제안(맨 위 묶음). 읽지 못하면 묶음만 없고 03은 그대로다.
    final proposals = widget.isBrand
        ? const <ReceivedProposal>[]
        : (ref.watch(receivedProposalsViewModelProvider).value ??
              const <ReceivedProposal>[]);

    final Widget body;
    if (state == null) {
      body = Padding(
        padding: const EdgeInsets.only(top: 16),
        child: async.hasError
            ? CoraStateView.loadFailed(
                title: InterestsTexts.loadFailedTitle,
                onRetry: _vm.reload,
              )
            : const CoraStateView.loading(),
      );
    } else if (state.visible.isEmpty) {
      body = const Padding(
        padding: EdgeInsets.only(top: 16),
        child: CoraStateView.empty(
          title: InterestsTexts.emptyTitle,
          description: InterestsTexts.emptyBody,
        ),
      );
    } else {
      body = _List(
        state: state,
        isBrand: widget.isBrand,
        onTapCard: _openCard,
        onTogglePick: (card) => _vm.togglePick(card),
        onOpenTerms: (card) async {
          final id = card.collaborationId;
          if (id == null) return;
          await context.push(AppRoutes.collaborationTerms(id));
          await _refreshAfterReturn();
        },
      );
    }

    final notice = state?.notice;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(isBrand: widget.isBrand),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 4,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            InterestsTexts.title,
                            style: CoraTextStyles.title.copyWith(
                              letterSpacing: -0.78,
                              height: 1.448,
                              color: c.text,
                            ),
                          ),
                        ),
                        Text(
                          widget.isBrand
                              ? InterestsTexts.brandDescription
                              : InterestsTexts.creatorDescription,
                          style: CoraTextStyles.meta.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (proposals.isNotEmpty)
                    ReceivedProposalsGroup(
                      proposals: proposals,
                      onOpen: _openProposal,
                    ),
                  if (state != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: InterestTabs(
                        labels: [
                          InterestsTexts.tabSaved(
                            state.count(InterestTab.saved),
                          ),
                          InterestsTexts.tabMutual(
                            state.count(InterestTab.mutual),
                          ),
                          InterestsTexts.tabSent(state.count(InterestTab.sent)),
                          InterestsTexts.tabHeld(state.count(InterestTab.held)),
                        ],
                        selected: InterestTab.values.indexOf(state.tab),
                        onChanged: (i) => _vm.selectTab(InterestTab.values[i]),
                      ),
                    ),
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(child: body),
                        if (notice != null)
                          Positioned(
                            top: 12,
                            left: 22,
                            right: 22,
                            child: DiscoveryToastBanner(
                              key: ValueKey(notice.serial),
                              message: notice.message,
                              onDismiss: () => _vm.dismissNotice(notice.serial),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.isBrand && state != null && state.visible.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 100,
              child: _CompareButton(
                count: state.selected.length,
                enabled: state.canCompare,
                onTap: () => _compare(state),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: widget.isBrand
                ? const BrandBottomNav(currentIndex: CoraCreatorNavItems.likes)
                : const CreatorBottomNav(
                    currentIndex: CoraCreatorNavItems.likes,
                  ),
          ),
          // 05 내용을 읽는 동안: 아래 화면을 막고 공용 불러오는 중 카드를 가운데에 둔다.
          if (_openingMatch)
            const Positioned.fill(
              child: Stack(
                children: [
                  ModalBarrier(dismissible: false, color: Colors.transparent),
                  Center(
                    child: SizedBox(
                      height: 120,
                      child: CoraStateView.loading(),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 머리(캔버스 Likes): 안쪽 위 14·아래 10·좌우 16. 왼쪽 로고, 오른쪽 관점 알약(`surface` 바탕, 12/500).
class _Header extends StatelessWidget {
  const _Header({required this.isBrand});

  final bool isBrand;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const CoraLogo(size: 26),
          DecoratedBox(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                isBrand ? InterestsTexts.brandPill : InterestsTexts.creatorPill,
                style: CoraTextStyles.caption.copyWith(color: c.text),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 카드 격자(두 줄, 사이 10, 좌우 16)와 그 아래 상자.
class _List extends StatelessWidget {
  const _List({
    required this.state,
    required this.isBrand,
    required this.onTapCard,
    required this.onTogglePick,
    required this.onOpenTerms,
  });

  final InterestsState state;
  final bool isBrand;
  final void Function(InterestCard card) onTapCard;
  final void Function(InterestCard card) onTogglePick;
  final void Function(InterestCard card) onOpenTerms;

  @override
  Widget build(BuildContext context) {
    final cards = state.visible;
    final mutual = [
      for (final c in cards)
        if (c.state == InterestState.mutual) c,
    ];
    final waiting = [
      for (final c in cards)
        if (c.state == InterestState.waiting) c,
    ];
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              mainAxisExtent: InterestGridCard.height,
            ),
            delegate: SliverChildBuilderDelegate(childCount: cards.length, (
              context,
              i,
            ) {
              final card = cards[i];
              return InterestGridCard(
                key: ValueKey(card.id),
                card: card,
                picked: state.selected.contains(card.id),
                onTap: () => onTapCard(card),
                onTogglePick: isBrand ? () => onTogglePick(card) : null,
              );
            }),
          ),
        ),
        if (mutual.isNotEmpty || waiting.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverToBoxAdapter(
              child: InterestStatusBox(
                mutual: mutual,
                waiting: waiting,
                onOpenTerms: onOpenTerms,
              ),
            ),
          ),
        // 떠 있는 비교 버튼(아래 100 + 54)과 그 위 안내 줄, 하단 메뉴 밑으로 내용이 밀리지 않게.
        SliverToBoxAdapter(child: SizedBox(height: isBrand ? 220 : 120)),
      ],
    );
  }
}

/// 아래 `선택한 {n}명 비교하기`: 높이 54, 알약, 라임 바탕에 16/700, 앞에 두 칸 아이콘. 두 장을 골랐을 때만
/// 켜지고, 아니면 꺼지며 위에 `비교할 후보 2명을 골라 주세요.`가 보인다.
class _CompareButton extends StatelessWidget {
  const _CompareButton({
    required this.count,
    required this.enabled,
    required this.onTap,
  });

  final int count;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final label = InterestsTexts.compareButton(count);
    final foreground = enabled ? c.onAccent : c.textSecondary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        if (!enabled)
          Text(
            InterestsTexts.compareNeedTwo,
            textAlign: TextAlign.center,
            style: CoraTextStyles.caption.copyWith(color: c.textSecondary),
          ),
        Semantics(
          container: true,
          button: true,
          enabled: enabled,
          label: label,
          onTap: enabled ? onTap : null,
          child: ExcludeSemantics(
            child: CoraPressable(
              onTap: enabled ? onTap : null,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: enabled ? c.accent : c.surface,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: SizedBox(
                  height: 54,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 8,
                    children: [
                      InterestIcon(ComparePainter(foreground), size: 18),
                      Text(
                        label,
                        style: CoraTextStyles.button.copyWith(
                          color: foreground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
