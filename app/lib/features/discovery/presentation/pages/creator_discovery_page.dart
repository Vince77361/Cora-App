import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/cora_shadows.dart';
import '../../../../core/theme/cora_swipe_tokens.dart';
import '../../../../core/ui/cora_bottom_nav.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../../../../core/ui/swipe_deck/swipe_deck.dart';
import '../../../store_browse/presentation/widgets/creator_bottom_nav.dart';
import '../../domain/discovery_card.dart';
import '../creator_discovery_text.dart';
import '../discovery_text.dart';
import '../viewmodels/creator_discovery_view_model.dart';
import '../widgets/discovery_header.dart';
import '../widgets/discovery_swipe_card.dart';
import '../widgets/discovery_toast.dart';
import '../widgets/pass_reason_sheet.dart';
import '../widgets/principles_banner.dart';
import '../widgets/swipe_action_buttons.dart';
import '../widgets/undo_last_link.dart';

/// 08 크리에이터의 발견. 오늘의 캠페인 카드와 가게 카드를 한 장씩 넘겨 본다(캔버스 CreatorDiscover).
/// 오른쪽은 관심(가게는 `조건 그대로 지원`), 왼쪽은 넘김, 위는 보류이고 아래 버튼으로도 된다.
/// 가게 카드에는 보류가 없어서 위로 밀면 카드가 제자리로 돌아온다. 카드를 밀지 않고 누르면 캠페인은
/// D1, 가게는 D2가 열린다.
class CreatorDiscoveryPage extends ConsumerStatefulWidget {
  const CreatorDiscoveryPage({super.key});

  @override
  ConsumerState<CreatorDiscoveryPage> createState() =>
      _CreatorDiscoveryPageState();
}

class _CreatorDiscoveryPageState extends ConsumerState<CreatorDiscoveryPage> {
  final _controller = SwipeDeckController();
  bool _undoing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  CreatorDiscoveryViewModel get _vm =>
      ref.read(creatorDiscoveryViewModelProvider.notifier);

  Future<void> _onSwiped(DiscoveryCard card, SwipeOutcome outcome) async {
    try {
      await _vm.decide(card, outcome);
    } catch (_) {
      // 저장하지 못한 결정이다. 안내를 띄우고 다시 던져 덱이 카드를 제자리로 돌려놓게 한다.
      _vm.showNotice(DiscoveryTexts.retryLater);
      rethrow;
    }
  }

  Future<void> _undo(CreatorDiscoveryState state) async {
    if (_undoing || _controller.busy || !state.canUndo) return;
    _undoing = true;
    try {
      final result = await _vm.undoLast();
      if (result == UndoResult.undone) return;
      _vm.showNotice(
        result == UndoResult.nothing
            ? DiscoveryTexts.undoTooLate
            : DiscoveryTexts.retryLater,
      );
    } finally {
      _undoing = false;
    }
  }

  void _openReason(CreatorToast toast) {
    final target = toast.target;
    if (target == null) return;
    _vm.dismissToast(toast.serial);
    showPassReasonSheet(
      context,
      onSave: (reason) => _vm.setPassReason(target, reason),
    );
  }

  void _openDetail(CreatorDiscoveryState state) {
    final remaining = state.remaining;
    if (remaining.isEmpty) return;
    final card = remaining.first;
    switch (card) {
      case CampaignCard():
        context.push(AppRoutes.creatorCampaign(card.campaignId), extra: card);
      case StoreCard():
        context.push(AppRoutes.creatorStore(card.store.id));
    }
  }

  void _openPrinciples() =>
      context.push(AppRoutes.creatorPrinciples, extra: AppRoutes.stacked);

