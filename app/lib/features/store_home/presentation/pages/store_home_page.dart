import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/cora_colors.dart';
import '../../../../core/theme/cora_shapes.dart';
import '../../../../core/theme/cora_text_styles.dart';
import '../../../../core/time/clock.dart';
import '../../../../core/ui/cora_bottom_nav.dart';
import '../../../../core/ui/cora_network_photo.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../../core/ui/cora_state_view.dart';
import '../../../applicant_picks/domain/applicant_pick.dart';
import '../../../notifications/presentation/viewmodels/unread_count_view_model.dart';
import '../../../notifications/presentation/widgets/notification_bell.dart';
import '../../../offers/presentation/pages/send_offer_page.dart';
import '../../../store_onboarding/presentation/viewmodels/my_store_view_model.dart';
import '../../../trial_compare/domain/trial_compare_repository.dart';
import '../../../trial_compare/domain/trial_info.dart';
import '../../domain/applicant.dart';
import '../store_home_text.dart';
import '../viewmodels/store_home_picks_view_model.dart';
import '../viewmodels/store_home_view_model.dart';
import '../widgets/browse_all_card.dart';
import '../widgets/recommended_picks.dart';
import '../widgets/recruit_box.dart';

/// 사장님 첫 화면(M19G4Applied·M19G4Empty / DarkM19G4*). 머리, `크리에이터 모집` 상자, 조건부 체험단 줄,
/// `추천 3명`, `전체 둘러보기`. 아래로 당기면 숫자와 추천을 함께 새로 읽는다.
class StoreHomePage extends ConsumerStatefulWidget {
  const StoreHomePage({super.key});

  static const title = '사장님 홈';
  static const storePage = '가게 페이지';
  static const compareBanner = '체험단 계약이 한 달 남았어요 · 비교 보기';
  static const hintBanner = '체험단 계약 정보를 넣으면 비교해 드려요.';

  /// 추천 제목 아래 안내. 지원자 중에서 뽑았을 때와 전체에서 뽑았을 때가 다르다.
  static String appliedIntro({required int applied, required int picked}) =>
      '지원한 $applied명 중 가게와 잘 맞는 $picked명이에요.';
  static String allIntro({required int picked}) =>
      'Cora 크리에이터 중 가게와 잘 맞는 $picked명이에요.';

  /// 캔버스에 없는 상태의 문구.
  static const loadFailed = '사장님 홈을 불러오지 못했어요.';

  /// 하단 메뉴 항목의 자리(`CoraNavItems.store`의 순서).
  static const navHome = 0;
  static const navFind = 1;
  static const navChat = 2;
  static const navOffers = 3;
  static const navDrafts = 4;

  /// 안내를 보여 주는 시간.
  static const noticeFor = Duration(milliseconds: 2500);

  @override
  ConsumerState<StoreHomePage> createState() => _StoreHomePageState();
}

class _StoreHomePageState extends ConsumerState<StoreHomePage> {
  Timer? _noticeTimer;
  final _scroll = ScrollController();

