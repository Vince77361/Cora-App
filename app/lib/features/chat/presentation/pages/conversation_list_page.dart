import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/time/clock.dart';
import '../../../../core/ui/cora_bottom_nav.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../../../discovery/presentation/widgets/brand_bottom_nav.dart';
import '../../../onboarding/domain/user_role.dart';
import '../../../onboarding/presentation/viewmodels/me_view_model.dart';
import '../../../store_browse/presentation/widgets/creator_bottom_nav.dart';
import '../chat_text.dart';
import '../viewmodels/conversation_list_view_model.dart';
import '../widgets/conversation_row.dart';

/// 대화 목록(하단 메뉴의 `대화`). 캔버스에 없는 화면이라 계획 문구와 기존 토큰, 공용 위젯으로 최소로 만들었다.
/// 내가 답해야 하는 메시지 요청은 맨 위 `메시지 요청 {n}` 묶음에 모이고, 그 아래에 대화가 마지막 메시지가 최근인
/// 순서로 있다. 하단 메뉴는 역할(사장님·브랜드·크리에이터)에 맞는 것이고 `대화`가 켜져 있다.
class ConversationListPage extends ConsumerWidget {
  const ConversationListPage({super.key});

  /// 하단 메뉴(높이 64, 아래 20)에 가려지지 않게 목록 끝에 두는 여백.
  static const double _navClearance = 20 + 64 + 24;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final async = ref.watch(conversationListViewModelProvider);
    final role = ref.watch(meViewModelProvider.select((s) => s.value?.role));
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 64,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Semantics(
                        header: true,
                        child: Text(
                          ChatTexts.listTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CoraTextStyles.title.copyWith(
                            fontSize: 22,
                            letterSpacing: -0.88,
                            height: 1.448,
                            color: c.text,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: switch (async) {
                    AsyncData(:final value) when value.isEmpty =>
                      const CoraStateView.empty(
                        title: ChatTexts.emptyTitle,
                        description: ChatTexts.emptyDescription,
                      ),
                    AsyncData(:final value) => _List(state: value),
                    AsyncError() => CoraStateView.loadFailed(
                      title: ChatTexts.loadFailedTitle,
                      description: ChatTexts.loadFailedDescription,
                      onRetry: () =>
                          ref.invalidate(conversationListViewModelProvider),
                    ),
                    _ => const CoraStateView.loading(),
                  },
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _ChatNav(role: role),
          ),
        ],
      ),
    );
  }
}

class _List extends ConsumerWidget {
  const _List({required this.state});

  final ConversationListState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final now = ref.watch(clockProvider).now();
    final vm = ref.read(conversationListViewModelProvider.notifier);

    Future<void> open(String route) async {
      await context.push(route);
      // 방에서 읽거나 답하고 돌아오면 안 읽은 수와 순서가 바뀌어 있다.
      if (context.mounted) await vm.refresh();
    }

    return RefreshIndicator(
      onRefresh: vm.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          8,
          0,
          8,
          ConversationListPage._navClearance,
        ),
        children: [
          if (state.requests.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Semantics(
                header: true,
                child: Text(
                  ChatTexts.requestGroup(state.requests.length),
                  style: CoraTextStyles.label.copyWith(color: c.textSecondary),
                ),
              ),
            ),
            for (final row in state.requests)
              ConversationRow(
                key: ValueKey('request-${row.id}'),
                row: row,
                now: now,
                onTap: () => open(AppRoutes.chatRequest(row.id)),
              ),
            if (state.conversations.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: ColoredBox(
                  color: c.line,
                  child: const SizedBox(height: 1, width: double.infinity),
                ),
              ),
          ],
          for (final row in state.conversations)
            ConversationRow(
              key: ValueKey('conversation-${row.id}'),
              row: row,
              now: now,
              onTap: () => open(AppRoutes.chat(row.id)),
            ),
        ],
      ),
    );
  }
}

/// 역할에 맞는 하단 메뉴. 역할을 아직 모르면(읽는 중) 그리지 않는다.
class _ChatNav extends StatelessWidget {
  const _ChatNav({required this.role});

  final UserRole? role;

  @override
  Widget build(BuildContext context) => switch (role) {
    UserRole.store => CoraBottomNav(
      items: CoraNavItems.store,
      currentIndex: _storeChat,
      onTap: (index) => _onStoreNav(context, index),
    ),
    UserRole.brand => const BrandBottomNav(
      currentIndex: CoraCreatorNavItems.chat,
    ),
    UserRole.creator => const CreatorBottomNav(
      currentIndex: CoraCreatorNavItems.chat,
    ),
    null => const SizedBox.shrink(),
  };

  // 사장님 하단 메뉴의 순서(홈, 찾기, 대화, 오퍼, AI 글).
  static const _storeHome = 0;
  static const _storeFind = 1;
  static const _storeChat = 2;
  static const _storeOffers = 3;
  static const _storeDrafts = 4;

  static void _onStoreNav(BuildContext context, int index) {
    switch (index) {
      case _storeHome:
        context.go(AppRoutes.store);
      case _storeFind:
        context.push(AppRoutes.storeDiscover);
      case _storeChat:
        break;
      case _storeOffers:
        context.push(AppRoutes.storeProposals);
      case _storeDrafts:
        context.push(AppRoutes.storeDrafts);
    }
  }
}
