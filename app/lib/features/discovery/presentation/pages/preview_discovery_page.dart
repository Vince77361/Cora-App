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
import '../../domain/discovery_card.dart';
import '../discovery_text.dart';
import '../viewmodels/preview_discovery_view_model.dart';
import '../widgets/creator_swipe_card.dart';
import '../widgets/discovery_header.dart';
import '../widgets/swipe_action_buttons.dart';

/// A1의 `등록 없이 먼저 둘러보기`가 여는 01(둘러보기). 역할이 없는 로그인 사용자가 카드를 읽기만 한다
/// (공통 규칙 23장). 결정·넘긴 이유·되돌리기를 서버에 보내지 않는다.
///
/// - 왼쪽으로 밀기와 넘김 버튼은 다음 카드로 간다(저장 없음).
/// - 오른쪽·위로 밀기는 카드가 제자리로 돌아온 뒤 A1로 간다. 관심·보류 버튼, 카드를 누를 때, 하단 메뉴의
///   `발견` 밖의 탭도 A1로 간다. 이때 A1이 `역할을 고르면 관심을 보낼 수 있어요.`를 한 번 보인다.
/// - 머리의 `역할 고르기`와 다 봤을 때·카드가 없을 때의 `역할 고르기`는 안내 없이 A1로 간다.
class PreviewDiscoveryPage extends ConsumerStatefulWidget {
  const PreviewDiscoveryPage({super.key});

  @override
  ConsumerState<PreviewDiscoveryPage> createState() =>
      _PreviewDiscoveryPageState();
}

class _PreviewDiscoveryPageState extends ConsumerState<PreviewDiscoveryPage> {
  final _controller = SwipeDeckController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// A1로 돌아간다. [hint]이면 A1이 안내를 한 번 보인다(A1이 `push`의 결과로 받는다). 쌓인 화면이
  /// 없으면(앱을 처음부터 이 경로로 열었다면) A1로 간다.
  void _toRolePage({bool hint = false}) {
    if (context.canPop()) {
      context.pop(hint);
    } else {
      context.go(AppRoutes.role);
    }
  }

  Future<void> _onSwiped(PreviewCard card, SwipeOutcome outcome) async {
    if (outcome != SwipeOutcome.pass) throw const SwipeRejected();
    ref.read(previewDiscoveryViewModelProvider.notifier).pass(card);
  }

  /// 둘러보기 카드를 01의 카드 모양으로 그린다. 인스타그램 아이디나 잘 맞는 이유는 처음부터 없다.
  CreatorCard _asCard(PreviewCard card) => CreatorCard(
    creatorId: card.creatorId,
    displayName: card.displayName,
    headline: card.headline,
    photoUrl: card.photoUrl,
    feeBand: card.feeBand,
    tags: card.tags,
  );

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(previewDiscoveryViewModelProvider);
    final state = async.value;

    final Widget body;
    if (state == null) {
      body = async.hasError
          ? CoraStateView.loadFailed(
              title: DiscoveryTexts.loadFailedTitle,
              onRetry: ref
                  .read(previewDiscoveryViewModelProvider.notifier)
                  .reload,
            )
          : const CoraStateView.loading();
    } else if (state.total == 0) {
      body = CoraStateView.empty(
        title: DiscoveryTexts.previewEmptyTitle,
        actionLabel: DiscoveryTexts.chooseRole,
        onAction: _toRolePage,
      );
    } else if (state.remaining.isEmpty) {
      body = CoraStateView(
        kind: CoraStateKind.allSeen,
        title: DiscoveryTexts.previewDoneTitle,
        description: DiscoveryTexts.previewDoneBody,
        actionLabel: DiscoveryTexts.chooseRole,
        onAction: _toRolePage,
      );
    } else {
      body = _PreviewDeck(
        state: state,
        controller: _controller,
        asCard: _asCard,
        onSwiped: _onSwiped,
        onRejected: () => _toRolePage(hint: true),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  DiscoveryHeader(onChooseRole: _toRolePage),
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
              items: CoraCreatorNavItems.items,
              currentIndex: CoraCreatorNavItems.discover,
              // `발견` 밖의 탭은 역할이 있어야 쓴다.
              onTap: (index) {
                if (index != CoraCreatorNavItems.discover) {
                  _toRolePage(hint: true);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 01의 카드 영역과 같은 모양(좌우 12, 아래 100, 모서리 28, 그림자). 아래 버튼은 넘김·보류·관심 셋이다.
class _PreviewDeck extends StatelessWidget {
  const _PreviewDeck({
    required this.state,
    required this.controller,
    required this.asCard,
    required this.onSwiped,
    required this.onRejected,
  });

  final PreviewDiscoveryState state;
  final SwipeDeckController controller;
  final CreatorCard Function(PreviewCard) asCard;
  final Future<void> Function(PreviewCard, SwipeOutcome) onSwiped;
  final VoidCallback onRejected;

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
              SwipeDeck<PreviewCard>(
                controller: controller,
                items: state.remaining,
                onSwiped: onSwiped,
                onRejected: onRejected,
                // 카드를 눌러도 상세는 없다. A1로 돌아가 역할을 고르게 한다.
                onTap: onRejected,
                cardBuilder: (context, card) => CreatorSwipeCard(
                  card: asCard(card),
                  position: state.positionOf(card),
                  total: state.total,
                ),
                empty: const SizedBox.shrink(),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 26,
                child: SwipeActionButtons(
                  showUndo: false,
                  canUndo: false,
                  onUndo: () {},
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
