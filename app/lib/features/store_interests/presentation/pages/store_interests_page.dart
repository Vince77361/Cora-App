import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_bottom_nav.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../../../../core/ui/cora_step_header.dart';
import '../../../interests/presentation/widgets/interest_tabs.dart';
import '../../../offers/presentation/pages/send_offer_page.dart';
import '../../../proposals/domain/proposal.dart';
import '../../../proposals/presentation/proposal_text.dart';
import '../../../store_discover/presentation/pages/store_discover_page.dart';
import '../../../store_home/domain/applicant.dart' show CreatorSummary;
import '../../../store_discover/presentation/store_discover_text.dart';
import '../../../world_cup/domain/world_cup_candidate.dart';
import '../../../world_cup/presentation/widgets/world_cup_banner.dart';
import '../../../world_cup/presentation/world_cup_flow.dart';
import '../../domain/store_interest.dart';
import '../store_interests_text.dart';
import '../viewmodels/store_interests_view_model.dart';
import '../widgets/interest_list_row.dart';

/// 사장님의 저장함(G2, 캔버스 M19G2TabsB). 내가 저장한 크리에이터, 하트를 보낸 크리에이터, 내가 보낸 제안을 세 탭의
/// 줄 목록으로 본다. 하단 메뉴에 저장함이 없어 둘러보기 머리의 북마크와 알림이 연다.
///
/// [initialTab]은 처음 열 탭이다(`?tab=saved|sent|offers`).
class StoreInterestsPage extends ConsumerStatefulWidget {
  const StoreInterestsPage({
    super.key,
    this.initialTab = StoreInterestTab.saved,
  });

  final StoreInterestTab initialTab;

  @override
  ConsumerState<StoreInterestsPage> createState() => _StoreInterestsPageState();
}

class _StoreInterestsPageState extends ConsumerState<StoreInterestsPage> {
  late StoreInterestTab _tab = widget.initialTab;

  StoreInterestsViewModel get _vm =>
      ref.read(storeInterestsViewModelProvider.notifier);

