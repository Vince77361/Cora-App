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
import '../../../../core/ui/cora_error_view.dart';
import '../../../../core/ui/cora_list_row.dart';
import '../../../../core/ui/cora_network_photo.dart';
import '../../../../core/ui/cora_pressable.dart';
import '../../../../core/ui/cora_segmented_tabs.dart';
import '../../../offers/domain/offer_view.dart';
import '../../../store_onboarding/presentation/viewmodels/my_store_view_model.dart';
import '../../domain/sent_offer.dart';
import '../store_home_text.dart';
import '../viewmodels/store_home_view_model.dart';
import '../widgets/cancel_offer_sheet.dart';

/// A9 사장님 홈(NStoreHome / DarkNStoreHome). 숫자 세 칸, 바로가기, `지원한 크리에이터`와
/// `보낸 오퍼` 목록. 아래로 당기면 숫자와 두 목록을 함께 새로 읽는다.
class StoreHomePage extends ConsumerStatefulWidget {
  const StoreHomePage({super.key});

  static const title = '사장님 홈';
  static const storePage = '가게 페이지';
  static const newApplications = '새 지원';
  static const sentOffers = '보낸 오퍼';
  static const inProgress = '진행 중';
  static const shortcuts = ['릴스로 찾기', '리스트 검색', '빠른 입찰'];
  static const sendOffer = '오퍼 보내기';
  static const emptyApplicants = '아직 지원한 크리에이터가 없어요. 가게가 공개되면 지원이 도착해요.';
  static const emptySentOffers = '아직 보낸 오퍼가 없어요.';

  /// 캔버스에 없는 상태의 문구.
  static const loadFailed = '사장님 홈을 불러오지 못했어요.';

  static String applicantsTab(int count) => '지원한 크리에이터 $count';
  static String sentOffersTab(int count) => '보낸 오퍼 $count';

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

  @override
  void dispose() {
    _noticeTimer?.cancel();
    super.dispose();
  }

  void _onNotice(String? message) {
    _noticeTimer?.cancel();
    if (message == null) return;
    _noticeTimer = Timer(StoreHomePage.noticeFor, () {
      if (mounted) ref.read(storeHomeNoticeProvider.notifier).clear();
    });
  }

  /// 아직 만들지 않은 화면. 홈 위로 밀려 들어온다.
  void _comingSoon(String title) =>
      context.push(AppRoutes.storeComingSoon(title), extra: AppRoutes.stacked);

  void _onNav(int index) {
    final vm = ref.read(storeHomeViewModelProvider.notifier);
    switch (index) {
      case StoreHomePage.navHome:
        vm.selectTab(StoreHomeTab.applicants);
      case StoreHomePage.navFind:
        _comingSoon(CoraNavItems.store[index].label);
      case StoreHomePage.navChat:
        _comingSoon(CoraNavItems.store[index].label);
      case StoreHomePage.navOffers:
        vm.selectTab(StoreHomeTab.sentOffers);
      case StoreHomePage.navDrafts:
        context.push(AppRoutes.storeDrafts);
    }
  }

  void _onSentOffer(SentOffer offer) {
    if (!offer.cancellable) return;
    showCancelOfferSheet(
      context,
      offer: offer,
      onCancel: () =>
          ref.read(storeHomeViewModelProvider.notifier).cancelOffer(offer.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(storeHomeNoticeProvider, (_, next) => _onNotice(next));
    final c = context.colors;
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
                onSentOffer: _onSentOffer,
                onShortcut: _comingSoon,
              ),
              AsyncError() => CoraErrorView(
                message: StoreHomePage.loadFailed,
                onRetry: () => ref.invalidate(storeHomeViewModelProvider),
              ),
              _ => ColoredBox(
                color: c.background,
                child: const SizedBox.expand(),
              ),
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
    required this.onSentOffer,
    required this.onShortcut,
  });

  final StoreHomeState state;
  final ValueChanged<SentOffer> onSentOffer;
  final ValueChanged<String> onShortcut;

