import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shadows.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/time/clock.dart';
import '../../../../core/ui/cora_bottom_nav.dart';
import '../../../../core/ui/cora_error_view.dart';
import '../../../../core/ui/cora_list_row.dart';
import '../../../../core/ui/cora_network_photo.dart';
import '../../../../core/ui/cora_pill_button.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../../core/ui/cora_primary_button.dart';
import '../../../collaboration/presentation/collaboration_text.dart';
import '../../../collaboration/presentation/viewmodels/collaboration_list_view_model.dart';
import '../../../offer_terms/presentation/offer_terms_text.dart';
import '../../../store_browse/presentation/widgets/creator_bottom_nav.dart';
import '../../../store_browse/presentation/widgets/photo_overlays.dart';
import '../../domain/received_offer.dart';
import '../received_offers_text.dart';
import '../viewmodels/received_offers_view_model.dart';

/// A6 받은 오퍼(NOfferInbox / DarkNOfferInbox). 새 오퍼는 도착한 순서대로 한 장씩 보여 주고,
/// 거절하면 30초 동안 되돌릴 수 있다. 수락한 오퍼는 `진행 중` 탭에 모인다.
class ReceivedOffersPage extends ConsumerWidget {
  const ReceivedOffersPage({super.key});

  static const title = '받은 오퍼';
  static const activeTab = '진행 중';
  static const badge = '소상공인';
  static const decline = '거절';
  static const accept = '수락하기';
  static const declinedTitle = '거절했어요.';
  static const declinedBody = '가게에는 정중한 거절 알림만 가요. 다음 오퍼를 보여드릴게요.';
  static const undo = '되돌리기';
  static const nextOffer = '다음 오퍼 보기';
  static const acceptedTitle = '수락했어요.';
  static const acceptedBody = '사장님이 결제하면 알려드릴게요.';
  static const confirm = '확인';
  static const noNewOffers = '새 오퍼가 없어요. 가게에 지원하면 오퍼가 도착해요.';
  static const noActive = '아직 진행 중인 협업이 없어요.';
  static const activeLoadFailed = '진행 중인 협업을 불러오지 못했어요.';
  static const alreadyHandled = '이미 처리된 오퍼예요.';
  static const actionFailed = '처리하지 못했어요. 다시 시도해 주세요.';
  static const loadFailed = '받은 오퍼를 불러오지 못했어요.';

  static String newTab(int count) => '새 오퍼 $count';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final async = ref.watch(receivedOffersViewModelProvider);
    final vm = ref.read(receivedOffersViewModelProvider.notifier);
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: switch (async) {
              AsyncData(:final value) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(
                    newCount: value.waitingCount,
                    tab: value.tab,
                    onTab: vm.selectTab,
                  ),
                  Expanded(
                    child: value.tab == ReceivedOffersTab.newOffers
                        ? _NewTab(state: value, vm: vm)
                        : const _ActiveTab(),
                  ),
                ],
              ),
              AsyncError() => CoraErrorView(
                message: loadFailed,
                onRetry: () => ref.invalidate(receivedOffersViewModelProvider),
              ),
              _ => ColoredBox(
                color: c.background,
                child: const SizedBox.expand(),
              ),
            },
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: CreatorBottomNav(currentIndex: CoraCreatorNavItems.collab),
          ),
        ],
      ),
    );
  }
}

/// 머리: 높이 64, 좌우 16. 왼쪽에 22/900 제목, 오른쪽에 알약 두 개짜리 탭(패딩 4, 사이 2).
class _Header extends StatelessWidget {
  const _Header({
    required this.newCount,
    required this.tab,
    required this.onTab,
  });

