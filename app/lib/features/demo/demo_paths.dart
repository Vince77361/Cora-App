/// 화면 경로. artifact 화면 파일 이름(`X.dc.html`, `DarkX.dc.html`)마다 하나.
/// 이 파일은 조율 세션만 고친다.
abstract final class DemoPaths {
  /// E1 로그인 (`NLogin.dc.html`)
  static const login = '/login';

  /// E2 휴대폰 인증 (`NVerify.dc.html`)
  static const verify = '/verify';

  /// A1 시작 · 역할 선택 (`NRole.dc.html`)
  static const role = '/role';

  /// 01 발견 · 브랜드 관점 (`Main.dc.html`)
  static const brandDiscover = '/brand-discover';

  /// 02 넘기기 이유 (`Pass.dc.html`)
  static const pass = '/pass';

  /// 03 관심·보류 (`Likes.dc.html`)
  static const likes = '/likes';

  /// 04 후보 비교 (`Compare.dc.html`)
  static const compare = '/compare';

  /// 05 서로 관심 확인 (`Match.dc.html`)
  static const match = '/match';

  /// 06 조건 협의 (`Terms.dc.html`)
  static const terms = '/terms';

  /// 07 진행 단계 (`Progress.dc.html`)
  static const progress = '/progress';

  /// 09 협업 원칙 (`Principles.dc.html`)
  static const principles = '/principles';

  /// 10 콘텐츠 기반 제안 (`Proposal.dc.html`)
  static const proposal = '/proposal';

  /// 11 다이렉트 대화 (`Chat.dc.html`)
  static const chat = '/chat';

  /// D3 대화방 (`NChatThread.dc.html`)
  static const chatThread = '/chat-thread';

  /// 12 조건 합의·변경 기록 (`Agreement.dc.html`)
  static const agreement = '/agreement';

  /// D4 최종 계약 (`NContract.dc.html`)
  static const contract = '/contract';

  /// 13 기획 가이드 (`Guide.dc.html`)
  static const guide = '/guide';

  /// 14 초안 검토 (`Review.dc.html`)
  static const review = '/review';

  /// 15 회고·재협업 (`Retro.dc.html`)
  static const retro = '/retro';

  /// D5 다시 만나고 싶은 브랜드 (`NKeepList.dc.html`)
  static const keepList = '/keep-list';

  /// 08 크리에이터의 발견 (`CreatorDiscover.dc.html`)
  static const creatorDiscover = '/creator-discover';

  /// D1 캠페인 상세 · 크리에이터 (`NCampaign.dc.html`)
  static const campaign = '/campaign';

  /// D2 가게 오퍼 상세 · 크리에이터 (`NStoreView.dc.html`)
  static const storeView = '/store-view';

  /// A6 받은 오퍼 · 크리에이터 (`NOfferInbox.dc.html`)
  static const offerInbox = '/offer-inbox';

  /// A7 에스크로 결제·지급 (`NEscrow.dc.html`)
  static const escrow = '/escrow';

  /// B6 콘텐츠 올리기 (논의 중) (`NUpload.dc.html`)
  static const upload = '/upload';

  /// B2 크리에이터 포트폴리오 (논의 중) (`NProfile.dc.html`)
  static const profile = '/profile';

  /// B3 인스타그램 연동 (논의 중) (`NInstagram.dc.html`)
  static const instagram = '/instagram';

  /// B5 다른 크리에이터 프로필 (논의 중) (`NCreatorView.dc.html`)
  static const creatorView = '/creator-view';

  /// A2 가게 링크 입력 (`NStoreLink.dc.html`)
  static const storeLink = '/store-link';

  /// A3 자동 생성된 가게 페이지 (`NStorePage.dc.html`)
  static const storePage = '/store-page';

  /// A4 AI 콘텐츠 초안 (`NStoreAI.dc.html`)
  static const storeAI = '/store-a-i';

  /// A9 사장님 홈 (`NStoreHome.dc.html`)
  static const storeHome = '/store-home';

  /// B1 릴스 피드 탐색 (논의 중) (`NReels.dc.html`)
  static const reels = '/reels';

  /// A5 오퍼 보내기 (3단계) (`NOffer.dc.html`)
  static const offer = '/offer';

  /// A8 가게 결제 (에스크로) (`NPay.dc.html`)
  static const pay = '/pay';

  /// B4 스와이프 입찰 (논의 중) (`NBidding.dc.html`)
  static const bidding = '/bidding';

  /// B7 입찰 결과 (논의 중) (`NBidResult.dc.html`)
  static const bidResult = '/bid-result';

  /// E3 알림 (`NNotify.dc.html`)
  static const notify = '/notify';

  /// E4 설정 (`NSettings.dc.html`)
  static const settings = '/settings';

  /// E5 알림 설정 (`NNotifySettings.dc.html`)
  static const notifySettings = '/notify-settings';

  /// E6 프로필 수정 (`NEditProfile.dc.html`)
  static const editProfile = '/edit-profile';

