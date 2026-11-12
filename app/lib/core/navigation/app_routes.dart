/// 앱의 경로. 화면 이동은 문자열 대신 이 상수로 한다.
///
/// 역할(`UserRole`)에 따른 경로 고르기는 여기 두지 않는다. 이 파일이 `features`를 가져오면
/// 핵심 계층이 기능에 기대게 되므로, 역할별 진입은 `role_entry.dart`가 맡는다.
abstract final class AppRoutes {
  /// 앱을 켠 직후 첫 세션 값을 기다리는 빈 화면. 값을 받으면 바로 다른 경로로 보낸다.
  static const splash = '/';

  /// 로그인(E1).
  static const login = '/login';

  /// 휴대폰 인증(E2). E1 위에 쌓이므로 뒤로 가면 E1이다.
  static const loginVerify = '/login/verify';

  /// 역할 선택(A1). 역할이 있어도 홈의 "역할 다시 고르기"로 다시 열 수 있다.
  static const role = '/role';

  /// 역할별 홈. 가게(`/store`)와 크리에이터(`/creator`)는 홈에 들어올 수 있는 상태(공개된
  /// 가게, 프로필이 있는 크리에이터)일 때만 열리고, 아니면 역할별 진입 규칙이 다른 곳으로 보낸다.
  static const store = '/store';
  static const brand = '/brand';
  static const creator = '/creator';

  // 가게 사장님 흐름
  static const storeOnboardingLinks = '/store/onboarding/links';
  static const storeOnboardingPage = '/store/onboarding/page';
  static const storeOnboardingEdit = '/store/onboarding/edit';
  static const storeOnboardingDrafts = '/store/onboarding/drafts';
  static const storeOnboardingTerms = '/store/onboarding/terms';
  static const storePage = '/store/page';
  static const storeDrafts = '/store/drafts';

  /// 내 가게(가게 페이지, 보관함, 설정, 로그아웃). 홈 머리의 가게 사진을 누르면 열린다.
  static const storeMe = '/store/me';

  /// 크리에이터 [creatorId]에게 보내는 오퍼 작성(NOffer).
  static String storeOfferNew(String creatorId) =>
      '/store/offers/new/${Uri.encodeComponent(creatorId)}';

  /// 협업 [collaborationId]의 결제(A8). 보낸 오퍼 줄의 `결제하기`로 열고, 홈 위에 밀려 들어온다.
  static String storePay(String collaborationId) =>
      '/store/collaborations/${Uri.encodeComponent(collaborationId)}/pay';

  /// [storePay]의 라우트 패턴.
  static const storePayPattern = '/store/collaborations/:collaborationId/pay';

  /// 아직 만들지 않은 가게 쪽 화면. [title]이 한글이어도 되도록 인코딩한다.
  static String storeComingSoon(String title) =>
      '/store/coming-soon/${Uri.encodeComponent(title)}';

  // 크리에이터 흐름
  static const creatorProfileSetup = '/creator/profile/setup';
  static const creatorOffers = '/creator/offers';
  static String creatorStore(String storeId) =>
      '/creator/stores/${Uri.encodeComponent(storeId)}';

  /// 크리에이터의 협업 진행(A7)과 거기서 여는 링크 제출·식사권 화면.
  static String creatorCollaboration(String id) =>
      '/creator/collaborations/${Uri.encodeComponent(id)}';
  static String creatorCollaborationSubmit(String id) =>
      '${creatorCollaboration(id)}/submit';
  static String creatorVoucher(String id) =>
      '${creatorCollaboration(id)}/voucher';
  static const creatorCollaborationPattern = '/creator/collaborations/:id';

  /// 지급받을 계좌와 인스타그램 연동. 협업 화면과 받은 오퍼 카드에서 밀려 들어온다.
  static const creatorPayoutAccount = '/creator/payout-account';
  static const creatorInstagram = '/creator/instagram';

  static String creatorComingSoon(String title) =>
      '/creator/coming-soon/${Uri.encodeComponent(title)}';

  /// 역할 선택 화면에서 홈으로 갈 때 쿼리로 붙이는 표시(`?from=roleSelect`). 이때만 진입 화면이
  /// 밀려 들어오고, 로그인 직후나 앱을 다시 켰을 때는 제자리에서 나타난다.
  ///
  /// `extra`가 아니라 쿼리인 이유: go_router는 리다이렉트로 다른 경로가 되면 `extra`를 버린다.
  /// 홈(`/store`)이 진입 경로로 리다이렉트되는 지금은 쿼리만 라우터가 옮겨 줄 수 있다.
  static const fromParam = 'from';
  static const fromRoleSelect = 'roleSelect';

  /// [path]에 [fromRoleSelect] 표시를 붙인다.
  static String withFromRoleSelect(String path) => Uri.parse(
    path,
  ).replace(queryParameters: {fromParam: fromRoleSelect}).toString();

  /// 홈이나 진입 화면으로도 쓰이는 경로(예: `/store/coming-soon/:title`)를 앱 안에서 `push`로
  /// 열 때 `extra`로 넘긴다. 넘기지 않으면 제자리에서 나타난다(진입과 구별할 수 없어서).
  static const stacked = 'stacked';

  /// 개발 환경 전용 모션 갤러리. 운영 빌드에는 없다.
  static const devMotion = '/dev/motion';

  /// 개발 환경 전용 가짜 결제창. 서버의 가짜 PG(`cora-dev://fake-pay`)를 앱 안에서 연다.
  static const devFakeCheckout = '/dev/fake-checkout';

  /// 개발 환경 전용 가짜 인스타그램 연결 화면(아이디를 직접 입력한다).
  static const devFakeInstagram = '/dev/fake-instagram';

  /// 이 경로 아래는 개발 도구다. 로그인 없이 열 수 있다.
  static const devPrefix = '/dev/';
}
