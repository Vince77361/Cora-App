import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shadows.dart';
import '../../../../core/theme/cora_swipe_tokens.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../../../../core/ui/swipe_deck/swipe_deck.dart';
import '../../domain/discovery_card.dart';
import '../discovery_text.dart';
import '../viewmodels/brand_discovery_view_model.dart';
import '../widgets/brand_bottom_nav.dart';
import '../widgets/creator_swipe_card.dart';
import '../widgets/discovery_header.dart';
import '../widgets/discovery_toast.dart';
import '../widgets/pass_reason_sheet.dart';
import '../widgets/swipe_action_buttons.dart';

/// 01 발견(브랜드 관점). 오늘의 크리에이터 카드를 한 장씩 넘겨 본다. 오른쪽은 관심, 왼쪽은 넘김,
/// 위는 보류이고 아래 버튼으로도 된다. 카드를 밀지 않고 누르면 크리에이터 상세가 열린다.
class BrandDiscoveryPage extends ConsumerStatefulWidget {
  const BrandDiscoveryPage({super.key});

  @override
  ConsumerState<BrandDiscoveryPage> createState() => _BrandDiscoveryPageState();
}

class _BrandDiscoveryPageState extends ConsumerState<BrandDiscoveryPage> {
  final _controller = SwipeDeckController();
  bool _undoing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  BrandDiscoveryViewModel get _vm =>
      ref.read(brandDiscoveryViewModelProvider.notifier);

  Future<void> _onSwiped(CreatorCard card, SwipeOutcome outcome) async {
    try {
      await _vm.decide(card, outcome);
    } catch (_) {
      // 저장하지 못한 결정이다. 안내를 띄우고 다시 던져 덱이 카드를 제자리로 돌려놓게 한다.
      _vm.showNotice(DiscoveryTexts.retryLater);
      rethrow;
    }
  }

  Future<void> _undo(BrandDiscoveryState state) async {
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
      onSave: (reason) => _vm.setPassReason(target, reason),
    );
  }

  void _openDetail(BrandDiscoveryState state) {
    final remaining = state.remaining;
    if (remaining.isEmpty) return;
    final card = remaining.first;
    context.push(AppRoutes.brandCreator(card.creatorId), extra: card);
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
        onAction: () => context.push(AppRoutes.brandSent),
        onDismiss: dismiss,
      ),
      DiscoveryToastKind.hold => DiscoveryToastBanner(
        key: ValueKey(toast.serial),
        message: DiscoveryTexts.holdToast,
        action: DiscoveryTexts.holdToastAction,
        onAction: () => context.push(AppRoutes.brandSaved),
        onDismiss: dismiss,
      ),
      DiscoveryToastKind.match => DiscoveryToastBanner(
        key: ValueKey(toast.serial),
        match: true,
        message: DiscoveryTexts.matchToast(toast.name ?? ''),
        action: DiscoveryTexts.matchToastAction,
        onAction: () {
          final id = toast.collaborationId;
          if (id != null) context.push(AppRoutes.brandMatch(id));
        },
        onDismiss: dismiss,
      ),
      DiscoveryToastKind.notice => DiscoveryToastBanner(
        key: ValueKey(toast.serial),
        message: toast.message ?? '',
        onDismiss: dismiss,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(brandDiscoveryViewModelProvider);
    final state = async.value;

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
    } else if (state.total == 0) {
      body = const CoraStateView.empty(
        title: DiscoveryTexts.noCandidatesTitle,
        description: DiscoveryTexts.noCandidatesBody,
      );
    } else if (state.remaining.isEmpty) {
      body = _AllSeen(
        canUndo: state.canUndo,
        onOpenSaved: () => context.push(AppRoutes.brandSaved),
        onUndo: () => _undo(state),
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
                  const DiscoveryHeader(),
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
            child: BrandBottomNav(),
          ),
        ],
      ),
    );
  }
}

/// 카드 영역(캔버스의 `section`): 좌우 12, 아래 100(메뉴 위), 모서리 28, 그림자 0 16 40. 뒤에 있는
/// 카드가 작아 보일 때 가장자리에 보이는 바탕은 라이트 `#E6E8EB`, 다크 `#0F1012`다.
class _DeckSection extends StatelessWidget {
  const _DeckSection({
    required this.state,
    required this.controller,
    required this.onSwiped,
    required this.onTap,
    required this.onUndo,
  });

  final BrandDiscoveryState state;
  final SwipeDeckController controller;
  final Future<void> Function(CreatorCard, SwipeOutcome) onSwiped;
  final VoidCallback onTap;
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
              SwipeDeck<CreatorCard>(
                controller: controller,
                items: state.remaining,
                onSwiped: onSwiped,
                onTap: onTap,
                cardBuilder: (context, card) => CreatorSwipeCard(
                  card: card,
                  position: state.positionOf(card),
                  total: state.total,
                  onOpenDetail: onTap,
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

/// 오늘 추천을 다 봤을 때. F8 공용 위젯에 01 캔버스의 `마지막 카드 되돌리기`를 그 아래에 둔다
/// (되돌릴 결정이 없으면 흐리게).
class _AllSeen extends StatelessWidget {
  const _AllSeen({
    required this.canUndo,
    required this.onOpenSaved,
    required this.onUndo,
  });

  final bool canUndo;
  final VoidCallback onOpenSaved;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Align(
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CoraStateView.allSeen(onOpenSaved: onOpenSaved),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Semantics(
                container: true,
                button: true,
                enabled: canUndo,
                onTap: canUndo ? onUndo : null,
                child: ExcludeSemantics(
                  child: CoraPressable(
                    onTap: onUndo,
                    child: Opacity(
                      opacity: canUndo ? 1 : 0.45,
                      child: SizedBox(
                        height: 44,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          widthFactor: 1,
                          child: Text(
                            DiscoveryTexts.undoLast,
                            style: CoraTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w500,
                              color: c.text,
                              decoration: TextDecoration.underline,
                              decorationColor: c.text,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
