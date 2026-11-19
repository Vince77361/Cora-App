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

  /// 등록 없이 먼저 둘러보기(A1 → 01 둘러보기). 역할이 없는 로그인 사용자만 머문다. 역할이 있으면
  /// 그 역할의 첫 화면으로 보낸다. A1 위에 밀려 들어오고, 돌아가면 A1이다.
  static const browse = '/browse';

  /// 역할별 홈. 가게(`/store`)와 크리에이터(`/creator`)는 홈에 들어올 수 있는 상태(공개된
  /// 가게, 프로필이 있는 크리에이터)일 때만 열리고, 아니면 역할별 진입 규칙이 다른 곳으로 보낸다.
  static const store = '/store';
  static const brand = '/brand';
  static const creator = '/creator';

  // 가게 사장님 흐름
  static const storeOnboardingLinks = '/store/onboarding/links';
  static const storeOnboardingPage = '/store/onboarding/page';
  static const storeOnboardingEdit = '/store/onboarding/edit';

  /// 직접 입력(F7). A2 위에 밀려 들어온다.
  static const storeOnboardingManual = '/store/onboarding/manual';
  static const storeOnboardingDrafts = '/store/onboarding/drafts';
  static const storeOnboardingTerms = '/store/onboarding/terms';
  static const storePage = '/store/page';
  static const storeDrafts = '/store/drafts';

  /// 내 가게(가게 페이지, 보관함, 설정, 로그아웃). 홈 머리의 가게 사진을 누르면 열린다.
  static const storeMe = '/store/me';

  /// 크리에이터 [creatorId]에게 보내는 오퍼 작성(NOffer).
  static String storeOfferNew(String creatorId) =>
      '/store/offers/new/${Uri.encodeComponent(creatorId)}';

  /// 협업 [collaborationId]의 결제(A8). 제안함과 제안 상세에서 열고, 홈 위에 밀려 들어온다.
  static String storePay(String collaborationId) =>
      '/store/collaborations/${Uri.encodeComponent(collaborationId)}/pay';

  /// 협업 [collaborationId]의 사장님 진행 화면. 제안 상세의 합의한 줄에서 열고, 홈 위에 밀려 들어온다.
  static String storeCollaboration(String collaborationId) =>
      '/store/collaborations/${Uri.encodeComponent(collaborationId)}';

  /// [storeCollaboration]의 라우트 패턴.
  static const storeCollaborationPattern =
      '/store/collaborations/:collaborationId';

  /// [storePay]의 라우트 패턴.
  static const storePayPattern = '/store/collaborations/:collaborationId/pay';

  /// 협업 [collaborationId]의 성과 확인(F4), 사장님 쪽. 진행 화면의 `조회 자료와 보상 계산 확인` 줄과 G1의
  /// `집계 출처와 계산 보기`가 연다.
  static String storeViewReport(String collaborationId) =>
      '${storeCollaboration(collaborationId)}/report';

  /// [storeViewReport]의 라우트 패턴.
  static const storeViewReportPattern =
      '/store/collaborations/:collaborationId/report';

  /// 협업 [collaborationId]의 7일 결과(G1). 정산 알림과 끝난 협업의 `7일 결과 보기`가 연다.
  static String storeResult(String collaborationId) =>
      '${storeCollaboration(collaborationId)}/result';

  /// [storeResult]의 라우트 패턴.
  static const storeResultPattern =
      '/store/collaborations/:collaborationId/result';

  /// 사장님의 전체 둘러보기(G1). 하단 메뉴의 `찾기`가 연다.
  static const storeDiscover = '/store/discover';

  /// 사장님의 저장함(G2). 둘러보기 알림의 `보낸 관심`·`저장함`이 `?tab=`으로 탭을 알려 연다.
  static const storeInterests = '/store/interests';
  static const storeSaved = '$storeInterests?$tabParam=saved';
  static const storeSent = '$storeInterests?$tabParam=sent';

  /// 지원자 목록. 사장님 홈의 `지원자 보기`와 지원 알림이 연다(홈 위로 밀려 들어온다).
  static const storeApplicants = '/store/applicants';

  /// 지원자 추천 3명을 한 장씩 보는 옛 화면(G2). 홈에서 가는 길은 없어졌고 마지막 작업에서 지운다.
  static const storeApplicantPicks = '/store/applicants/picks';

  /// 지난 3개월 비교(G3)와 체험단 계약 정보 입력. 홈의 체험단 줄과 내 가게가 연다.
  static const storeTrialCompare = '/store/trial-compare';
  static const storeTrialInfo = '/store/me/trial-info';

  /// 제안함(F3). 사장님 하단 메뉴의 `오퍼`가 열고, 오퍼를 보낸 뒤에도 여기로 온다.
  static const storeProposals = '/store/proposals';

  /// 제안 [offerId]의 상세. 제안함이 연다.
  static String storeProposal(String offerId) =>
      '$storeProposals/${Uri.encodeComponent(offerId)}';

  /// [storeProposal]의 라우트 패턴.
  static const storeProposalPattern = '/store/proposals/:offerId';

  /// 아직 만들지 않은 가게 쪽 화면. [title]이 한글이어도 되도록 인코딩한다.
  static String storeComingSoon(String title) =>
      '/store/coming-soon/${Uri.encodeComponent(title)}';

  // 브랜드 흐름
  /// 브랜드 프로필 만들기. 프로필이 없는 브랜드의 진입 경로다.
  static const brandProfileSetup = '/brand/profile/setup';

  /// 캠페인 만들기. 프로필은 있고 진행 중인 캠페인이 없는 브랜드의 진입 경로다.
  static const brandCampaignNew = '/brand/campaign/new';

  /// 진행 중인 캠페인 고치기·마감.
  static const brandCampaignEdit = '/brand/campaign/edit';

  /// 크리에이터 [creatorId]의 상세(임시, 7번 계획의 B5가 대신한다). 카드를 누르면 열린다.
  static String brandCreator(String creatorId) =>
      '/brand/creators/${Uri.encodeComponent(creatorId)}';

  /// [brandCreator]의 라우트 패턴.
  static const brandCreatorPattern = '/brand/creators/:id';

  /// 저장함(03).
  static const brandInterests = '/brand/interests';

  /// 03의 저장 탭. 01의 `저장한 후보 보기`가 연다.
  static const brandSaved = '$brandInterests?tab=saved';

  /// 03의 보낸 관심 탭. 01의 하트 알림 `보낸 관심`이 연다.
  static const brandSent = '$brandInterests?tab=sent';

  /// 서로 관심 확인(05). 03 화면이 시트로 여는 것이라 `match` 쿼리로 협업 [collaborationId]를 알린다
  /// (알림 가는 곳 `MATCH`와 같은 모양이다).
  static String brandMatch(String collaborationId) =>
      '$brandInterests?$matchParam=${Uri.encodeQueryComponent(collaborationId)}';

  /// 03이 읽는 쿼리 이름. `tab`은 처음 고를 탭(`saved`, `sent`, 브랜드만 `proposals`), `match`는 시트로 열 협업.
  static const tabParam = 'tab';
  static const matchParam = 'match';

  /// 후보 비교(04). 03에서 고른 두 크리에이터 [a]·[b]를 견준다.
  static String brandCompare(String a, String b) =>
      '$brandInterests/compare?a=${Uri.encodeQueryComponent(a)}&b=${Uri.encodeQueryComponent(b)}';

  /// [brandCompare]의 라우트 패턴(쿼리는 패턴에 쓰지 않는다).
  static const brandComparePattern = '$brandInterests/compare';

  /// 크리에이터의 저장함(03, 크리에이터 쪽).
  static const creatorInterests = '/creator/interests';

  /// 크리에이터의 03 저장 탭. 08의 저장 알림 `저장함`이 연다.
  static const creatorSaved = '$creatorInterests?$tabParam=saved';

  /// 크리에이터의 03 보낸 관심 탭. 08의 하트 알림 `보낸 관심`이 연다.
  static const creatorSent = '$creatorInterests?$tabParam=sent';

  /// 크리에이터 쪽 서로 관심 확인(05).
  static String creatorMatch(String collaborationId) =>
      '$creatorInterests?$matchParam=${Uri.encodeQueryComponent(collaborationId)}';

  /// 조건 협의(06). 브랜드와 크리에이터 모두 협업 [collaborationId]의 최신 조건 판본을 여기서 본다.
  static String collaborationTerms(String collaborationId) =>
      '/collaborations/${Uri.encodeComponent(collaborationId)}/terms';

  /// [collaborationTerms]의 라우트 패턴.
  static const collaborationTermsPattern = '/collaborations/:id/terms';

  /// 조건 합의(12). 대화방 머리의 조건 요약이 연다(5번 계획 Task 12가 채운다).
  static String collaborationAgreement(String collaborationId) =>
      '/collaborations/${Uri.encodeComponent(collaborationId)}/agreement';

  /// [collaborationAgreement]의 라우트 패턴.
  static const collaborationAgreementPattern = '/collaborations/:id/agreement';

  /// 조건 수정 제안(Task 12). 대화방의 더하기 메뉴 `조건 수정 제안`이 연다.
  static String collaborationTermsPropose(String collaborationId) =>
      '${collaborationTerms(collaborationId)}/propose';

  /// [collaborationTermsPropose]의 라우트 패턴.
  static const collaborationTermsProposePattern =
      '/collaborations/:id/terms/propose';

  /// 12에서 수정 제안을 열 때 `extra`로 넘긴다. 보낸 뒤 12를 새로 쌓지 않고 12로 돌아간다.
  static const fromAgreement = 'fromAgreement';

  /// 협업 계약(D4). 12의 `계약서 미리 보기`·`계약하러 가기`·`계약서 보기`가 연다(5번 계획 Task 13이 채운다).
  static String collaborationContract(String collaborationId) =>
      '/collaborations/${Uri.encodeComponent(collaborationId)}/contract';

  /// [collaborationContract]의 라우트 패턴.
  static const collaborationContractPattern = '/collaborations/:id/contract';

  /// 07에서 06을 열 때 `extra`로 넘긴다. 06에서 수락하면 07을 새로 쌓지 않고 07로 돌아간다.
  static const fromProgress = 'fromProgress';

  /// 캠페인 상세(D1). 크리에이터의 08·03 카드를 누르면 열린다.
  static String creatorCampaign(String campaignId) =>
      '/creator/campaigns/${Uri.encodeComponent(campaignId)}';

  /// [creatorCampaign]의 라우트 패턴.
  static const creatorCampaignPattern = '/creator/campaigns/:id';

  /// 진행 단계(07). 브랜드와 크리에이터 모두 브랜드 협업 [collaborationId]의 여섯 단계를 여기서 본다.
  static String collaborationProgress(String collaborationId) =>
      '/collaborations/${Uri.encodeComponent(collaborationId)}/progress';

  /// [collaborationProgress]의 라우트 패턴.
  static const collaborationProgressPattern = '/collaborations/:id/progress';

  /// 브랜드의 협업 탭. 진행 중인 브랜드 협업이 하나면 곧바로 07이고, 여럿이면 목록이다.
  static const brandCollaborations = '/brand/collaborations';

  /// 브랜드 계약 [id]의 성과 확인(F4), 브랜드 쪽. 성과 추가가 있는 계약의 `조회수 집계가 끝났어요.` 알림이
  /// 연다. 크리에이터는 같은 계약을 [creatorViewReport]로 열고, 화면이 협업을 읽어 브랜드 문구로 보인다.
  static String brandViewReport(String id) =>
      '$brandCollaborations/${Uri.encodeComponent(id)}/report';

  /// [brandViewReport]의 라우트 패턴.
  static const brandViewReportPattern = '/brand/collaborations/:id/report';

  /// 07의 `남은 캠페인 예산`이 여는 제안함 자리 화면. 브랜드의 제안함(F3)은 5번 계획이 채우므로 그때까지
  /// F8의 빈 상태만 보인다.
  static const brandProposals = '/brand/proposals';

  /// 브랜드 하단 메뉴의 `프로필`. 계정·설정 계획이 만들기 전까지 역할 다시 고르기와 로그아웃만 있는 자리 화면이다.
  static const brandProfile = '/brand/profile';

  /// 아직 만들지 않은 브랜드 쪽 화면(대화와 프로필 등).
  static String brandComingSoon(String title) =>
      '/brand/coming-soon/${Uri.encodeComponent(title)}';

  // 크리에이터 흐름
  static const creatorProfileSetup = '/creator/profile/setup';

  /// 협업 원칙(09). 프로필 설정을 마치면 이어지고, 프로필에서 다시 열 수도 있다.
  static const creatorPrinciples = '/creator/principles';
  static const creatorOffers = '/creator/offers';
  static String creatorStore(String storeId) =>
      '/creator/stores/${Uri.encodeComponent(storeId)}';

  /// 가게 [storeId]에 내 방식으로 하는 제안(F6). 가게 상세 위에 밀려 들어온다.
  static String creatorStoreProposal(String storeId) =>
      '${creatorStore(storeId)}/propose';

  /// [creatorStoreProposal]의 라우트 패턴.
  static const creatorStoreProposalPattern = '/creator/stores/:id/propose';

  /// 크리에이터의 제안함(F3). 받은 오퍼의 `진행 중` 탭 맨 위 `제안함` 줄이 연다.
  static const creatorProposals = '/creator/proposals';

  /// 제안 [offerId]의 상세.
  static String creatorProposal(String offerId) =>
      '$creatorProposals/${Uri.encodeComponent(offerId)}';

  /// [creatorProposal]의 라우트 패턴.
  static const creatorProposalPattern = '/creator/proposals/:offerId';

  /// 받은 제안(10). 03 맨 위 `받은 제안` 묶음의 카드가 연다. 캠페인 [campaignId]의 브랜드가 내게 한 제안이다.
  static String creatorReceivedProposal(String campaignId) =>
      '/creator/received-proposals/${Uri.encodeComponent(campaignId)}';

  /// [creatorReceivedProposal]의 라우트 패턴.
  static const creatorReceivedProposalPattern =
      '/creator/received-proposals/:campaignId';

  /// 크리에이터의 협업 진행(A7)과 거기서 여는 링크 제출·식사권 화면.
  static String creatorCollaboration(String id) =>
      '/creator/collaborations/${Uri.encodeComponent(id)}';
  static String creatorCollaborationSubmit(String id) =>
      '${creatorCollaboration(id)}/submit';
  static String creatorVoucher(String id) =>
      '${creatorCollaboration(id)}/voucher';
  static const creatorCollaborationPattern = '/creator/collaborations/:id';

  /// 협업 [id]의 성과 확인(F4), 크리에이터 쪽. A7의 `조회 자료와 보상 계산 확인` 줄과 알림이 연다.
  static String creatorViewReport(String id) =>
      '${creatorCollaboration(id)}/report';

  /// 협업 [id]의 조회수 캡처 올리기. F4의 `캡처 올리기`가 연다.
  static String creatorViewEvidence(String id) =>
      '${creatorCollaboration(id)}/evidence';

  /// 지급받을 계좌와 인스타그램 연동. 협업 화면과 받은 오퍼 카드에서 밀려 들어온다.
  static const creatorPayoutAccount = '/creator/payout-account';
  static const creatorInstagram = '/creator/instagram';

  /// 대표 게시물(G6). 하단 `프로필` 탭과 프로필 설정의 `대표 게시물 n / 4` 줄이 연다. 홈 위에 밀려 들어온다.
  static const creatorFeaturedPosts = '/creator/featured-posts';

  /// 인스타에서 고르기. 대표 게시물 위에 밀려 들어오고, 고른 초안 목록을 돌려준다. `extra`가 `true`이면 교체(한 개만).
  static const creatorFeaturedPostsPick = '/creator/featured-posts/pick';

  /// 사진첩에서 올리기의 한 줄 설명 화면. 고른 사진(`PickedPhoto`)을 `extra`로 받고 초안 한 개를 돌려준다.
  static const creatorFeaturedPostsCompose = '/creator/featured-posts/compose';

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

  /// 브랜드 하단 메뉴의 `발견` 탭이 `/brand`에 붙이는 표시(`?from=tab`). 진행 중인 캠페인이 없을 때
  /// 진입 규칙이 협업 탭으로 보내지 않고 캠페인 만들기를 열게 한다(앱을 열 때와 로그인할 때는 규칙 그대로).
  static const fromTab = 'tab';
  static const brandDiscoverTab = '/brand?$fromParam=$fromTab';

  /// 홈이나 진입 화면으로도 쓰이는 경로(예: `/store/coming-soon/:title`)를 앱 안에서 `push`로
  /// 열 때 `extra`로 넘긴다. 넘기지 않으면 제자리에서 나타난다(진입과 구별할 수 없어서).
  static const stacked = 'stacked';

  /// 이상형 월드컵의 대결과 결과(G3). 사장님과 브랜드의 저장함이 `extra`로 판 정보를 넘겨 연다. 상태가 `extra`에만
  /// 있어서 앱을 다시 켠 뒤에는 열 수 없다(첫 화면으로 보낸다).
  static const worldCupMatch = '/world-cup/match';
  static const worldCupResult = '/world-cup/result';

  /// 대화 목록. 세 역할의 하단 메뉴 `대화`가 제자리에서 연다.
  static const chats = '/chats';

  /// 대화방 [id](D3). 목록의 줄과 알림이 연다.
  static String chat(String id) => '$chats/${Uri.encodeComponent(id)}';

  /// 메시지 요청 [id](11). 목록의 `메시지 요청` 묶음이 연다. `대화 열기`를 누르면 이 화면이 [chat]으로 바뀐다.
  static String chatRequest(String id) => '${chat(id)}/request';

  /// [chat]의 라우트 패턴.
  static const chatPattern = '$chats/:id';

  /// [chatRequest]의 라우트 패턴.
  static const chatRequestPattern = '$chats/:id/request';

  /// 개발 환경 전용 모션 갤러리. 운영 빌드에는 없다.
  static const devMotion = '/dev/motion';

  /// 개발 환경 전용 가짜 결제창. 서버의 가짜 PG(`cora-dev://fake-pay`)를 앱 안에서 연다.
  static const devFakeCheckout = '/dev/fake-checkout';

  /// 개발 환경 전용 가짜 인스타그램 연결 화면(아이디를 직접 입력한다).
  static const devFakeInstagram = '/dev/fake-instagram';

  /// 이 경로 아래는 개발 도구다. 로그인 없이 열 수 있다.
  static const devPrefix = '/dev/';
}
