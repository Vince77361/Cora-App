import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_shadows.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/ui/cora_bottom_nav.dart';
import '../../../../core/ui/cora_network_photo.dart';
import '../../../../core/ui/cora_page_header.dart';
import '../../../../core/ui/cora_pill_button.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../../../notifications/presentation/notification_routes.dart';
import '../../../offers/presentation/pages/send_offer_page.dart';
import '../../../store_browse/presentation/widgets/photo_overlays.dart';
import '../../../store_home/domain/applicant.dart';
import '../../domain/applicant_pick.dart';
import '../applicant_picks_text.dart';
import '../viewmodels/applicant_picks_view_model.dart';

/// G2 지원자 추천 3명(NApplicants / DarkNApplicants). 지원한 크리에이터 가운데 가게와 잘 맞는 3명을 한 명씩
/// 카드로 보여 준다. `넘기기`는 다음 추천으로, `좋아요하고 오퍼`는 그 크리에이터를 받는 사람으로 한 오퍼 보내기(A5)로 간다.
class ApplicantPicksPage extends ConsumerWidget {
  const ApplicantPicksPage({super.key});

  static const explore = '탐색';
  static const skip = '넘기기';
  static const like = '좋아요하고 오퍼';
  static const allSeenTitle = '추천을 모두 봤어요.';
  static const allSeenDescription = '지원자 목록에서 나머지를 볼 수 있어요.';
  static const openList = '지원자 목록 보기';
  static const noApplicants = '아직 지원한 크리에이터가 없어요.';

  /// 캔버스에 없는 상태의 문구.
  static const loadFailed = '지원자 추천을 불러오지 못했어요.';
  static const skipFailedNotice = '넘기지 못했어요. 다시 시도해 주세요.';