  /// 하단 메뉴(높이 64, 아래 20)에 가려지지 않게 목록 끝에 두는 여백.
  static const double _navClearance = 20 + 64 + 24;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final vm = ref.read(storeHomeViewModelProvider.notifier);
    final now = ref.watch(clockProvider).now();
    final summary = state.summary;
    final sentTab = state.tab == StoreHomeTab.sentOffers;
    return RefreshIndicator(
      onRefresh: vm.refresh,
      color: c.text,
      backgroundColor: c.background,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: _navClearance),
        children: [
          const _Header(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  Expanded(
                    // 캔버스는 첫 칸의 이름만 본문색이고 나머지는 보조색이다.
                    child: _Count(
                      label: StoreHomePage.newApplications,
                      value: summary.newApplications,
                      emphasized: true,
                    ),
                  ),
                  Expanded(
                    child: _Count(
                      label: StoreHomePage.sentOffers,
                      value: summary.sentOffers,
                    ),
                  ),
                  Expanded(
                    child: _Count(
                      label: StoreHomePage.inProgress,
                      value: summary.inProgress,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              spacing: 8,
              children: [
                for (final (i, label) in StoreHomePage.shortcuts.indexed)
                  Expanded(
                    child: _Shortcut(
                      label: label,
                      muted: i == 0,
                      onTap: () => onShortcut(label),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: CoraSegmentedTabs(
              labels: [
                StoreHomePage.applicantsTab(state.applicants.length),
                StoreHomePage.sentOffersTab(state.sentOffers.length),
              ],
              selected: sentTab ? 1 : 0,
              onChanged: (i) => vm.selectTab(
                i == 1 ? StoreHomeTab.sentOffers : StoreHomeTab.applicants,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
            child: sentTab
                ? _SentOffers(
                    state: state,
                    onTap: onSentOffer,
                    onAction: onShortcut,
                  )
                : _Applicants(state: state, now: now),
          ),
        ],
      ),
    );
  }
}

/// 머리(높이 72, 좌우 20): 가게 사진 44, 가게 이름, 오른쪽 `가게 페이지`. 사진을 누르면 내 가게.
class _Header extends ConsumerWidget {
  const _Header();

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

/// 숫자 칸(NStoreHome `<dl>`의 칸): 안쪽 14, 모서리 20, `surface` 바탕, 이름 12, 값 24/900.
class _Count extends StatelessWidget {
  const _Count({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final int value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      label: label,
      value: '$value',
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(CoraRadius.field),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CoraTextStyles.fieldLabel.copyWith(
                    color: emphasized ? c.text : c.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$value',
                  style: CoraTextStyles.digit.copyWith(
                    fontWeight: FontWeight.w900,
                    color: c.text,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 바로가기 알약(높이 46, 14/500). 첫 번째만 `surfaceMuted`, 나머지는 `surface`.
class _Shortcut extends StatelessWidget {
  const _Shortcut({
    required this.label,
    required this.muted,
    required this.onTap,
  });

  final String label;
  final bool muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: CoraPressable(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: muted ? c.surfaceMuted : c.surface,
              borderRadius: BorderRadius.circular(CoraRadius.pill),
            ),
            child: SizedBox(
              height: 46,
              child: Center(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CoraTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                    color: muted ? c.onSurfaceMuted : c.text,
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

/// 캔버스 NStoreHome 목록 사진의 `object-position: 50% 25%`(사람 사진은 얼굴이 위쪽에 있다).
const _faceAlignment = Alignment(0, -0.5);

class _Applicants extends StatelessWidget {
  const _Applicants({required this.state, required this.now});

  final StoreHomeState state;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    if (state.applicants.isEmpty) {
      return const _Empty(message: StoreHomePage.emptyApplicants);
    }
    return Column(
      children: [
        for (final applicant in state.applicants)
          CoraListRow(
            photoUrl: applicant.creator.photoUrl,
            photoAlignment: _faceAlignment,
            title: applicant.creator.displayName,
            subtitle: applicantMeta(applicant, now),
            actionLabel: StoreHomePage.sendOffer,
            actionHighlighted: true,
            onAction: () =>
                context.push(AppRoutes.storeOfferNew(applicant.creator.userId)),
          ),
      ],
    );
  }
}

class _SentOffers extends StatelessWidget {
  const _SentOffers({
    required this.state,
    required this.onTap,
    required this.onAction,
  });

  final StoreHomeState state;
  final ValueChanged<SentOffer> onTap;

  /// `결제하기`, `다시 찾기`를 눌렀을 때(아직 만들지 않은 화면).
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    if (state.sentOffers.isEmpty) {
      return const _Empty(message: StoreHomePage.emptySentOffers);
    }
    return Column(
      children: [
        for (final offer in state.sentOffers)
          CoraListRow(
            photoUrl: offer.creator.photoUrl,
            photoAlignment: _faceAlignment,
            title: offer.creator.displayName,
            subtitle: sentOfferMeta(offer),
            actionLabel: sentOfferAction(offer),
            // 캔버스에서 강조색 버튼은 결제하기뿐이다.
            actionHighlighted: offer.view == OfferView.accepted,
            onAction: () => onAction(sentOfferAction(offer)!),
            onTap: offer.cancellable ? () => onTap(offer) : null,
          ),
      ],
    );
  }
}

/// 목록이 비었을 때(캔버스에 없는 상태).
class _Empty extends StatelessWidget {
  const _Empty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
      child: Semantics(
        liveRegion: true,
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: CoraTextStyles.body.copyWith(
            fontWeight: FontWeight.w400,
            color: c.textSecondary,
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