  final int newCount;
  final ReceivedOffersTab tab;
  final ValueChanged<ReceivedOffersTab> onTab;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                ReceivedOffersPage.title,
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
            const SizedBox(width: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(CoraRadius.pill),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 2,
                  children: [
                    _TabPill(
                      label: ReceivedOffersPage.newTab(newCount),
                      selected: tab == ReceivedOffersTab.newOffers,
                      onTap: () => onTab(ReceivedOffersTab.newOffers),
                    ),
                    _TabPill(
                      label: ReceivedOffersPage.activeTab,
                      selected: tab == ReceivedOffersTab.active,
                      onTap: () => onTab(ReceivedOffersTab.active),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 탭 하나: 패딩 8/14, 13/500. 고른 탭은 `stepPill` 바탕에 작은 그림자(라이트 흰색, 다크 밝은 회색).
class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: selected ? c.stepPill : const Color(0x00000000),
              borderRadius: BorderRadius.circular(CoraRadius.pill),
              boxShadow: selected
                  ? CoraShadows.stepPill(c.stepPillShadow)
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Text(
                label,
                maxLines: 1,
                style: CoraTextStyles.label.copyWith(
                  color: selected ? c.onStepPill : c.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 새 오퍼 탭: 카드 영역은 좌우 12, 아래 100(하단 메뉴 위)이다.
class _NewTab extends StatelessWidget {
  const _NewTab({required this.state, required this.vm});

  final ReceivedOffersState state;
  final ReceivedOffersViewModel vm;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final current = state.current;
    final notice = switch (state.notice) {
      ReceivedOffersNotice.alreadyHandled => ReceivedOffersPage.alreadyHandled,
      ReceivedOffersNotice.failed => ReceivedOffersPage.actionFailed,
      null => null,
    };
    final Widget body;
    if (state.accepted) {
      body = _MessagePanel(
        title: ReceivedOffersPage.acceptedTitle,
        body: ReceivedOffersPage.acceptedBody,
        children: [
          const SizedBox(height: 14),
          CoraPrimaryButton(
            label: ReceivedOffersPage.confirm,
            onPressed: vm.confirmAccepted,
          ),
        ],
      );
    } else if (current == null) {
      body = const _MessagePanel(body: ReceivedOffersPage.noNewOffers);
    } else if (current.canUndoDecline) {
      body = _MessagePanel(
        title: ReceivedOffersPage.declinedTitle,
        body: ReceivedOffersPage.declinedBody,
        children: [
          const SizedBox(height: 6),
          _TextAction(
            label: ReceivedOffersPage.undo,
            underline: true,
            onTap: state.busy ? null : vm.undoDecline,
          ),
          _TextAction(label: ReceivedOffersPage.nextOffer, onTap: vm.nextOffer),
        ],
      );
    } else {
      body = _OfferCard(
        offer: current,
        busy: state.busy,
        onDecline: vm.decline,
        onAccept: vm.accept,
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (notice != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  notice,
                  textAlign: TextAlign.center,
                  style: CoraTextStyles.meta.copyWith(color: c.text),
                ),
              ),
            ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// 오퍼 카드 한 장(캔버스 `article`): 반경 28, 사진 위에 어두운 그라데이션, 왼쪽 위 표지, 아래에
/// 가게·제목·보상·설명·꼬리표, 맨 아래 `거절` / `수락하기`.
class _OfferCard extends ConsumerWidget {
  const _OfferCard({
    required this.offer,
    required this.busy,
    required this.onDecline,
    required this.onAccept,
  });

  final ReceivedOffer offer;
  final bool busy;
  final VoidCallback onDecline;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final now = ref.watch(clockProvider).now();
    final store = offer.store;
    final neighborhood = (store.neighborhood ?? '').trim();
    final storeLine = neighborhood.isEmpty
        ? store.name
        : '${store.name}, $neighborhood';
    final muted = CoraTextStyles.bodySmall.copyWith(
      fontWeight: FontWeight.w500,
      color: c.onPhotoSecondary,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(CoraRadius.xxl),
        boxShadow: CoraShadows.offerCard,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(CoraRadius.xxl),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Semantics(
              image: true,
              label: '${store.name}의 대표 사진',
              child: ExcludeSemantics(
                child: CoraNetworkPhoto(
                  url: store.coverPhotoUrl,
                  alignment: const Alignment(0, -0.1),
                  background: c.coverPlaceholder,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 480,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      c.photoScrim.withValues(alpha: 0),
                      c.photoScrim.withValues(alpha: 0.6),
                      c.photoScrim.withValues(alpha: 0.9),
                    ],
                    stops: const [0, 0.4, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              top: 14,
              child: PhotoChip(
                '${ReceivedOffersPage.badge} · ${arrivedAgo(offer.receivedAt, now)}',
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 92,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                spacing: 10,
                children: [
                  Text(storeLine, style: muted),
                  Text(
                    '${formatLabel(offer.terms.format)} 1편을\n부탁했어요',
                    style: CoraTextStyles.display.copyWith(
                      fontSize: 30,
                      letterSpacing: -1.5,
                      height: 1.15,
                      color: c.onPhoto,
                    ),
                  ),
                  Text(
                    rewardHeadline(offer.terms),
                    style: CoraTextStyles.bodyLarge.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: c.accent,
                    ),
                  ),
                  Text(
                    offerDescription(offer.terms, offer.storeIntro),
                    style: muted.copyWith(
                      fontWeight: FontWeight.w400,
                      height: 1.55,
                    ),
                  ),
                  Wrap(
                    spacing: 12,
                    children: [
                      for (final tag in offerTags(offer))
                        Text(tag, style: muted),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Row(
                spacing: 10,
                children: [
                  Expanded(
                    child: CoraPillButton(
                      label: ReceivedOffersPage.decline,
                      onPressed: busy ? null : onDecline,
                      background: c.onPhoto.withValues(alpha: 0.18),
                      foreground: c.onPhoto,
                      textStyle: CoraTextStyles.bodyLarge,
                    ),
                  ),
                  Expanded(
                    child: CoraPillButton(
                      label: ReceivedOffersPage.accept,
                      onPressed: busy ? null : onAccept,
                      background: c.accent,
                      foreground: c.onAccent,
                      textStyle: CoraTextStyles.button,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 카드 자리에 놓이는 안내 칸(캔버스 거절 후 칸): 반경 28, `surface` 바탕, 좌우 28, 가운데 정렬,
/// 제목 24/900, 설명 15 줄 높이 1.6 보조색. 캔버스에는 거절 후 칸만 있고, 수락 후와 빈 목록은 같은 모양을 쓴다.
class _MessagePanel extends StatelessWidget {
  const _MessagePanel({
    this.title,
    required this.body,
    this.children = const [],
  });

  final String? title;
  final String body;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(CoraRadius.xxl),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 10,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: CoraTextStyles.title.copyWith(
                      fontSize: 24,
                      letterSpacing: -0.96,
                      height: 1.448,
                      color: c.text,
                    ),
                  ),
                Text(
                  body,
                  style: CoraTextStyles.body.copyWith(color: c.textSecondary),
                ),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 안내 칸 안의 글자 버튼(캔버스 `되돌리기`): 높이 44, 14/500, 왼쪽 정렬.
class _TextAction extends StatelessWidget {
  const _TextAction({
    required this.label,
    required this.onTap,
    this.underline = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool underline;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        container: true,
        button: true,
        enabled: onTap != null,
        label: label,
        onTap: onTap,
        child: ExcludeSemantics(
          child: CoraPressable(
            onTap: onTap,
            child: SizedBox(
              height: 44,
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: 1,
                child: Text(
                  label,
                  style: CoraTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                    color: underline ? c.text : c.textSecondary,
                    decoration: underline ? TextDecoration.underline : null,
                    decorationColor: c.text,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 진행 중 탭: 수락한 오퍼가 만든 협업의 가게 줄. 설명은 단계에 따라 `결제를 기다리고 있어요` /
/// `방문하고 촬영해 주세요 · {기한}까지` / `집계 중 · {n}일 남음`이고, 누르면 협업 진행(A7)이 열린다.
class _ActiveTab extends ConsumerWidget {
  const _ActiveTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(collaborationListViewModelProvider);
    final now = ref.watch(clockProvider).now();
    return switch (async) {
      AsyncData(:final value) when value.isEmpty => const Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, 100),
        child: _MessagePanel(body: ReceivedOffersPage.noActive),
      ),
      AsyncData(:final value) => ListView(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 112),
        children: [
          for (final collaboration in value)
            CoraListRow(
              photoUrl: collaboration.counterpartPhotoUrl,
              title: collaboration.counterpartName,
              subtitle: activeRowSubtitle(collaboration, now),
              onTap: () async {
                await context.push(
                  AppRoutes.creatorCollaboration(collaboration.id),
                );
                // A7에서 제출하거나 그만두고 돌아오면 줄이 낡을 수 있다.
                ref.invalidate(collaborationListViewModelProvider);
              },
            ),
        ],
      ),
      AsyncError() => CoraErrorView(
        message: ReceivedOffersPage.activeLoadFailed,
        onRetry: () => ref.invalidate(collaborationListViewModelProvider),
      ),
      _ => const SizedBox.expand(),
    };
  }
}
