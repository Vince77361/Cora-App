import 'package:flutter/foundation.dart';

import 'demo_paths.dart';

/// 시연 앱이 지금 어느 역할로 들어와 있는지. A1 역할 고르기에서 정하고, 로그아웃하면 비운다.
/// 실제 앱은 한 역할이 다른 역할의 화면을 볼 수 없으므로, 링크와 하단 메뉴는 이 값으로 길을 고른다.
/// 비어 있으면(경로로 바로 연 화면 확인, 테스트) 화면을 가리지 않고 캔버스 링크를 그대로 따른다.
enum DemoRole {
  store('가게 사장님'),
  brand('브랜드'),
  creator('크리에이터');

  const DemoRole(this.label);

  /// 설정 화면 같은 곳에 쓰는 이름.
  final String label;
}

final ValueNotifier<DemoRole?> demoRole = ValueNotifier<DemoRole?>(null);

/// 화면 묶음. 기술 스택 설계 1장 표와 공통 모델 14장의 역할별 화면 구성을 따른다.
final Set<String> _account = {
  DemoPaths.login,
  DemoPaths.verify,
  DemoPaths.role,
  DemoPaths.notify,
  DemoPaths.settings,
  DemoPaths.notifySettings,
  DemoPaths.help,
};

/// 대화·조건 합의·계약·초안 검토: 역할이 함께 쓴다.
final Set<String> _shared = {
  DemoPaths.chat,
  DemoPaths.chatThread,
  DemoPaths.agreement,
  DemoPaths.contract,
  DemoPaths.review,
};

final Set<String> _storeOnly = {
  DemoPaths.storeLink,
  DemoPaths.storePage,
  DemoPaths.storeAI,
  DemoPaths.storeHome,
  DemoPaths.offer,
  DemoPaths.pay,
  DemoPaths.bidding,
  DemoPaths.bidResult,
  DemoPaths.directory,
  DemoPaths.outreach,
};

/// B1·B5는 맡기는 쪽(사장님·브랜드)이 함께 쓴다.
final Set<String> _storeAndBrand = {DemoPaths.reels, DemoPaths.creatorView};

final Set<String> _brandOnly = {
  DemoPaths.brandDiscover,
  DemoPaths.pass,
  DemoPaths.likes,
  DemoPaths.compare,
  DemoPaths.match,
  DemoPaths.terms,
};

/// 진행 단계(07)는 브랜드와 크리에이터가 함께 본다(공통 모델 14장 "협업" 탭).
final Set<String> _brandAndCreator = {DemoPaths.progress};

final Set<String> _creatorOnly = {
  DemoPaths.creatorDiscover,
  DemoPaths.principles,
  DemoPaths.proposal,
  DemoPaths.guide,
  DemoPaths.retro,
  DemoPaths.keepList,
  DemoPaths.campaign,
  DemoPaths.storeView,
  DemoPaths.offerInbox,
  DemoPaths.escrow,
  DemoPaths.upload,
  DemoPaths.profile,
  DemoPaths.instagram,
  DemoPaths.editProfile,
  DemoPaths.wallet,
};

/// [role]이 열 수 있는 화면 경로.
Set<String> demoAllowedPaths(DemoRole role) => switch (role) {
  DemoRole.store => {..._account, ..._shared, ..._storeOnly, ..._storeAndBrand},
  DemoRole.brand => {
    ..._account,
    ..._shared,
    ..._brandOnly,
    ..._storeAndBrand,
    ..._brandAndCreator,
  },
  DemoRole.creator => {
    ..._account,
    ..._shared,
    ..._creatorOnly,
    ..._brandAndCreator,
  },
};

/// 지금 역할이 이 화면(경로)을 열 수 있는가. 역할이 없으면 모두 열 수 있다.
bool demoCanOpenPath(String path) {
  final role = demoRole.value;
  return role == null || demoAllowedPaths(role).contains(path);
}

