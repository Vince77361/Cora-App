import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/navigation/cora_hero_tag.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_info_tile.dart';
import '../../../../core/ui/cora_network_photo.dart';
import '../../../../core/ui/cora_pill_button.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../../../../core/ui/cora_step_header.dart';
import '../../../offer_terms/presentation/offer_terms_text.dart';
import '../../domain/store_detail.dart';
import '../store_browse_text.dart';
import '../viewmodels/store_detail_view_model.dart';
import '../widgets/photo_overlays.dart';

/// D2 가게 오퍼 상세(NStoreView / DarkNStoreView). 크리에이터가 가게의 모집 글(가게 정보와 기본
/// 오퍼 조건)을 보고 지원하거나 지원을 취소한다. 사장님이 오퍼를 보냈으면 받은 오퍼로 안내한다.
class StoreDetailPage extends ConsumerWidget {
  const StoreDetailPage({super.key, required this.storeId});

  final String storeId;

  static const badge = '소상공인';
  static const rewardLabel = '보상';
  static const shootingLabel = '찍기 좋은 시간';
  static const conditionLabel = '지원 조건';
  static const conditionValue = '팔로워 무관';
  static const storeInfo = '가게 정보';
  static const apply = '지원하기';
  static const applied = '지원했어요. 사장님이 고르면 오퍼가 도착해요.';
  static const cancel = '취소';
  static const offered = '오퍼가 도착했어요.';
  static const viewOffer = '오퍼 보기';
  static const actionFailed = '처리하지 못했어요. 다시 시도해 주세요.';
  static const loadFailed = '가게를 불러오지 못했어요.';

