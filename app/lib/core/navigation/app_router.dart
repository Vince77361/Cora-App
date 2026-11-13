import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/applicant_picks/presentation/pages/applicant_picks_page.dart';
import '../../features/auth/domain/auth_session.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/phone_verify_page.dart';
import '../../features/auth/presentation/viewmodels/auth_view_model.dart';
import '../../features/collaboration/presentation/pages/collaboration_page.dart';
import '../../features/collaboration/presentation/pages/store_collaboration_page.dart';
import '../../features/collaboration/presentation/pages/submit_link_page.dart';
import '../../features/collaboration/presentation/pages/voucher_page.dart';
import '../../features/creator_profile/presentation/pages/creator_profile_setup_page.dart';
import '../../features/dev/presentation/pages/motion_gallery_page.dart';
import '../../features/notification_settings/presentation/pages/notification_settings_page.dart';
import '../../features/notifications/presentation/notification_routes.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/onboarding/domain/me.dart';
import '../../features/payment/presentation/pages/fake_checkout_page.dart';
import '../../features/payment/presentation/pages/store_payment_page.dart';
import '../../features/onboarding/presentation/pages/role_home_placeholder_page.dart';
import '../../features/onboarding/presentation/pages/role_select_page.dart';
import '../../features/onboarding/presentation/viewmodels/me_view_model.dart';
import '../../features/instagram_connect/presentation/pages/fake_instagram_connect_page.dart';
import '../../features/proposals/domain/offer_version.dart';
import '../../features/proposals/presentation/pages/counter_proposal_page.dart';
import '../../features/proposals/presentation/pages/proposal_detail_page.dart';
import '../../features/proposals/presentation/pages/proposals_page.dart';
import '../../features/instagram_connect/presentation/pages/instagram_connect_page.dart';
import '../../features/offers/presentation/pages/received_offers_page.dart';
import '../../features/payout_account/presentation/pages/payout_account_page.dart';
import '../../features/wallet/presentation/pages/wallet_page.dart';
import '../../features/offers/presentation/pages/send_offer_page.dart';
import '../../features/store_browse/presentation/pages/store_detail_page.dart';
import '../../features/store_browse/presentation/pages/store_list_page.dart';
import '../../features/store_home/presentation/pages/store_home_page.dart';
import '../../features/trial_compare/presentation/pages/trial_compare_page.dart';
import '../../features/view_report/presentation/pages/view_report_page.dart';
import '../../features/trial_compare/presentation/pages/trial_info_page.dart';
import '../../features/store_result/presentation/pages/store_result_page.dart';
import '../../features/store_home/presentation/pages/store_me_page.dart';
import '../../features/store_home/presentation/viewmodels/store_home_view_model.dart';
import '../../features/store_onboarding/presentation/pages/content_drafts_page.dart';
import '../../features/store_onboarding/presentation/pages/recruit_terms_page.dart';
import '../../features/store_onboarding/presentation/pages/store_edit_page.dart';
import '../../features/store_onboarding/presentation/pages/store_manual_page.dart';
import '../../features/store_onboarding/presentation/pages/store_links_page.dart';
import '../../features/store_onboarding/presentation/pages/store_page_preview_page.dart';
import '../config/app_config.dart';
import '../config/app_config_provider.dart';
import '../ui/cora_coming_soon_page.dart';
import 'app_routes.dart';
import 'cora_transitions.dart';
import 'role_entry.dart';