/// artifact 파일 이름(`NWallet.dc.html`)으로 묻는 [demoCanOpenPath].
bool demoCanOpen(String canvasFile) =>
    demoCanOpenPath(DemoPaths.forCanvas(canvasFile));

/// 역할의 홈. 다른 역할의 화면으로 가던 링크의 마지막 대비책이다.
String demoHomePath(DemoRole role) => switch (role) {
  DemoRole.store => DemoPaths.storeHome,
  DemoRole.brand => DemoPaths.brandDiscover,
  DemoRole.creator => DemoPaths.creatorDiscover,
};

/// 다른 역할의 화면으로 가던 링크를 같은 역할의 가장 가까운 화면으로 바꾼다.
/// 키는 `'화면>가려던 화면'`이고 `*`는 어느 화면에서든이다. 화면에서 온 키가 먼저다.
/// 여기에 없는 링크가 걸리면 역할 홈으로 보내고 [demoRedirectFallbacks]에 남긴다(테스트가 비어 있음을 확인한다).
final Map<DemoRole, Map<String, String>> _redirects = {
  DemoRole.store: {
    // A5 오퍼 보내기: 캔버스는 크리에이터의 받은 오퍼(A6)로 간다.
    '${DemoPaths.offer}>${DemoPaths.offerInbox}': DemoPaths.storeHome,
    // D4 계약 → 진행 단계: 사장님에게는 진행 단계가 없다.
    '*>${DemoPaths.progress}': DemoPaths.storeHome,
    // 14 초안 검토 → 회고: 회고는 크리에이터 화면이다.
    '*>${DemoPaths.retro}': DemoPaths.storeHome,
    // 조건 협의(06)는 브랜드 화면. 사장님의 조건은 오퍼 보내기에서 다룬다.
    '*>${DemoPaths.terms}': DemoPaths.offer,
    // 콘텐츠 제안(10)은 크리에이터 화면.
    '*>${DemoPaths.proposal}': DemoPaths.agreement,
  },
  DemoRole.brand: {
    '*>${DemoPaths.retro}': DemoPaths.progress,
    '*>${DemoPaths.proposal}': DemoPaths.terms,
    // B1·B5의 "오퍼 보내기"는 사장님의 A5. 브랜드는 조건 협의로 간다.
    '*>${DemoPaths.offer}': DemoPaths.terms,
  },
  DemoRole.creator: {
    // 넘기기 이유(02)는 브랜드 화면. 크리에이터는 발견으로 돌아간다.
    '*>${DemoPaths.pass}': DemoPaths.creatorDiscover,
    // 관심·보류(03)는 브랜드 화면. 크리에이터의 보관함(D5)으로 간다.
    '*>${DemoPaths.likes}': DemoPaths.keepList,
    // 서로 관심 확인(05)은 브랜드 화면. 대화로 간다.
    '*>${DemoPaths.match}': DemoPaths.chat,
    // 조건 협의(06)는 브랜드 화면. 크리에이터는 제안(10)으로 간다.
    '*>${DemoPaths.terms}': DemoPaths.proposal,
    // D2의 "가게 정보"는 사장님의 가게 페이지(A3). 크리에이터는 이 화면에 머문다.
    '${DemoPaths.storeView}>${DemoPaths.storePage}': DemoPaths.storeView,
  },
};

/// 역할 홈으로 보낸 링크 기록(`화면>가려던 화면`). 테스트가 쓴다.
@visibleForTesting
final List<String> demoRedirectFallbacks = [];

/// [from]에서 [to]로 가는 링크가 지금 역할에서 가야 할 화면 경로.
String demoResolvePath(String from, String to) {
  final role = demoRole.value;
  if (role == null || demoAllowedPaths(role).contains(to)) return to;
  final table = _redirects[role]!;
  final hit = table['$from>$to'] ?? table['*>$to'];
  if (hit != null) return hit;
  demoRedirectFallbacks.add('$from>$to');
  return demoHomePath(role);
}
