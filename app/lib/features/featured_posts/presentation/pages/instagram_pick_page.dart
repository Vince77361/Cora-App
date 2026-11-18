import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_featured_post_tokens.dart';
import '../../../../core/theme/cora_shadows.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_network_photo.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../../../discovery/presentation/widgets/discovery_toast.dart';
import '../../domain/featured_post.dart';
import '../featured_posts_text.dart';
import '../viewmodels/instagram_pick_view_model.dart';
import '../widgets/featured_post_close_header.dart';

/// 인스타에서 고르기(캔버스 M19G6Pick). 연동한 계정의 게시물을 세 칸 격자로 보여 주고, 고른 차례대로 번호가 붙는다.
/// `대표 게시물에 추가`를 누르면 고른 게시물을 서버로 가져와 초안으로 돌려주고(저장은 대표 게시물 화면의 `저장하기`)
/// 닫힌다. [replace]이면 `인스타에서 골라 교체`라서 한 개만 고른다.
class InstagramPickPage extends ConsumerStatefulWidget {
  const InstagramPickPage({super.key, this.replace = false});

  final bool replace;

  @override
  ConsumerState<InstagramPickPage> createState() => _InstagramPickPageState();
}

class _InstagramPickPageState extends ConsumerState<InstagramPickPage> {
  /// 한도를 넘게 눌렀을 때 3초 뜨는 안내. 새로 누를 때마다 [_toastTick]이 올라 3초를 다시 센다.
  String? _toast;
  int _toastTick = 0;

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.creatorFeaturedPosts);
    }
  }

  void _tap(String id, int limit) {
    final result = ref
        .read(instagramPickViewModelProvider(widget.replace).notifier)
        .toggle(id);
    if (result == InstagramPickToggle.limitReached) {
      setState(() {
        _toast = FeaturedPostsText.pickLimit(limit);
        _toastTick++;
      });
    } else if (_toast != null) {
      setState(() => _toast = null);
    }
  }

  Future<void> _add() async {
    final drafts = await ref
        .read(instagramPickViewModelProvider(widget.replace).notifier)
        .importPicked();
    if (drafts != null && mounted) context.pop(drafts);
  }

  @override
  Widget build(BuildContext context) {
    final provider = instagramPickViewModelProvider(widget.replace);
    final async = ref.watch(provider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FeaturedPostCloseHeader(
              title: FeaturedPostsText.pickTitle,
              onClose: _close,
            ),
            Expanded(
              child: switch (async) {
                AsyncData(:final value) => Stack(
                  children: [
                    _Content(
                      state: value,
                      onTap: (id) => _tap(id, value.limit),
                      onAdd: _add,
                    ),
                    if (_toast != null)
                      Positioned(
                        left: 10,
                        right: 10,
                        top: 12,
                        child: DiscoveryToastBanner(
                          key: ValueKey(_toastTick),
                          message: _toast!,
                          onDismiss: () {
                            if (mounted) setState(() => _toast = null);
                          },
                        ),
                      ),
                  ],
                ),
                AsyncError() => CoraStateView.loadFailed(
                  title: FeaturedPostsText.pickLoadFailed,
                  onRetry: () => ref.invalidate(provider),
                ),
                _ => const CoraStateView.loading(),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.state,
    required this.onTap,
    required this.onAdd,
  });

  final InstagramPickState state;
  final ValueChanged<String> onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = math.max(32.0, MediaQuery.viewPaddingOf(context).bottom);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
                  child: Text(
                    '${FeaturedPostsText.pickOwner(state.handle)} '
                    '${FeaturedPostsText.pickRule}',
                    style: CoraTextStyles.bodySmall.copyWith(
                      height: 1.6,
                      color: c.textSecondary,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                sliver: SliverGrid.builder(
                  itemCount: state.posts.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                    mainAxisExtent: 128,
                  ),
                  itemBuilder: (context, i) {
                    final post = state.posts[i];
                    final order = state.picked.indexOf(post.id);
                    return _PickCell(
                      post: post,
                      order: order < 0 ? null : order + 1,
                      imported: state.imported.contains(post.id),
                      onTap: () => onTap(post.id),
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: c.background,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(CoraRadius.xxl),
            ),
            boxShadow: CoraShadows.sheet,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 18, 16, bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        FeaturedPostsText.pickCounter(
                          state.picked.length,
                          state.limit,
                        ),
                        style: CoraTextStyles.buttonMedium.copyWith(
                          color: c.text,
                        ),
                      ),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            FeaturedPostsText.pickOrderHint,
                            textAlign: TextAlign.end,
                            style: CoraTextStyles.fieldLabel.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        state.error!,
                        textAlign: TextAlign.center,
                        style: CoraTextStyles.meta.copyWith(color: c.text),
                      ),
                    ),
                  ),
                CoraPrimaryButton(
                  label: FeaturedPostsText.pickAdd,
                  look: CoraPrimaryButtonLook.accent,
                  onPressed: state.picked.isEmpty || state.busy ? null : onAdd,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 격자 한 칸: 사진 위 오른쪽 위에 번호 동그라미 24. 고른 것은 라임에 번호, 안 고른 것은 빈 동그라미다. 이미 가져온 칸과
/// 영상 한도(60초·100MB)를 넘는 칸은 흐리게 덮고 표지를 달아 고를 수 없다(캔버스 밖).
class _PickCell extends StatelessWidget {
  const _PickCell({
    required this.post,
    required this.order,
    required this.imported,
    required this.onTap,
  });

  final InstagramPost post;

  /// 고른 차례(1부터). 안 골랐으면 null.
  final int? order;
  final bool imported;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final blocked = imported || !post.importable;
    final picked = order != null;
    return Semantics(
      container: true,
      button: true,
      selected: picked,
      enabled: !blocked,
      label: post.caption ?? '',
      onTap: blocked ? null : onTap,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: blocked ? null : onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CoraNetworkPhoto(
                url: post.thumbnailUrl,
                background: c.avatarPlaceholder,
              ),
              if (blocked) ...[
                const ColoredBox(color: CoraFeaturedPostTokens.importedDim),
                Positioned(
                  right: 8,
                  top: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.photoChip,
                      borderRadius: BorderRadius.circular(CoraRadius.pill),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Text(
                        imported
                            ? FeaturedPostsText.alreadyImported
                            : FeaturedPostsText.notImportable,
                        style: CoraTextStyles.caption.copyWith(
                          fontSize: 11,
                          color: c.onPhotoChip,
                        ),
                      ),
                    ),
                  ),
                ),
              ] else
                Positioned(
                  right: 8,
                  top: 8,
                  child: picked
                      ? DecoratedBox(
                          decoration: BoxDecoration(
                            color: c.accent,
                            shape: BoxShape.circle,
                            // 캔버스 `box-shadow: 0 0 0 2px rgba(255,255,255,.9)`.
                            boxShadow: const [
                              BoxShadow(
                                color: CoraFeaturedPostTokens.pickRing,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: SizedBox.square(
                            dimension: 24,
                            child: Center(
                              child: Text(
                                '$order',
                                style: CoraTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: c.onAccent,
                                ),
                              ),
                            ),
                          ),
                        )
                      : const DecoratedBox(
                          decoration: BoxDecoration(
                            color: CoraFeaturedPostTokens.pickIdleFill,
                            shape: BoxShape.circle,
                            border: Border.fromBorderSide(
                              BorderSide(
                                color: CoraFeaturedPostTokens.pickRing,
                                width: 2,
                              ),
                            ),
                          ),
                          child: SizedBox.square(dimension: 24),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