/// 앱의 라우터. 앱이 떠 있는 동안 하나만 만든다.
///
/// 로그인 상태나 내 정보(역할)가 바뀌면 라우터를 새로 만들지 않고 리다이렉트만 다시 돌린다.
/// 새로 만들면 쌓여 있던 화면과 이동 기록이 모두 사라진다.
final appRouterProvider = Provider<GoRouter>((ref) {
  final config = ref.watch(appConfigProvider);
  // 개발 화면(`/dev/…`)은 운영으로 컴파일하면 상수 false로 막혀 앱 바이너리에서 빠진다.
  final devScreens = kDevScreensCompiledIn && config.isDev;

  // 두 상태 중 무엇이 바뀌어도 리다이렉트를 다시 돌린다. 값은 리다이렉트가 돌 때 그 순간의
  // 것을 읽는다. 로그인 상태가 바뀐 직후에는 내 정보가 아직 옛 사용자의 것일 수 있어서,
  // 알림으로 받은 값을 들고 있으면 한 박자 어긋난다.
  final refresh = _RouterRefresh();
  ref.listen(authViewModelProvider, (_, _) => refresh.notify());
  ref.listen(meViewModelProvider, (_, _) => refresh.notify());

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => _redirect(
      ref,
      ref.read(authViewModelProvider),
      ref.read(meViewModelProvider),
      state.uri,
      devScreens: devScreens,
    ),
    // 없는 경로(예: 운영 빌드의 /dev/motion)는 오류 화면 대신 첫 화면에서 다시 고른다.
    onException: (context, state, router) => router.go(AppRoutes.splash),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) =>
            NoTransitionPage(key: state.pageKey, child: const Scaffold()),
      ),
      // 로그인 전후는 제자리에서 바뀐다(fade). E2는 E1 위로 밀려 들어오고 뒤로 가면 E1이다.
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) =>
            CoraTransitions.fade(const LoginPage(), key: state.pageKey),
        routes: [
          GoRoute(
            path: 'verify',
            pageBuilder: (context, state) => CoraTransitions.push(
              const PhoneVerifyPage(),
              key: state.pageKey,
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.role,
        pageBuilder: (context, state) =>
            CoraTransitions.fade(const RoleSelectPage(), key: state.pageKey),
      ),
      // 브랜드 홈은 아직 임시 화면이다. 가게와 크리에이터 화면은 아래 역할 경로들이다.
      GoRoute(
        path: AppRoutes.brand,
        pageBuilder: (context, state) =>
            _entryPage(state, const RoleHomePlaceholderPage()),
      ),
      // 가게 사장님 흐름.
      GoRoute(
        path: AppRoutes.store,
        pageBuilder: (context, state) => _entryPage(
          state,
          // 알림함이 `?tab=`으로 열 탭을 알려 준다.
          StoreHomePage(
            initialTab: switch (state.uri.queryParameters[NotificationRoutes
                .tabParam]) {
              NotificationRoutes.applicantsTab => StoreHomeTab.applicants,
              NotificationRoutes.sentOffersTab => StoreHomeTab.sentOffers,
              _ => null,
            },
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.storeOnboardingLinks,
        pageBuilder: (context, state) =>
            _entryPage(state, const StoreLinksPage()),
      ),
      GoRoute(
        path: AppRoutes.storeOnboardingPage,
        pageBuilder: (context, state) =>
            _entryPage(state, const StorePagePreviewPage()),
      ),
      GoRoute(
        path: AppRoutes.storeOnboardingEdit,
        pageBuilder: (context, state) => CoraTransitions.sheet(
          StoreEditPage(
            args: state.extra is StoreEditArgs
                ? state.extra! as StoreEditArgs
                : const StoreEditArgs(),
          ),
          key: state.pageKey,
        ),
      ),
      GoRoute(
        path: AppRoutes.storeOnboardingManual,
        pageBuilder: (context, state) => CoraTransitions.push(
          StoreManualPage(
            args: state.extra is StoreManualArgs
                ? state.extra! as StoreManualArgs
                : const StoreManualArgs(),
          ),
          key: state.pageKey,
        ),
      ),
      GoRoute(
        path: AppRoutes.storeOnboardingDrafts,
        pageBuilder: (context, state) =>
            _entryPage(state, const ContentDraftsPage()),
      ),
      GoRoute(
        path: AppRoutes.storeOnboardingTerms,
        pageBuilder: (context, state) =>
            _entryPage(state, const RecruitTermsPage()),
      ),
      GoRoute(
        path: AppRoutes.storePage,
        pageBuilder: (context, state) => CoraTransitions.push(
          const StorePagePreviewPage(onboarding: false),
          key: state.pageKey,
        ),
      ),
      GoRoute(
        path: AppRoutes.storeMe,
        pageBuilder: (context, state) =>
            CoraTransitions.push(const StoreMePage(), key: state.pageKey),
      ),
      // 체험단 계약 정보 입력. 내 가게와 홈의 안내 줄이 연다.
      GoRoute(
        path: AppRoutes.storeTrialInfo,
        pageBuilder: (context, state) =>
            CoraTransitions.push(const TrialInfoPage(), key: state.pageKey),
      ),
      // 지난 3개월 비교(G3). 사장님 홈 위로 밀려 들어온다.
      GoRoute(
        path: AppRoutes.storeTrialCompare,
        pageBuilder: (context, state) =>
            CoraTransitions.push(const TrialComparePage(), key: state.pageKey),
      ),
      GoRoute(
        path: AppRoutes.storeDrafts,
        pageBuilder: (context, state) => CoraTransitions.push(
          const ContentDraftsPage(onboarding: false),
          key: state.pageKey,
        ),
      ),
      GoRoute(
        path: '/store/offers/new/:creatorId',
        pageBuilder: (context, state) => CoraTransitions.push(
          SendOfferPage(
            creatorId: state.pathParameters['creatorId']!,
            // G1·G2가 받는 사람(지원자가 아닐 수 있다)과 지난 조건을 넘긴다.
            args: state.extra is SendOfferArgs
                ? state.extra! as SendOfferArgs
                : const SendOfferArgs(),
          ),
          key: state.pageKey,
        ),
      ),
      // 제안함(F3)과 제안 상세. 사장님 홈 위로 밀려 들어온다.
      GoRoute(
        path: AppRoutes.storeProposals,
        pageBuilder: (context, state) => CoraTransitions.push(
          const ProposalsPage(party: ProposalParty.store),
          key: state.pageKey,
        ),
      ),
      GoRoute(
        path: AppRoutes.storeProposalPattern,
        pageBuilder: (context, state) => CoraTransitions.push(
          ProposalDetailPage(
            offerId: state.pathParameters['offerId']!,
            party: ProposalParty.store,
          ),
          key: state.pageKey,
        ),
      ),
      GoRoute(
        path: AppRoutes.storePayPattern,
        pageBuilder: (context, state) => CoraTransitions.push(
          StorePaymentPage(
            collaborationId: state.pathParameters['collaborationId']!,
          ),
          key: state.pageKey,
        ),
      ),
      // 지원자 추천(G2). 사장님 홈 위로 밀려 들어온다.
      GoRoute(
        path: AppRoutes.storeApplicantPicks,
        pageBuilder: (context, state) => CoraTransitions.push(
          const ApplicantPicksPage(),
          key: state.pageKey,
        ),
      ),
      GoRoute(
        path: AppRoutes.storeResultPattern,
        pageBuilder: (context, state) => CoraTransitions.push(
          StoreResultPage(
            collaborationId: state.pathParameters['collaborationId']!,
          ),
          key: state.pageKey,
        ),
      ),
      GoRoute(
        path: AppRoutes.storeViewReportPattern,
        pageBuilder: (context, state) => CoraTransitions.push(
          ViewReportPage(
            collaborationId: state.pathParameters['collaborationId']!,
            viewer: ViewReportViewer.owner,
          ),
          key: state.pageKey,
        ),
      ),
      GoRoute(
        path: AppRoutes.storeCollaborationPattern,
        pageBuilder: (context, state) => CoraTransitions.push(
          StoreCollaborationPage(
            collaborationId: state.pathParameters['collaborationId']!,
          ),
          key: state.pageKey,
        ),
      ),
      GoRoute(
        path: '/store/coming-soon/:title',
        pageBuilder: (context, state) => _entryPage(
          state,
          CoraComingSoonPage(title: state.pathParameters['title']!),
        ),
      ),
      // 알림함(E3). 역할 홈 위로 밀려 들어온다.
      GoRoute(
        path: NotificationRoutes.notifications,
        pageBuilder: (context, state) =>
            CoraTransitions.push(const NotificationsPage(), key: state.pageKey),
      ),
      // 알림 설정(E5). 알림함의 설정 아이콘이 연다(E4 설정은 새 계획이 만든다).
      GoRoute(
        path: NotificationRoutes.settings,
        pageBuilder: (context, state) => CoraTransitions.push(
          const NotificationSettingsPage(),
          key: state.pageKey,
        ),
      ),
      // 크리에이터 흐름. 10번 작업이 실제 화면으로 바꾼다.
      GoRoute(
        path: AppRoutes.creator,
        pageBuilder: (context, state) =>
            _entryPage(state, const StoreListPage()),
      ),
      GoRoute(
        path: AppRoutes.creatorProfileSetup,
        pageBuilder: (context, state) =>
            _entryPage(state, const CreatorProfileSetupPage()),
      ),
      GoRoute(
        path: '/creator/stores/:id',
        pageBuilder: (context, state) => CoraTransitions.push(
          StoreDetailPage(storeId: state.pathParameters['id']!),
          key: state.pageKey,
        ),
      ),
      // F6 내 방식으로 제안. D2가 쓴 한 줄을 `extra`로 넘긴다.
      GoRoute(
        path: AppRoutes.creatorStoreProposalPattern,
        pageBuilder: (context, state) => CoraTransitions.push(
          CounterProposalPage(
            storeId: state.pathParameters['id']!,
            pitch: state.extra is String ? state.extra! as String : '',
          ),
          key: state.pageKey,
        ),
      ),
      // 하단 메뉴의 `협업` 탭이라 제자리에서 바뀐다. 가게 상세에서 `오퍼 보기`로 열 때만 밀려 들어온다.
      GoRoute(
        path: AppRoutes.creatorOffers,
        pageBuilder: (context, state) =>
            _entryPage(state, const ReceivedOffersPage()),
      ),
      // 크리에이터의 제안함(F3)과 제안 상세. 받은 오퍼 위로 밀려 들어온다.
      GoRoute(
        path: AppRoutes.creatorProposals,
        pageBuilder: (context, state) => CoraTransitions.push(
          const ProposalsPage(party: ProposalParty.creator),
          key: state.pageKey,
        ),
      ),
      GoRoute(
        path: AppRoutes.creatorProposalPattern,
        pageBuilder: (context, state) => CoraTransitions.push(
          ProposalDetailPage(
            offerId: state.pathParameters['offerId']!,
            party: ProposalParty.creator,
          ),
          key: state.pageKey,
        ),
      ),
      GoRoute(
        path: AppRoutes.creatorCollaborationPattern,
        pageBuilder: (context, state) => CoraTransitions.push(
          CollaborationPage(collaborationId: state.pathParameters['id']!),
          key: state.pageKey,
        ),
      ),
      GoRoute(
        path: '${AppRoutes.creatorCollaborationPattern}/submit',
        pageBuilder: (context, state) => CoraTransitions.push(
          SubmitLinkPage(collaborationId: state.pathParameters['id']!),
          key: state.pageKey,
        ),
      ),
      GoRoute(
        path: '${AppRoutes.creatorCollaborationPattern}/report',
        pageBuilder: (context, state) => CoraTransitions.push(
          ViewReportPage(
            collaborationId: state.pathParameters['id']!,
            viewer: ViewReportViewer.creator,
          ),
          key: state.pageKey,
        ),
      ),
      GoRoute(
        path: '${AppRoutes.creatorCollaborationPattern}/voucher',
        pageBuilder: (context, state) => CoraTransitions.push(
          VoucherPage(collaborationId: state.pathParameters['id']!),
          key: state.pageKey,
        ),
      ),
      // 정산(E7). 알림함의 정산 줄이 연다(E4 설정의 "정산 계좌와 내역"은 새 계획이 만든다).
      GoRoute(
        path: NotificationRoutes.wallet,
        pageBuilder: (context, state) =>
            CoraTransitions.push(const WalletPage(), key: state.pageKey),
      ),
      GoRoute(
        path: AppRoutes.creatorPayoutAccount,
        pageBuilder: (context, state) =>
            CoraTransitions.push(const PayoutAccountPage(), key: state.pageKey),
      ),
      GoRoute(
        path: AppRoutes.creatorInstagram,
        pageBuilder: (context, state) => CoraTransitions.push(
          const InstagramConnectPage(),
          key: state.pageKey,
        ),
      ),
      GoRoute(
        path: '/creator/coming-soon/:title',
        pageBuilder: (context, state) => _entryPage(
          state,
          CoraComingSoonPage(title: state.pathParameters['title']!),
        ),
      ),
      if (kDevScreensCompiledIn && config.isDev)
        GoRoute(
          path: AppRoutes.devMotion,
          pageBuilder: (context, state) => CoraTransitions.push(
            const MotionGalleryPage(),
            key: state.pageKey,
          ),
        ),
      // 가짜 인스타그램 연결 화면도 개발 환경에서만 있다(서버가 가짜 어댑터일 때 아이디를 직접 입력한다).
      if (kDevScreensCompiledIn && config.isDev)
        GoRoute(
          path: AppRoutes.devFakeInstagram,
          pageBuilder: (context, state) => CoraTransitions.push(
            const FakeInstagramConnectPage(),
            key: state.pageKey,
          ),
        ),
      // 가짜 결제창은 서버가 가짜 PG일 때(개발)만 쓴다. 운영 빌드에는 라우트도 코드도 없다.
      if (kDevScreensCompiledIn && config.isDev)
        GoRoute(
          path: AppRoutes.devFakeCheckout,
          pageBuilder: (context, state) => CoraTransitions.push(
            FakeCheckoutPage(
              paymentId: state.uri.queryParameters['paymentId'] ?? '',
              amount: int.tryParse(state.uri.queryParameters['amount'] ?? ''),
            ),
            key: state.pageKey,
          ),
        ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

/// 진입 경로로도 쓰이는 화면의 전환. 역할을 고른 직후(`?from=roleSelect`)이거나 앱 안에서
/// `push`로 연 경우(`stacked`)에만 밀려 들어오고, 로그인 직후나 앱을 다시 켰을 때는 제자리에서
/// 나타난다.
Page<void> _entryPage(GoRouterState state, Widget child) {
  final pushed =
      state.uri.queryParameters[AppRoutes.fromParam] ==
          AppRoutes.fromRoleSelect ||
      state.extra == AppRoutes.stacked;
  return pushed
      ? CoraTransitions.push(child, key: state.pageKey)
      : CoraTransitions.fade(child, key: state.pageKey);
}

/// 리다이렉트를 다시 돌리라고 알리기만 하는 신호.
class _RouterRefresh extends ChangeNotifier {
  void notify() => notifyListeners();
}

/// 로그인 상태와 내 정보(역할)에 따른 이동 규칙.
///
/// - 첫 세션 값을 받기 전(앱을 켠 직후 한 프레임)에는 빈 첫 화면에 머문다. 여기서 로그인
///   화면을 먼저 띄우면 저장된 세션이 있는 사람에게 로그인 화면이 깜빡인다.
/// - 세션이 없으면 로그인(`/login`, `/login/verify`) 말고는 어디서든 `/login`.
/// - 세션이 있고 내 정보를 불러오는 중이면 빈 첫 화면에서 기다린다. 역할을 알기 전에
///   역할 선택이나 홈을 먼저 띄우면 잘못된 화면이 깜빡인다.
/// - 내 정보를 불러오지 못하면 `/role`로 보낸다. 거기서 오류와 "다시 시도"를 보여 준다.
/// - 역할이 없으면 `/role`. `/role`은 역할이 있어도 열린다(홈의 "역할 다시 고르기").
/// - 역할이 있으면 진입 경로([RoleEntryResolver])로 보낸다. 로그인 화면·첫 화면·자기 역할의
///   홈·다른 역할의 화면을 열었을 때다. 이미 그 안쪽 화면에 있으면 그대로 둔다.
/// - 개발 환경의 `/dev/…`는 로그인과 상관없이 연다(E1의 로고를 길게 눌러 모션 갤러리로 들어간다).
Future<String?> _redirect(
  Ref ref,
  AsyncValue<AuthSession?> auth,
  AsyncValue<Me?> me,
  Uri uri, {
  required bool devScreens,
}) async {
  final path = uri.path;
  if (devScreens && path.startsWith(AppRoutes.devPrefix)) return null;
  if (!auth.hasValue && !auth.hasError) {
    return path == AppRoutes.splash ? null : AppRoutes.splash;
  }
  final signedIn = auth.value != null;
  final onLoginScreen =
      path == AppRoutes.login || path == AppRoutes.loginVerify;
  if (!signedIn) return onLoginScreen ? null : AppRoutes.login;

  // 불러오는 중에는 이전 값(옛 사용자나 이전 오류)이 남아 있을 수 있어서 isLoading을 먼저 본다.
  if (me.isLoading) return path == AppRoutes.splash ? null : AppRoutes.splash;
  if (me.hasError) return path == AppRoutes.role ? null : AppRoutes.role;
  final profile = me.value;
  // 로그인한 직후 내 정보가 아직 로그아웃 때의 null이면 불러오기가 시작되기 전이다.
  if (profile == null) {
    return path == AppRoutes.splash ? null : AppRoutes.splash;
  }

  final role = profile.role;
  if (role == null) return path == AppRoutes.role ? null : AppRoutes.role;
  final owner = roleOwningPath(path);
  final needsEntry =
      onLoginScreen ||
      path == AppRoutes.splash ||
      path == roleHomePath(role) ||
      (owner != null && owner != role);
  if (!needsEntry) return null;

  final String target;
  try {
    target = await ref.read(roleEntryResolverProvider)(ref, role);
  } catch (_) {
    // 진입 경로를 알 수 없으면(조회 실패) 빈 화면에 갇히지 않게 역할 화면으로 보낸다.
    return AppRoutes.role;
  }
  if (target == path) return null;
  // 역할을 고른 직후라는 표시는 리다이렉트 너머로 이어 준다(전환을 고르는 데 쓴다).
  return uri.queryParameters[AppRoutes.fromParam] == AppRoutes.fromRoleSelect
      ? AppRoutes.withFromRoleSelect(target)
      : target;
}