  @override
  void initState() {
    super.initState();
    // 둘러보기가 이미 읽어 둔 목록이 있으면 옛 값일 수 있어 새로 읽는다(처음 읽는 중이면 그대로 둔다).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(storeInterestsViewModelProvider).hasValue) {
        unawaited(_vm.refresh());
      }
    });
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.storeDiscover);
    }
  }

  void _onNav(int index) {
    switch (index) {
      case StoreDiscoverPage.navHome:
        context.go(AppRoutes.store);
      case StoreDiscoverPage.navFind:
        _back();
      case StoreDiscoverPage.navChat:
        context.go(AppRoutes.chats);
      case StoreDiscoverPage.navOffers:
        context.push(AppRoutes.storeProposals);
      case StoreDiscoverPage.navDrafts:
        context.push(AppRoutes.storeDrafts);
    }
  }

  /// 받는 사람이 채워진 오퍼 작성(A5)을 연다.
  Future<void> _propose(StoreInterest creator) async {
    await context.push(
      AppRoutes.storeOfferNew(creator.creatorId),
      extra: _offerArgs(creator),
    );
    if (mounted) unawaited(_vm.refresh());
  }

  static SendOfferArgs _offerArgs(StoreInterest creator) => SendOfferArgs(
    creator: CreatorSummary(
      userId: creator.creatorId,
      displayName: creator.name,
      contentFocus: creator.contentFocus,
      photoUrl: creator.photoUrl,
    ),
  );

  /// 이상형 월드컵(G3): 저장한 사람 전부를 후보로 넘긴다. 서버 목록에 한 줄 설명(대표 게시물)이 없어 한 줄은 비워 둔다.
  /// 우승자에게 `제안하기`는 저장 줄의 `제안하기`와 같은 오퍼 작성(A5)이다.
  Future<void> _startWorldCup(List<StoreInterest> saved) {
    final byId = {for (final p in saved) p.creatorId: p};
    return startWorldCup(
      context,
      saved: [
        for (final (i, p) in saved.indexed)
          WorldCupCandidate(
            id: p.creatorId,
            name: p.name,
            headline: p.headline,
            // 월드컵 카드는 대표 게시물 1번 사진이다. 게시물이 없으면 프로필 사진으로 대신한다.
            photoUrl: p.representativePhotoUrl ?? p.photoUrl,
            meta: StoreDiscoverTexts.infoLine(p.contentFocus, p.followers),
            savedOrder: i + 1,
          ),
      ],
      onPropose: (context, winner) async {
        final creator = byId[winner.id];
        if (creator != null) {
          await context.push(
            AppRoutes.storeOfferNew(creator.creatorId),
            extra: _offerArgs(creator),
          );
        }
        return null;
      },
    );
  }

  /// 크리에이터 상세. 사장님이 크리에이터 상세를 볼 화면이 아직 없어 준비 중 화면을 연다.
  void _openProfile(StoreInterest creator) => context.push(
    AppRoutes.storeComingSoon(StoreInterestsTexts.creatorDetailSoon),
    extra: AppRoutes.stacked,
  );

  Future<void> _openOffer(ProposalRow row) async {
    await context.push(AppRoutes.storeProposal(row.offerId));
    if (mounted) unawaited(_vm.refresh());
  }

  Widget _empty(StoreInterestTab tab) => switch (tab) {
    StoreInterestTab.saved => CoraStateView.empty(
      title: StoreInterestsTexts.emptySavedTitle,
      description: StoreInterestsTexts.emptySavedBody,
      actionLabel: StoreInterestsTexts.emptySavedAction,
      onAction: () => context.push(AppRoutes.storeDiscover),
    ),
    StoreInterestTab.sent => const CoraStateView.empty(
      title: StoreInterestsTexts.emptySentTitle,
      description: StoreInterestsTexts.emptySentBody,
    ),
    StoreInterestTab.offers => const CoraStateView.empty(
      title: StoreInterestsTexts.emptyOffersTitle,
      description: StoreInterestsTexts.emptyOffersBody,
    ),
  };

  List<Widget> _rows(StoreInterestsState state) => switch (_tab) {
    StoreInterestTab.saved => [
      for (final p in state.saved)
        InterestListRow(
          key: ValueKey('saved-${p.creatorId}'),
          name: p.name,
          photoUrl: p.photoUrl,
          meta: StoreInterestsTexts.meta(p.contentFocus, p.followers),
          actionLabel: StoreInterestsTexts.propose,
          onAction: () => _propose(p),
          onTap: () => _openProfile(p),
        ),
    ],
    StoreInterestTab.sent => [
      for (final p in state.sent)
        InterestListRow(
          key: ValueKey('sent-${p.creatorId}'),
          name: p.name,
          photoUrl: p.photoUrl,
          meta: StoreInterestsTexts.meta(p.contentFocus, p.followers),
          chip: p.mutual ? InterestRowChip.mutual : InterestRowChip.waiting,
          actionLabel: p.mutual
              ? StoreInterestsTexts.propose
              : StoreInterestsTexts.profile,
          actionHot: p.mutual,
          onAction: p.mutual ? () => _propose(p) : () => _openProfile(p),
          onTap: () => _openProfile(p),
        ),
    ],
    StoreInterestTab.offers => [
      for (final row in state.offers)
        InterestListRow(
          key: ValueKey('offer-${row.offerId}'),
          name: row.name,
          photoUrl: row.photoUrl,
          meta: rowSubtitle(row),
          actionLabel: row.group == ProposalGroup.myTurn
              ? StoreInterestsTexts.respond
              : StoreInterestsTexts.waitingButton,
          actionHot: row.group == ProposalGroup.myTurn,
          onAction: () => _openOffer(row),
          onTap: () => _openOffer(row),
        ),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final async = ref.watch(storeInterestsViewModelProvider);
    final state = async.value;

    final Widget body;
    if (state == null) {
      body = Padding(
        padding: const EdgeInsets.only(top: 16),
        child: async.hasError
            ? CoraStateView.loadFailed(
                title: StoreInterestsTexts.loadFailedTitle,
                onRetry: _vm.reload,
              )
            : const CoraStateView.loading(),
      );
    } else if (state.count(_tab) == 0) {
      body = Padding(
        padding: const EdgeInsets.only(top: 16),
        child: _empty(_tab),
      );
    } else {
      body = ListView(
        // 하단 메뉴(아래 20 + 높이 64) 밑으로 마지막 줄이 가려지지 않게 한다.
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 120),
        children: [
          // 저장이 4명 이상이면 저장 탭 맨 위에 월드컵 배너(캔버스 M19G3Banner: 탭 아래 14, 좌우 16, 목록과 6 사이).
          if (_tab == StoreInterestTab.saved &&
              WorldCupBanner.shownFor(state.saved.length)) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
              child: WorldCupBanner(
                savedCount: state.saved.length,
                onStart: () => _startWorldCup(state.saved),
              ),
            ),
          ],
          ..._rows(state),
        ],
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 캔버스 `.hdr3`: 높이 64, 좌우 8. 가운데 제목은 없다.
                  SizedBox(
                    height: 64,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: CoraBackButton(onPressed: _back),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 4,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            StoreInterestsTexts.title,
                            style: CoraTextStyles.title.copyWith(
                              letterSpacing: -0.78,
                              height: 1.448,
                              color: c.text,
                            ),
                          ),
                        ),
                        Text(
                          StoreInterestsTexts.description,
                          style: CoraTextStyles.meta.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (state != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: InterestTabs(
                        height: 38,
                        selectedColor: c.notifyTabSelected,
                        selectedShadow: false,
                        semanticLabel: StoreInterestsTexts.tabListLabel,
                        labels: [
                          StoreInterestsTexts.tabSaved(
                            state.count(StoreInterestTab.saved),
                          ),
                          StoreInterestsTexts.tabSent(
                            state.count(StoreInterestTab.sent),
                          ),
                          StoreInterestsTexts.tabOffers(
                            state.count(StoreInterestTab.offers),
                          ),
                        ],
                        selected: StoreInterestTab.values.indexOf(_tab),
                        onChanged: (i) =>
                            setState(() => _tab = StoreInterestTab.values[i]),
                      ),
                    ),
                  Expanded(child: body),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CoraBottomNav(
              items: CoraNavItems.store,
              currentIndex: StoreDiscoverPage.navFind,
              onTap: _onNav,
            ),
          ),
        ],
      ),
    );
  }
}