  Widget _toast(CreatorToast toast) {
    void dismiss() => _vm.dismissToast(toast.serial);
    final key = ValueKey(toast.serial);
    return switch (toast.kind) {
      CreatorToastKind.pass => DiscoveryToastBanner(
        key: key,
        creator: true,
        message: CreatorDiscoveryTexts.passToast,
        action: CreatorDiscoveryTexts.passToastAction,
        onAction: () => _openReason(toast),
        onDismiss: dismiss,
      ),
      CreatorToastKind.like => DiscoveryToastBanner(
        key: key,
        creator: true,
        message: CreatorDiscoveryTexts.likeToast,
        action: CreatorDiscoveryTexts.likeToastAction,
        onAction: () => context.push(AppRoutes.creatorSent),
        onDismiss: dismiss,
      ),
      CreatorToastKind.hold => DiscoveryToastBanner(
        key: key,
        creator: true,
        message: CreatorDiscoveryTexts.holdToast,
        action: CreatorDiscoveryTexts.holdToastAction,
        onAction: () => context.push(AppRoutes.creatorSaved),
        onDismiss: dismiss,
      ),
      CreatorToastKind.match => DiscoveryToastBanner(
        key: key,
        creator: true,
        match: true,
        message: CreatorDiscoveryTexts.matchToast(toast.brandName ?? ''),
        action: CreatorDiscoveryTexts.matchToastAction,
        onAction: () {
          final id = toast.collaborationId;
          if (id != null) context.push(AppRoutes.creatorMatch(id));
        },
        onDismiss: dismiss,
      ),
      CreatorToastKind.applied => DiscoveryToastBanner(
        key: key,
        creator: true,
        message: CreatorDiscoveryTexts.appliedToast,
        onDismiss: dismiss,
      ),
      CreatorToastKind.notice => DiscoveryToastBanner(
        key: key,
        creator: true,
        message: toast.message ?? '',
        onDismiss: dismiss,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(creatorDiscoveryViewModelProvider);
    final state = async.value;

    final Widget body;
    if (state == null) {
      body = async.hasError
          ? CoraStateView.loadFailed(
              title: CreatorDiscoveryTexts.loadFailedTitle,
              onRetry: _vm.reload,
            )
          : const CoraStateView.loading();
    } else if (state.total == 0) {
      body = CoraStateView.empty(
        title: CreatorDiscoveryTexts.emptyTitle,
        description: CreatorDiscoveryTexts.emptyBody,
        actionLabel: CreatorDiscoveryTexts.allSeenAction,
        onAction: _openPrinciples,
      );
    } else if (state.remaining.isEmpty) {
      body = Align(
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CoraStateView(
              kind: CoraStateKind.allSeen,
              title: CreatorDiscoveryTexts.allSeenTitle,
              description: CreatorDiscoveryTexts.allSeenBody,
              actionLabel: CreatorDiscoveryTexts.allSeenAction,
              onAction: _openPrinciples,
            ),
            UndoLastLink(canUndo: state.canUndo, onUndo: () => _undo(state)),
          ],
        ),
      );
    } else {
      body = _DeckSection(
        state: state,
        controller: _controller,
        onSwiped: _onSwiped,
        onTap: () => _openDetail(state),
        onUndo: () => _undo(state),
      );
    }

    final toast = state?.toast;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  const DiscoveryHeader(creator: true),
                  if (state != null && state.principlesMissing)
                    PrinciplesBanner(onTap: _openPrinciples),
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(child: body),
                        if (toast != null)
                          Positioned(
                            top: 12,
                            left: 22,
                            right: 22,
                            child: _toast(toast),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CreatorBottomNav(currentIndex: CoraCreatorNavItems.discover),
          ),
        ],
      ),
    );
  }
}

/// 카드 영역(캔버스의 `section`): 좌우 12, 아래 100(메뉴 위), 모서리 28, 그림자 0 16 40. 뒤에 있는
/// 카드가 작아 보일 때 가장자리에 보이는 바탕은 라이트 `#E6E8EB`, 다크 `#2A2D33`이다.
class _DeckSection extends StatelessWidget {
  const _DeckSection({
    required this.state,
    required this.controller,
    required this.onSwiped,
    required this.onTap,
    required this.onUndo,
  });

  final CreatorDiscoveryState state;
  final SwipeDeckController controller;
  final Future<void> Function(DiscoveryCard, SwipeOutcome) onSwiped;
  final VoidCallback onTap;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final remaining = state.remaining;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: dark
              ? CoraSwipeTokens.creatorBackdropDark
              : CoraSwipeTokens.backdrop,
          borderRadius: BorderRadius.circular(28),
          boxShadow: CoraShadows.swipeCard,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              SwipeDeck<DiscoveryCard>(
                controller: controller,
                items: remaining,
                onSwiped: onSwiped,
                onTap: onTap,
                // 가게 카드에는 보류가 없다. 위로 밀거나 보류 버튼을 누르면 카드가 제자리로 돌아온다.
                accepts: (outcome) =>
                    outcome != SwipeOutcome.hold ||
                    remaining.first is! StoreCard,
                cardBuilder: (context, card) => DiscoverySwipeCard(
                  card: card,
                  position: state.positionOf(card),
                  total: state.total,
                ),
                empty: const SizedBox.shrink(),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 16,
                child: SwipeActionButtons(
                  canUndo: state.canUndo,
                  onUndo: onUndo,
                  onPass: () => controller.swipe(SwipeOutcome.pass),
                  onHold: () => controller.swipe(SwipeOutcome.hold),
                  onLike: () => controller.swipe(SwipeOutcome.like),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
