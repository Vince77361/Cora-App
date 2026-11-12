import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/navigation/cora_hero_tag.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_bottom_nav.dart';
import '../../../../core/ui/cora_network_photo.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../../../offer_terms/presentation/offer_terms_text.dart';
import '../../domain/store_summary.dart';
import '../viewmodels/store_list_view_model.dart';
import '../widgets/creator_bottom_nav.dart';
import '../widgets/photo_overlays.dart';

/// 크리에이터 홈. 공개된 가게를 사진 카드 목록으로 보여 주고, 누르면 가게 상세(D2)로 간다.
/// 캔버스에 없는 화면이라 D2의 사진 카드를 줄여 쓴다(4번 계획이 스와이프 발견 화면으로 바꾼다).
class StoreListPage extends ConsumerWidget {
  const StoreListPage({super.key});

  static const title = '공개된 가게';
  static const empty = '아직 공개된 가게가 없어요.';
  static const loadFailed = '가게를 불러오지 못했어요.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final list = ref.watch(storeListViewModelProvider);
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
                      child: Text(
                        title,
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
                Expanded(
                  child: switch (list) {
                    AsyncData(:final value) => RefreshIndicator(
                      onRefresh: ref
                          .read(storeListViewModelProvider.notifier)
                          .refresh,
                      child: value.stores.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(top: 12),
                              children: const [
                                CoraStateView.empty(title: empty),
                              ],
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                0,
                                12,
                                112,
                              ),
                              itemCount: value.stores.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, i) => _StoreCard(
                                store: value.stores[i],
                                otherProvince: value.inOtherProvince(
                                  value.stores[i],
                                ),
                              ),
                            ),
                    ),
                    AsyncError() => CoraStateView.loadFailed(
                      title: loadFailed,
                      onRetry: () => ref.invalidate(storeListViewModelProvider),
                    ),
                    _ => const CoraStateView.loading(),
                  },
                ),
              ],
            ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: CreatorBottomNav(currentIndex: CoraCreatorNavItems.discover),
          ),
        ],
      ),
    );
  }
}

/// 가게 한 곳: 사진 위에 `{업종}, {동네}`, 이름, 보상 한 줄. 다른 시·도면 사진 위에 시·도 표지.
class _StoreCard extends StatelessWidget {
  const _StoreCard({required this.store, required this.otherProvince});

  final StoreSummary store;
  final bool otherProvince;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final line = store.categoryAndNeighborhood;
    final reward = rewardHeadline(store.defaultTerms);
    return Semantics(
      container: true,
      button: true,
      label: [store.name, ?line, reward].join(', '),
      onTap: () => _open(context),
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: () => _open(context),
          child: SizedBox(
            height: 220,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(CoraRadius.xl),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: CoraHeroTag.of('store', store.id),
                    child: CoraNetworkPhoto(
                      url: store.coverPhotoUrl,
                      // CSS object-position: 50% 45%.
                      alignment: const Alignment(0, -0.1),
                      background: c.coverPlaceholder,
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 130,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            c.photoScrim.withValues(alpha: 0),
                            c.photoScrim.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (otherProvince)
                    Positioned(
                      left: 14,
                      top: 14,
                      child: PhotoChip(store.regionSido!),
                    ),
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (line != null)
                          Text(
                            line,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CoraTextStyles.meta.copyWith(
                              color: c.onPhotoSecondary,
                            ),
                          ),
                        Text(
                          store.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CoraTextStyles.title.copyWith(
                            fontSize: 22,
                            letterSpacing: -0.88,
                            height: 1.448,
                            color: c.onPhoto,
                          ),
                        ),
                        Text(
                          reward,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CoraTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: c.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context) =>
      context.push(AppRoutes.creatorStore(store.id));
}