  void _leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.store);
    }
  }

  /// 지원자 목록(사장님 홈의 지원자 탭)으로 간다.
  void _openList(BuildContext context) => context.go(
    '${AppRoutes.store}?${NotificationRoutes.tabParam}=${NotificationRoutes.applicantsTab}',
  );

  void _openOffer(BuildContext context, ApplicantPick pick) {
    final c = pick.creator;
    context.push(
      AppRoutes.storeOfferNew(c.userId),
      extra: SendOfferArgs(
        creator: CreatorSummary(
          userId: c.userId,
          displayName: c.displayName,
          contentFocus: c.contentFocus,
          photoUrl: c.photoUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(applicantPicksViewModelProvider);
    final vm = ref.read(applicantPicksViewModelProvider.notifier);
    final state = async.value;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CoraPageHeader(
              title: state == null ? null : picksTitle(state.totalNew),
              extent: 64,
              onBack: () => _leave(context),
              trailing: _ExploreLink(
                onTap: () => context.push(
                  AppRoutes.storeComingSoon(CoraNavItems.store[1].label),
                  extra: AppRoutes.stacked,
                ),
              ),
            ),
            Expanded(
              child: switch (async) {
                AsyncData(:final value) => _Body(
                  state: value,
                  onSkip: vm.skip,
                  onLike: (pick) => _openOffer(context, pick),
                  onOpenList: () => _openList(context),
                ),
                AsyncError() => CoraStateView.loadFailed(
                  title: loadFailed,
                  onRetry: () =>
                      ref.invalidate(applicantPicksViewModelProvider),
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

/// 머리 오른쪽의 `탐색`(13, 보조색, 안쪽 10/8).
class _ExploreLink extends StatelessWidget {
  const _ExploreLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      label: ApplicantPicksPage.explore,
      onTap: onTap,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Text(
              ApplicantPicksPage.explore,
              maxLines: 1,
              style: CoraTextStyles.label.copyWith(
                fontWeight: FontWeight.w400,
                color: c.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.state,
    required this.onSkip,
    required this.onLike,
    required this.onOpenList,
  });

  final ApplicantPicksState state;
  final VoidCallback onSkip;
  final ValueChanged<ApplicantPick> onLike;
  final VoidCallback onOpenList;

  @override
  Widget build(BuildContext context) {
    final pick = state.current;
    if (pick == null) {
      // 새 지원이 아예 없으면 그렇게 말하고, 다 넘겼으면 지원자 목록으로 안내한다.
      return state.allSeen || state.totalNew > 0
          ? CoraStateView.empty(
              title: ApplicantPicksPage.allSeenTitle,
              description: ApplicantPicksPage.allSeenDescription,
              actionLabel: ApplicantPicksPage.openList,
              onAction: onOpenList,
            )
          : const CoraStateView.empty(title: ApplicantPicksPage.noApplicants);
    }
    final c = context.colors;
    final bottom = math.max(28.0, MediaQuery.viewPaddingOf(context).bottom);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            picksIntro(totalNew: state.totalNew, picked: state.total),
            style: CoraTextStyles.meta.copyWith(color: c.textSecondary),
          ),
        ),
        const SizedBox(height: 17),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _PickCard(
              pick: pick,
              index: state.index,
              total: state.total,
            ),
          ),
        ),
        const SizedBox(height: 26),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              if (state.skipFailed)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    ApplicantPicksPage.skipFailedNotice,
                    textAlign: TextAlign.center,
                    style: CoraTextStyles.meta.copyWith(color: c.text),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 12,
                children: [
                  CoraPillButton(
                    label: ApplicantPicksPage.skip,
                    onPressed: state.busy ? null : onSkip,
                    background: c.subtleAction,
                    foreground: c.onSubtleAction,
                    textStyle: CoraTextStyles.buttonMedium,
                    height: 58,
                    horizontalPadding: 26,
                  ),
                  Flexible(
                    child: _LikeButton(
                      onTap: state.busy ? null : () => onLike(pick),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 추천 카드(모서리 28, 그림자 0 16px 40px 알파 0.14): 사진 위에 알약, 아래에 한 줄·이유·이름.
class _PickCard extends StatelessWidget {
  const _PickCard({
    required this.pick,
    required this.index,
    required this.total,
  });

  final ApplicantPick pick;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final creator = pick.creator;
    final pitch = pickPitch(pick);
    final reasons = pickReasons(pick);
    final hasPhoto = (creator.photoUrl ?? '').isNotEmpty;
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
              label: '${creator.displayName}의 대표 릴스',
              child: ExcludeSemantics(
                child: hasPhoto
                    ? CoraNetworkPhoto(
                        url: creator.photoUrl,
                        alignment: const Alignment(0, -0.4),
                        background: c.creatorPhotoPlaceholder,
                      )
                    : ColoredBox(
                        color: c.creatorPhotoPlaceholder,
                        child: Align(
                          alignment: const Alignment(0, -0.35),
                          child: Text(
                            creator.displayName.isEmpty
                                ? ''
                                : String.fromCharCodes(
                                    creator.displayName.runes.take(1),
                                  ),
                            style: CoraTextStyles.display.copyWith(
                              fontSize: 140,
                              height: 1.2,
                              color: c.onPhotoChip.withValues(alpha: 0.35),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 380,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      c.photoScrim.withValues(alpha: 0),
                      c.photoScrim.withValues(alpha: 0.55),
                      c.photoScrim.withValues(alpha: 0.86),
                    ],
                    stops: const [0, 0.45, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              top: 14,
              child: PhotoChip(picksChip(index: index, total: total)),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  // 글자를 키운 작은 폰에서도 카드 밖으로 넘치지 않게 안쪽을 스크롤로 둔다.
                  child: SingleChildScrollView(
                    reverse: true,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 8,
                      children: [
                        if (pitch != null)
                          Text(
                            pitch,
                            style: CoraTextStyles.title.copyWith(
                              letterSpacing: -1.3,
                              height: 1.2,
                              color: c.onPhoto,
                            ),
                          ),
                        if (reasons != null)
                          Text(
                            reasons,
                            style: CoraTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                              color: c.onPhotoSecondary,
                            ),
                          ),
                        Text(
                          pickMeta(pick),
                          style: CoraTextStyles.meta.copyWith(
                            fontWeight: FontWeight.w400,
                            color: c.onPhotoSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `좋아요하고 오퍼`: 라임 알약(높이 58, 좌우 30), 하트 20과 글자 사이 8.
class _LikeButton extends StatelessWidget {
  const _LikeButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      enabled: onTap != null,
      label: ApplicantPicksPage.like,
      onTap: onTap,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.accent,
              borderRadius: BorderRadius.circular(CoraRadius.pill),
            ),
            child: SizedBox(
              height: 58,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 8,
                    children: [
                      CustomPaint(
                        size: const Size.square(20),
                        painter: _HeartPainter(c.onAccent),
                      ),
                      Text(
                        ApplicantPicksPage.like,
                        maxLines: 1,
                        style: CoraTextStyles.button.copyWith(
                          color: c.onAccent,
                        ),
                      ),
                    ],
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

/// 캔버스의 하트 `M12 20.5s-7.5-4.6-7.5-10.4A4.3 4.3 0 0 1 12 7.4a4.3 4.3 0 0 1 7.5 2.7c0 5.8-7.5 10.4-7.5 10.4z`
/// (24 x 24 칸)를 채운다.
class _HeartPainter extends CustomPainter {
  const _HeartPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    final path = Path()
      ..moveTo(12 * k, 20.5 * k)
      ..cubicTo(12 * k, 20.5 * k, 4.5 * k, 15.9 * k, 4.5 * k, 10.1 * k)
      ..arcToPoint(
        Offset(12 * k, 7.4 * k),
        radius: Radius.circular(4.3 * k),
        clockwise: true,
      )
      ..arcToPoint(
        Offset(19.5 * k, 10.1 * k),
        radius: Radius.circular(4.3 * k),
        clockwise: true,
      )
      ..cubicTo(19.5 * k, 15.9 * k, 12 * k, 20.5 * k, 12 * k, 20.5 * k)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_HeartPainter old) => old.color != color;
}
