import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shadows.dart';
import '../../../../core/theme/cora_swipe_tokens.dart';
import '../../../../core/ui/cora_bottom_nav.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../../../../core/ui/swipe_deck/swipe_deck.dart';
import '../../../discovery/presentation/discovery_text.dart';
import '../../../discovery/presentation/viewmodels/brand_discovery_view_model.dart'
    show DiscoveryToast, DiscoveryToastKind;
import '../../../discovery/presentation/widgets/discovery_toast.dart';
import '../../../discovery/presentation/widgets/pass_reason_sheet.dart';
import '../../../discovery/presentation/widgets/swipe_action_buttons.dart';
import '../../../discovery/presentation/widgets/undo_last_link.dart';
import '../../domain/store_creator_card.dart';
import '../viewmodels/store_discover_view_model.dart';
import '../widgets/featured_post_card.dart';
import '../widgets/store_discover_header.dart';

/// 사장님의 전체 둘러보기(G1, 캔버스 M19G1Swipe). 오늘의 크리에이터 카드를 한 장씩 넘겨 본다. 오른쪽은
/// 하트, 왼쪽은 넘김, 위는 저장이고 아래 버튼으로도 된다. 카드는 대표 게시물을 탭으로 넘겨 본다.
class StoreDiscoverPage extends ConsumerStatefulWidget {
  const StoreDiscoverPage({super.key});

  /// 하단 메뉴 항목의 자리(`CoraNavItems.store`의 순서).
  static const navHome = 0;
  static const navFind = 1;
  static const navChat = 2;
  static const navOffers = 3;
  static const navDrafts = 4;

  @override
  ConsumerState<StoreDiscoverPage> createState() => _StoreDiscoverPageState();
}

class _StoreDiscoverPageState extends ConsumerState<StoreDiscoverPage> {
  final _controller = SwipeDeckController();
  bool _undoing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  StoreDiscoverViewModel get _vm =>
      ref.read(storeDiscoverViewModelProvider.notifier);

  Future<void> _onSwiped(StoreCreatorCard card, SwipeOutcome outcome) async {
    try {
      await _vm.decide(card, outcome);
    } catch (_) {
      // 저장하지 못한 결정이다. 안내를 띄우고 다시 던져 덱이 카드를 제자리로 돌려놓게 한다.
      _vm.showNotice(DiscoveryTexts.retryLater);
      rethrow;
    }
  }

  Future<void> _undo(StoreDiscoverState state) async {
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

  void _openReason(DiscoveryToast toast) {
    final target = toast.target;
    if (target == null) return;
    _vm.dismissToast(toast.serial);
    showPassReasonSheet(
      context,
      onSave: (reason) => _vm.setPassReason(target.id, reason),
    );
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.store);
    }
  }

  void _onNav(int index) {
    switch (index) {
      case StoreDiscoverPage.navHome:
        context.go(AppRoutes.store);
      case StoreDiscoverPage.navFind:
        break;
      case StoreDiscoverPage.navChat:
        context.go(AppRoutes.chats);
      case StoreDiscoverPage.navOffers:
        context.push(AppRoutes.storeProposals);
      case StoreDiscoverPage.navDrafts:
        context.push(AppRoutes.storeDrafts);
    }
  }

  Widget _toast(DiscoveryToast toast) {
    void dismiss() => _vm.dismissToast(toast.serial);
    return switch (toast.kind) {
      DiscoveryToastKind.pass => DiscoveryToastBanner(
        key: ValueKey(toast.serial),
        message: DiscoveryTexts.passToast,
        action: DiscoveryTexts.passToastAction,
        onAction: () => _openReason(toast),
        onDismiss: dismiss,
      ),
      DiscoveryToastKind.like => DiscoveryToastBanner(
        key: ValueKey(toast.serial),
        message: DiscoveryTexts.likeToast,
        action: DiscoveryTexts.likeToastAction,
        onAction: () => context.push(AppRoutes.storeSent),
        onDismiss: dismiss,
      ),
      DiscoveryToastKind.hold => DiscoveryToastBanner(
        key: ValueKey(toast.serial),
        message: DiscoveryTexts.holdToast,
        action: DiscoveryTexts.holdToastAction,
        onAction: () => context.push(AppRoutes.storeSaved),
        onDismiss: dismiss,
      ),
      // 사장님의 서로 관심은 이 화면에서 알리지 않는다(하트 응답에 `matched`가 없다).
      DiscoveryToastKind.match ||
      DiscoveryToastKind.notice => DiscoveryToastBanner(
        key: ValueKey(toast.serial),
        message: toast.message ?? '',
        onDismiss: dismiss,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(storeDiscoverViewModelProvider);
    final state = async.value;
    final savedCount = ref.watch(storeSavedCountProvider);

    final Widget body;
    if (state == null) {
      body = async.hasError
          ? Align(
              alignment: Alignment.topCenter,
              child: CoraStateView.loadFailed(
                title: DiscoveryTexts.loadFailedTitle,
                onRetry: _vm.reload,
              ),
            )
          : const CoraStateView.loading();
    } else if (state.nothingToday) {
      body = const CoraStateView.empty(
        title: DiscoveryTexts.noCandidatesTitle,
        description: DiscoveryTexts.noCandidatesBody,
      );
    } else if (state.remaining.isEmpty) {
      // 서버의 total은 이미 결정한 카드를 포함해서, 남은 카드가 없는지로 다 봤는지를 정한다.
      body = Align(
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CoraStateView.allSeen(
              onOpenSaved: () => context.push(AppRoutes.storeSaved),
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
                  StoreDiscoverHeader(
                    savedCount: savedCount,
                    onBack: _back,
                    onOpenSaved: () => context.push(AppRoutes.storeSaved),
                  ),
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

/// 카드 영역(캔버스의 `section.card`): 좌우 12, 아래 100(메뉴 위), 모서리 28, 그림자 0 16 40. 뒤에 있는
/// 카드가 작아 보일 때 가장자리에 보이는 바탕은 라이트 `#E6E8EB`, 다크 `#0F1012`다(브랜드 01과 같다).
class _DeckSection extends StatelessWidget {
  const _DeckSection({
    required this.state,
    required this.controller,
    required this.onSwiped,
    required this.onUndo,
  });

  final StoreDiscoverState state;
  final SwipeDeckController controller;
  final Future<void> Function(StoreCreatorCard, SwipeOutcome) onSwiped;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: dark ? c.background : CoraSwipeTokens.backdrop,
          borderRadius: BorderRadius.circular(28),
          boxShadow: CoraShadows.swipeCard,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 카드 전체를 누르는 동작은 없다. 탭은 카드 안에서 대표 게시물을 넘긴다.
              SwipeDeck<StoreCreatorCard>(
                controller: controller,
                items: state.remaining,
                onSwiped: onSwiped,
                cardBuilder: (context, card) => FeaturedPostCard(card: card),
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