  @override
  void dispose() {
    _noticeTimer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  /// 알림함에서 돌아왔을 때. 알림함에서 결제하거나 취소를 요청했을 수 있어서 홈을 서버에서 다시 읽는다.
  void _onBellReturn(Object? result) {
    unawaited(_refreshAll());
  }

  Future<void> _refreshAll() {
    // 당겨 새로 읽을 때 종의 점도 서버 값으로 다시 맞춘다.
    ref.invalidate(unreadCountViewModelProvider);
    return Future.wait([
      ref.read(storeHomeViewModelProvider.notifier).refresh(),
      ref.read(storeHomePicksViewModelProvider.notifier).refresh(),
    ]);
  }

  void _onNotice(String? message) {
    _noticeTimer?.cancel();
    if (message == null) return;
    _noticeTimer = Timer(StoreHomePage.noticeFor, () {
      if (mounted) ref.read(storeHomeNoticeProvider.notifier).clear();
    });
  }

  void _onNav(int index) {
    switch (index) {
      case StoreHomePage.navHome:
        // 이미 홈이라서 맨 위로 올라간다.
        if (_scroll.hasClients) {
          unawaited(
            _scroll.animateTo(
              0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            ),
          );
        }
      case StoreHomePage.navFind:
        // 하단 메뉴의 `찾기`는 전체 둘러보기(G1)다. 홈 위로 밀려 들어온다.
        context.push(AppRoutes.storeDiscover);
      case StoreHomePage.navChat:
        context.go(AppRoutes.chats);
      case StoreHomePage.navOffers:
        // 하단 메뉴의 `오퍼`는 제안함(F3)이다. 홈 위로 밀려 들어온다.
        context.push(AppRoutes.storeProposals);
      case StoreHomePage.navDrafts:
        context.push(AppRoutes.storeDrafts);
    }
  }

  /// 추천 칸의 `제안하기`. 지원자가 아닐 수 있어서 받는 사람을 함께 넘긴다.
  void _offerTo(ApplicantPick pick) {
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
  Widget build(BuildContext context) {
    ref.listen(storeHomeNoticeProvider, (_, next) => _onNotice(next));
    final async = ref.watch(storeHomeViewModelProvider);
    final notice = ref.watch(storeHomeNoticeProvider);
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: switch (async) {
              AsyncData(:final value) => _Body(
                state: value,
                controller: _scroll,
                onRefresh: _refreshAll,
                onBellReturn: _onBellReturn,
                onOffer: _offerTo,
              ),
              AsyncError() => CoraStateView.loadFailed(
                title: StoreHomePage.loadFailed,
                onRetry: () => ref.invalidate(storeHomeViewModelProvider),
              ),
              _ => const CoraStateView.loading(),
            },
          ),
          if (notice != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                // 하단 메뉴(높이 64, 아래 20) 바로 위.
                padding: const EdgeInsets.only(bottom: 20 + 64 + 12),
                child: _Notice(message: notice),
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: CoraBottomNav(
              items: CoraNavItems.store,
              currentIndex: StoreHomePage.navHome,
              onTap: _onNav,
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.state,
    required this.controller,
    required this.onRefresh,
    required this.onBellReturn,
    required this.onOffer,
  });

  final StoreHomeState state;
  final ScrollController controller;
  final Future<void> Function() onRefresh;
  final ValueChanged<Object?> onBellReturn;
  final ValueChanged<ApplicantPick> onOffer;

  /// 하단 메뉴(높이 64, 아래 20)에 가려지지 않게 목록 끝에 두는 여백.
  static const double _navClearance = 20 + 64 + 24;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final now = ref.watch(clockProvider).now();
    final store = ref.watch(myStoreViewModelProvider).value;
    final picks = ref.watch(storeHomePicksViewModelProvider).value;
    final newApplications = state.summary.newApplications;
    final terms = store?.defaultTerms;
    // `지원 있음`·`지원 없음`은 서버가 말한 출처로 가른다(지원 줄은 있어도 프로필이 모두 지워졌으면 전체에서
    // 뽑는다). 추천을 아직 못 읽었으면 `새 지원` 숫자로 임시로 정한다.
    final applied = picks == null
        ? newApplications > 0
        : picks.source == PicksSource.applicants;
    final trialBanner = store?.trialBanner;
    final shownCount = newApplications > 0
        ? newApplications
        : (picks?.items.length ?? 0);
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: c.text,
      backgroundColor: c.background,
      child: ListView(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: _navClearance),
        children: [
          _Header(onBellReturn: onBellReturn),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: RecruitBox(
              headline: terms == null ? null : recruitHeadline(terms.reward),
              detail: terms == null ? null : recruitDetail(terms.reward),
              hasApplicants: applied,
              newApplications: shownCount,
              onFix: () => context.push(
                AppRoutes.storeOnboardingTerms,
                extra: AppRoutes.stacked,
              ),
              onOpenApplicants: () => context.push(AppRoutes.storeApplicants),
              onSetTerms: () => context.push(
                AppRoutes.storeOnboardingTerms,
                extra: AppRoutes.stacked,
              ),
            ),
          ),
          if (trialBanner != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _TrialBanner(kind: trialBanner),
            ),
          // 모집 조건을 정하지 않은 가게에는 추천을 보이지 않는다(캔버스 밖).
          if (terms != null && picks != null && picks.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: RecommendedPicks(
                picks: picks.items,
                applied: applied,
                now: now,
                intro: applied
                    ? StoreHomePage.appliedIntro(
                        applied: shownCount,
                        picked: picks.items.length,
                      )
                    : StoreHomePage.allIntro(picked: picks.items.length),
                onOffer: onOffer,
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: BrowseAllCard(
              onTap: () => context.push(AppRoutes.storeDiscover),
            ),
          ),
        ],
      ),
    );
  }
}