  /// E7 정산 (`NWallet.dc.html`)
  static const wallet = '/wallet';

  /// E8 고객센터 (`NHelp.dc.html`)
  static const help = '/help';

  /// F1 보상·예산 설정 (`NBudget.dc.html`, 2026-11-12 캔버스)
  static const budget = '/budget';

  /// F2 제안 보내기 전 검토 (`NReviewSend.dc.html`, 2026-11-12 캔버스)
  static const reviewSend = '/review-send';

  /// F3 제안함 (`NProposals.dc.html`, 2026-11-12 캔버스)
  static const proposals = '/proposals';

  /// F4 조회 자료와 보상 계산 (`NMetrics.dc.html`, 2026-11-12 캔버스)
  static const metrics = '/metrics';

  /// F7 매장 직접 입력 (`NStoreManual.dc.html`, 2026-11-12 캔버스)
  static const storeManual = '/store-manual';

  /// F8 빈 상태·오류 (`NStates.dc.html`, 2026-11-12 캔버스)
  static const states = '/states';

  /// G1 7일 결과 (`NResult.dc.html`, 2026-11-12 캔버스)
  static const result = '/result';

  /// G2 지원자 추천 3명 (`NApplicants.dc.html`, 2026-11-12 캔버스)
  static const applicants = '/applicants';

  /// G3 체험단 재계약 전 비교 (`NSwitchReport.dc.html`, 2026-11-12 캔버스)
  static const switchReport = '/switch-report';

  /// F5 Cora AI 제작 승인 (`NAIOrder.dc.html`, 2026-11-12 캔버스)
  static const aiOrder = '/ai-order';

  /// F6 크리에이터 역제안 (`NCounter.dc.html`, 2026-11-12 캔버스)
  static const counter = '/counter';

  /// C1 외부 리스트 검색 (`NDirectory.dc.html`)
  static const directory = '/directory';

  /// C2 미가입 계정에 연락 (`NOutreach.dc.html`)
  static const outreach = '/outreach';

  /// 모든 화면 경로. 화면 전체를 도는 테스트가 쓴다.
  static const List<String> all = [
    login,
    verify,
    role,
    brandDiscover,
    pass,
    likes,
    compare,
    match,
    terms,
    progress,
    principles,
    proposal,
    chat,
    chatThread,
    agreement,
    contract,
    guide,
    review,
    retro,
    keepList,
    creatorDiscover,
    campaign,
    storeView,
    offerInbox,
    escrow,
    upload,
    profile,
    instagram,
    creatorView,
    storeLink,
    storePage,
    storeAI,
    storeHome,
    reels,
    offer,
    pay,
    bidding,
    bidResult,
    notify,
    settings,
    notifySettings,
    editProfile,
    wallet,
    help,
    directory,
    outreach,
  ];

  /// artifact 링크(`NSettings.dc.html`, `DarkNSettings.dc.html`)를 경로로 바꾼다.
  static String forCanvas(String file) {
    var n = file.replaceAll('.dc.html', '');
    if (n.startsWith('Dark')) n = n.substring(4);
    return _byCanvas[n] ?? login;
  }

  static const Map<String, String> _byCanvas = {
    'NLogin': login,
    'NVerify': verify,
    'NRole': role,
    'Main': brandDiscover,
    'Pass': pass,
    'Likes': likes,
    'Compare': compare,
    'Match': match,
    'Terms': terms,
    'Progress': progress,
    'Principles': principles,
    'Proposal': proposal,
    'Chat': chat,
    'NChatThread': chatThread,
    'Agreement': agreement,
    'NContract': contract,
    'Guide': guide,
    'Review': review,
    'Retro': retro,
    'NKeepList': keepList,
    'CreatorDiscover': creatorDiscover,
    'NCampaign': campaign,
    'NStoreView': storeView,
    'NOfferInbox': offerInbox,
    'NEscrow': escrow,
    'NUpload': upload,
    'NProfile': profile,
    'NInstagram': instagram,
    'NCreatorView': creatorView,
    'NStoreLink': storeLink,
    'NStorePage': storePage,
    'NStoreAI': storeAI,
    'NStoreHome': storeHome,
    'NReels': reels,
    'NOffer': offer,
    'NPay': pay,
    'NBidding': bidding,
    'NBidResult': bidResult,
    'NNotify': notify,
    'NSettings': settings,
    'NNotifySettings': notifySettings,
    'NEditProfile': editProfile,
    'NWallet': wallet,
    'NHelp': help,
    'NBudget': budget,
    'NReviewSend': reviewSend,
    'NProposals': proposals,
    'NMetrics': metrics,
    'NStoreManual': storeManual,
    'NStates': states,
    'NResult': result,
    'NApplicants': applicants,
    'NSwitchReport': switchReport,
    'NAIOrder': aiOrder,
    'NCounter': counter,
    'NDirectory': directory,
    'NOutreach': outreach,
  };
}