  static String headline(StoreDetail d) =>
      '${formatLabel(d.summary.defaultTerms.format)} 1편을 만들어 줄\n크리에이터를 찾아요';

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.creator);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = storeDetailViewModelProvider(storeId);
    final async = ref.watch(provider);
    return Scaffold(
      body: switch (async) {
        AsyncData(:final value) => _Loaded(
          state: value,
          onBack: () => _back(context),
          onApply: ref.read(provider.notifier).apply,
          onCancel: ref.read(provider.notifier).cancelApplication,
          onStoreInfo: () => context.push(
            AppRoutes.creatorComingSoon(storeInfo),
            extra: AppRoutes.stacked,
          ),
          onViewOffer: () =>
              context.push(AppRoutes.creatorOffers, extra: AppRoutes.stacked),
        ),
        AsyncError() => SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
                  child: CoraBackButton(onPressed: () => _back(context)),
                ),
              ),
              Expanded(
                child: CoraStateView.loadFailed(
                  title: loadFailed,
                  onRetry: () => ref.invalidate(provider),
                ),
              ),
            ],
          ),
        ),
        _ => const CoraStateView.loading(),
      },
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({
    required this.state,
    required this.onBack,
    required this.onApply,
    required this.onCancel,
    required this.onStoreInfo,
    required this.onViewOffer,
  });

  final StoreDetailState state;
  final VoidCallback onBack;
  final VoidCallback onApply;
  final VoidCallback onCancel;
  final VoidCallback onStoreInfo;
  final VoidCallback onViewOffer;

  @override
  Widget build(BuildContext context) {
    final detail = state.detail;
    final store = detail.summary;
    final c = context.colors;
    final top = MediaQuery.paddingOf(context).top;
    final line = store.categoryAndNeighborhood;
    final reward = detailReward(store.defaultTerms);
    final shooting = (detail.bestShootingTime ?? '').trim();
    final intro = (detail.intro ?? '').trim();
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Stack(
              children: [
                // 사진(높이 280). 흰 면이 24 겹쳐 올라온다.
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: 280,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Semantics(
                        image: true,
                        label: '${store.name} 대표 사진',
                        child: ExcludeSemantics(
                          child: Hero(
                            tag: CoraHeroTag.of('store', store.id),
                            child: CoraNetworkPhoto(
                              url: store.coverPhotoUrl,
                              alignment: const Alignment(0, -0.1),
                              background: c.coverPlaceholder,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 160,
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
                      Positioned(
                        left: 10,
                        top: top + 10,
                        child: PhotoBackButton(onPressed: onBack),
                      ),
                      Positioned(
                        right: 14,
                        top: top + 18,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 8,
                          children: [
                            if (state.inOtherProvince)
                              PhotoChip(store.regionSido!),
                            const PhotoChip(StoreDetailPage.badge),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 40,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (line != null)
                              Text(
                                line,
                                style: CoraTextStyles.meta.copyWith(
                                  color: c.onPhotoSecondary,
                                ),
                              ),
                            const SizedBox(height: 2),
                            Text(
                              store.name,
                              style: CoraTextStyles.title.copyWith(
                                letterSpacing: -1.04,
                                height: 1.448,
                                color: c.onPhoto,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 256),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.background,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(CoraRadius.xl),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              StoreDetailPage.headline(detail),
                              style: CoraTextStyles.title.copyWith(
                                fontSize: 22,
                                letterSpacing: -0.88,
                                height: 1.35,
                                color: c.text,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _RewardTile(title: reward.title, note: reward.note),
                            const SizedBox(height: 8),
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                spacing: 8,
                                children: [
                                  Expanded(
                                    child: _ValueTile(
                                      label: StoreDetailPage.shootingLabel,
                                      value: shooting.isEmpty
                                          ? CoraInfoTile.emptyValue
                                          : shooting,
                                    ),
                                  ),
                                  const Expanded(
                                    child: _ValueTile(
                                      label: StoreDetailPage.conditionLabel,
                                      value: StoreDetailPage.conditionValue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (intro.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Text(
                                intro,
                                style: CoraTextStyles.bodySmall.copyWith(
                                  height: 1.6,
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
              ],
            ),
          ),
        ),
        _BottomBar(
          state: state,
          onApply: onApply,
          onCancel: onCancel,
          onStoreInfo: onStoreInfo,
          onViewOffer: onViewOffer,
        ),
      ],
    );
  }
}

/// 보상 칸(캔버스 첫 칸, 두 칸 너비): 반경 20, 패딩 14, 라벨 12, 값 17/700, 둘째 줄 13.
class _RewardTile extends StatelessWidget {
  const _RewardTile({required this.title, required this.note});

  final String title;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(CoraRadius.field),
      ),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                StoreDetailPage.rewardLabel,
                style: CoraTextStyles.fieldLabel.copyWith(color: c.text),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: CoraTextStyles.bodyLarge.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: c.text,
                ),
              ),
              if (note != null) ...[
                const SizedBox(height: 2),
                Text(
                  note!,
                  style: CoraTextStyles.meta.copyWith(
                    fontWeight: FontWeight.w400,
                    color: c.text,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 작은 항목 칸(`찍기 좋은 시간`, `지원 조건`): 반경 18, 패딩 12/14, 라벨 12 보조색, 값 15/500, 사이 2.
class _ValueTile extends StatelessWidget {
  const _ValueTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
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
              style: CoraTextStyles.fieldLabel.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: CoraTextStyles.buttonMedium.copyWith(color: c.text),
            ),
          ],
        ),
      ),
    );
  }
}

/// 아래 고정 막대: 패딩 12/16/28. 지원 상태에 따라 버튼 두 개, 지원했어요 칸, 오퍼가 도착했어요 칸.
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.state,
    required this.onApply,
    required this.onCancel,
    required this.onStoreInfo,
    required this.onViewOffer,
  });

  final StoreDetailState state;
  final VoidCallback onApply;
  final VoidCallback onCancel;
  final VoidCallback onStoreInfo;
  final VoidCallback onViewOffer;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final status = state.detail.myApplicationStatus;
    return ColoredBox(
      color: c.background,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.failed)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    StoreDetailPage.actionFailed,
                    textAlign: TextAlign.center,
                    style: CoraTextStyles.meta.copyWith(color: c.text),
                  ),
                ),
              ),
            switch (status) {
              MyApplicationStatus.none => Row(
                spacing: 8,
                children: [
                  Expanded(
                    flex: 10,
                    child: CoraPillButton(
                      label: StoreDetailPage.storeInfo,
                      onPressed: onStoreInfo,
                      background: c.surface,
                      foreground: c.text,
                      textStyle: CoraTextStyles.buttonMedium,
                    ),
                  ),
                  Expanded(
                    flex: 16,
                    child: CoraPillButton(
                      label: StoreDetailPage.apply,
                      onPressed: state.busy ? null : onApply,
                      // 지원하기는 라이트·다크 모두 라임이다(캔버스).
                      background: c.accent,
                      foreground: c.onAccent,
                      textStyle: CoraTextStyles.button,
                    ),
                  ),
                ],
              ),
              MyApplicationStatus.applied => _StatusPanel(
                message: StoreDetailPage.applied,
                actionLabel: StoreDetailPage.cancel,
                onAction: state.busy ? null : onCancel,
              ),
              MyApplicationStatus.offered => _StatusPanel(
                message: StoreDetailPage.offered,
                actionLabel: StoreDetailPage.viewOffer,
                onAction: onViewOffer,
              ),
            },
          ],
        ),
      ),
    );
  }
}

/// 상태 안내 칸(캔버스 `role="status"`): 패딩 14/18, 반경 20, 안내 14 줄 높이 1.5, 오른쪽 작은 버튼(높이 40).
/// 다크는 칸이 배경과 같은 색이고 글자가 흰색이며 버튼이 반투명 흰색이다(캔버스 그대로).
class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final panel = dark ? c.background : c.surface;
    final text = dark ? c.onPhoto : c.text;
    final button = dark ? c.onPhoto.withValues(alpha: 0.14) : c.background;
    return Semantics(
      container: true,
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(CoraRadius.field),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            spacing: 12,
            children: [
              Expanded(
                child: Text(
                  message,
                  style: CoraTextStyles.bodySmall.copyWith(
                    height: 1.5,
                    color: text,
                  ),
                ),
              ),
              CoraPillButton(
                label: actionLabel,
                onPressed: onAction,
                background: button,
                foreground: text,
                textStyle: CoraTextStyles.label,
                height: 40,
                horizontalPadding: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