/// 머리(높이 72, 좌우 20): 가게 사진 44, 가게 이름, 종 아이콘, 오른쪽 `가게 페이지`. 사진을 누르면 내 가게.
/// 종은 캔버스 NStoreHome에 없다(2026-11-11 소유자 결정). `가게 페이지` 왼쪽에 둔다.
class _Header extends ConsumerWidget {
  const _Header({required this.onBellReturn});

  final ValueChanged<Object?> onBellReturn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final store = ref.watch(myStoreViewModelProvider).value;
    return SizedBox(
      height: 72,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Semantics(
              container: true,
              button: true,
              label: '내 가게',
              onTap: () => context.push(AppRoutes.storeMe),
              child: ExcludeSemantics(
                child: CoraPressable(
                  onTap: () => context.push(AppRoutes.storeMe),
                  child: SizedBox.square(
                    dimension: 44,
                    child: ClipOval(
                      child: CoraNetworkPhoto(
                        url: store?.coverPhotoUrl,
                        background: c.coverPlaceholder,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    StoreHomePage.title,
                    style: CoraTextStyles.fieldLabel.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
                  Text(
                    store?.name ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CoraTextStyles.bodyLarge.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: c.text,
                    ),
                  ),
                ],
              ),
            ),
            NotificationBell(onReturn: onBellReturn),
            Semantics(
              container: true,
              button: true,
              label: StoreHomePage.storePage,
              onTap: () => context.push(AppRoutes.storePage),
              child: ExcludeSemantics(
                child: CoraPressable(
                  onTap: () => context.push(AppRoutes.storePage),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 10,
                    ),
                    child: Text(
                      StoreHomePage.storePage,
                      style: CoraTextStyles.label.copyWith(color: c.text),
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

/// 체험단 줄(캔버스 NStoreHome `<a>`): 안쪽 12/16, 모서리 18, `surface`, 글자 13과 오른쪽 `›`.
/// `COMPARE`는 비교(G3)를, `HINT`는 계약 정보 입력을 연다. 안내(`HINT`)는 한 번 보이면 서버에 봤다고 알려
/// 다시 나오지 않게 한다.
class _TrialBanner extends ConsumerStatefulWidget {
  const _TrialBanner({required this.kind});

  final TrialBannerKind kind;

  @override
  ConsumerState<_TrialBanner> createState() => _TrialBannerState();
}

class _TrialBannerState extends ConsumerState<_TrialBanner> {
  @override
  void initState() {
    super.initState();
    if (widget.kind == TrialBannerKind.hint) _markSeen();
  }

  /// 이 화면의 줄은 그대로 두고 서버에만 알린다(누를 수 있어야 해서). 알리지 못해도 홈은 그대로다.
  Future<void> _markSeen() async {
    try {
      await ref.read(trialCompareRepositoryProvider).markHintSeen();
    } on Object {
      // 다음에 홈을 열 때 한 번 더 보일 뿐이다.
    }
  }

  void _open() => context.push(
    widget.kind == TrialBannerKind.compare
        ? AppRoutes.storeTrialCompare
        : AppRoutes.storeTrialInfo,
  );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = widget.kind == TrialBannerKind.compare
        ? StoreHomePage.compareBanner
        : StoreHomePage.hintBanner;
    return Semantics(
      container: true,
      button: true,
      label: text,
      onTap: _open,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: _open,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(CoraRadius.lg),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                spacing: 8,
                children: [
                  Expanded(
                    child: Text(
                      text,
                      style: CoraTextStyles.meta.copyWith(color: c.text),
                    ),
                  ),
                  Text(
                    '›',
                    style: CoraTextStyles.meta.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 홈 아래에 잠깐 떠 있는 안내(캔버스에 없다). 본문색 바탕에 배경색 글자라 라이트·다크 모두 읽힌다.
class _Notice extends StatelessWidget {
  const _Notice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return IgnorePointer(
      child: Semantics(
        liveRegion: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.text,
            borderRadius: BorderRadius.circular(CoraRadius.pill),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Text(
              message,
              style: CoraTextStyles.label.copyWith(color: c.background),
            ),
          ),
        ),
      ),
    );
  }
}
