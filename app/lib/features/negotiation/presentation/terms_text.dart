import '../../../core/text/josa.dart';
import '../../collaboration/domain/collaboration.dart'
    show Collaboration, CollaborationNextAction;
import '../../discovery/domain/discovery_card.dart' show MatchReason;
import '../../discovery/presentation/discovery_text.dart';
import '../../offer_terms/domain/offer_terms.dart' show ContentFormat, ViewPay;
import '../../offer_terms/presentation/offer_terms_text.dart'
    show formatLabel, won, wonExact;
import '../../principles/domain/principles.dart' show FeeBand;
import '../domain/brand_usage_rights.dart';
import '../domain/terms_version.dart';

// 브랜드 계약의 조건을 화면 문구로 바꾸는 순수 함수들. 03·04(관심·비교)가 먼저 쓰고, 06 조건 협의와 07 진행
// 단계가 같은 문구를 이어 쓴다. 캔버스 글자 그대로다. 금액은 `won`(1만 원 단위면 `30만 원`, 아니면
// `350,000원`)과 `wonLabel`(늘 `350,000원`)을 쓴다.

/// 금액 칸. 정해진 금액이 있으면 `30만 원`, 없으면 희망 제작비 구간 `30만 원대`.
String cashLabel(int? amount, FeeBand? band) {
  if (amount != null) return won(amount);
  if (band != null) return DiscoveryTexts.feeBandLabel(band);
  return '';
}

/// 03 카드 아래 글의 날짜. `11월 16일 이후`, 날짜가 없으면 `일정 협의`.
String startFromLabel(DateTime? date) =>
    date == null ? '일정 협의' : '${date.month}월 ${date.day}일 이후';

/// 04 `결과물`. `{형식} {편 수}편`, 릴스와 쇼츠는 뒤에 ` · 30초`(결과물의 길이는 고정 안내다).
String compareDeliverableLabel(ContentFormat format, int pieces) {
  final base = '${formatLabel(format)} $pieces편';
  return switch (format) {
    ContentFormat.reels || ContentFormat.shorts => '$base · 30초',
    _ => base,
  };
}

/// 04 `혜택`.
String compareBenefitLabel(bool productProvided) =>
    productProvided ? '제품 제공' : '없음';

/// 04 `성과 상한`. 성과 추가가 없으면 `없음`.
String comparePerfCapLabel(int? cap) => cap == null ? '없음' : won(cap);

/// 04 `사용권`. 06의 `usageLabel`과 다른 짧은 라벨이다(캔버스의 기간은 보여 주지 않는다).
String compareUsageLabel(BrandUsageRights rights) => switch (rights) {
  BrandUsageRights.repostOnly => '브랜드 계정 재게시',
  BrandUsageRights.adsToo => '재게시 + 광고',
  BrandUsageRights.none => '사용 안 함',
};

/// 04 `얼굴 출연`.
String compareFaceLabel(bool faceOk) => faceOk ? '있음' : '없음';

/// 07의 정확한 금액. `350,000원`(만 원 단위로 줄이지 않는다).
String wonLabel(int amount) => wonExact(amount);

/// 06 `성과 추가`. 없으면 `없음`, 있으면 `최대 6만 원`.
String perfLabel(ViewPay? performance) =>
    performance == null ? '없음' : '최대 ${won(performance.cap)}';

/// 06 `{형식 라벨}`. `릴스 1편`.
String deliverableLabel(ContentFormat format, int pieces) =>
    '${formatLabel(format)} $pieces편';

/// 06 `수정 범위`.
String revisionLabel(RevisionScope scope) => switch (scope) {
  RevisionScope.none => '없음',
  RevisionScope.guideOnce => '기획안 기준 1회',
  RevisionScope.draftOnce => '초안 기준 1회',
  RevisionScope.draftTwice => '초안 기준 2회',
};

/// 06 `콘텐츠 활용`의 요약. 04의 짧은 라벨([compareUsageLabel])과 다르다.
String usageLabel(BrandUsageRights rights) => switch (rights) {
  BrandUsageRights.repostOnly => '브랜드 계정 재게시만',
  BrandUsageRights.adsToo => '광고 소재로도 사용',
  BrandUsageRights.none => '사용 안 함',
};

/// 06 `재게시` 값. 캔버스는 `브랜드 계정만`이고, 사용하지 않기로 했으면 `사용 안 함`이다.
String repostValueLabel(BrandUsageRights rights) =>
    rights == BrandUsageRights.none ? '사용 안 함' : '브랜드 계정만';

/// 06 `광고 활용` 값. 광고 소재로도 쓰기로 했으면 `포함`, 아니면 캔버스의 `별도 협의`다.
String adsValueLabel(BrandUsageRights rights) =>
    rights == BrandUsageRights.adsToo ? '포함' : '별도 협의';

/// 06 `지급과 광고 표시`의 `지급 시점` 값. `최종 게시 후 7일 이내`.
String payoutLabel(int days) => '최종 게시 후 $days일 이내';

/// 06 `추천된 이유`의 `잘 맞는 점` 한 줄과 요약에 쓰는 이유 문구.
String reasonLabel(MatchReason reason) => reason.label;

/// 06 `수정과 촬영`의 요약. 캔버스는 `기획안 기준 1회 수정`이다(안쪽 줄 값은 [revisionLabel] 그대로). 수정이 없으면
/// `수정 없음`이다(캔버스 밖).
String revisionSummary(RevisionScope scope) =>
    scope == RevisionScope.none ? '수정 없음' : '${revisionLabel(scope)} 수정';

/// 06 `지급과 광고 표시`의 요약. 캔버스는 `최종 게시 후 7일 이내 지급`이다(안쪽 줄 값은 [payoutLabel] 그대로).
String payoutSummary(int days) => '${payoutLabel(days)} 지급';

/// 06 `팔로워`. `8,200명`.
String followersLabel(int followers) => '${_commas(followers)}명';

String _commas(int n) {
  final digits = n.abs().toString();
  final out = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}

/// 06 머리의 제목과 오른쪽 표지. [highlighted]면 내가 응답할 차례라 라임 알약이다.
class TermsHeader {
  const TermsHeader(this.title, this.badge, {this.highlighted = false});

  final String title;
  final String badge;
  final bool highlighted;

  @override
  bool operator ==(Object other) =>
      other is TermsHeader &&
      other.title == title &&
      other.badge == badge &&
      other.highlighted == highlighted;

  @override
  int get hashCode => Object.hash(title, badge, highlighted);
}

/// 06의 머리와 표지(설계 2장 표). 내 차례면 `받은 제안`, 양쪽이 확인했으면 `합의한 조건`, 그 밖(내가 확인했거나
/// 내가 낸 판본이고 상대가 아직)은 내가 낸 판본이면 `보낸 제안`, 아니면 `받은 제안`에 `상대 대기`다.
TermsHeader termsHeader({
  required int version,
  required bool myTurn,
  required bool mine,
  required bool agreed,
}) {
  if (agreed) return TermsHeader('합의한 조건 · 판본 $version', '합의 완료');
  if (myTurn) {
    return TermsHeader('받은 제안 · 판본 $version', '내가 응답할 차례', highlighted: true);
  }
  return TermsHeader('${mine ? '보낸 제안' : '받은 제안'} · 판본 $version', '상대 대기');
}

/// 06 칸 세 개 아래 안내. 성과 추가가 있으면 뒤에 환불 안내가 붙는다.
String termsAcceptNote(int maxCash, {required bool hasPerformance}) =>
    '수락하면 이 판본 조건으로 계약 준비를 시작해요. 최대 현금 부담 ${won(maxCash)}.'
    '${hasPerformance ? ' 성과 추가는 조회수만큼, 남으면 환불해요.' : ''}';

/// 07 `지금 할 일` 상자의 글. `RESPOND_TERMS` 문구는 캔버스에 없다(설계 6장 16번).
String nextActionLabel(CollaborationNextAction action) => switch (action) {
  CollaborationNextAction.respondTerms => '받은 제안 확인하고 응답하기',
  CollaborationNextAction.signContract => '계약서 확인하고 동의하기',
};

/// 07 머리 아래 한 줄. `{크리에이터 이름}과 {브랜드 이름}`(조사는 이름의 받침에 맞춘다).
String progressPair(String creatorName, String brandName) =>
    '${josa(creatorName, JosaPair.gwaWa)} $brandName';

/// 협업 목록(브랜드의 협업 탭, 크리에이터의 `진행 중`)에서 브랜드 협업 줄의 설명. 지금 할 일이 있으면 그 글,
/// 없으면 `{n} / 6 완료`다(캔버스 밖).
String brandRowSubtitle(Collaboration c) {
  final action = c.nextAction;
  if (action != null) return nextActionLabel(action);
  final progress = c.brandProgress;
  return progress == null
      ? (c.campaign?.headline ?? '')
      : TermsTexts.doneCount(progress.doneCount);
}

/// 06·07의 고정 문구와 안내. 캔버스 글자 그대로이고, 아래 표시한 것만 캔버스에 없다.
abstract final class TermsTexts {
  // 06
  static const cellFee = '현금 고정비';
  static const cellBenefit = '혜택';
  static const cellPerf = '성과 추가';
  static const groupWhy = '추천된 이유';
  static const groupEdit = '수정과 촬영';
  static const groupUse = '콘텐츠 활용';
  static const groupPay = '지급과 광고 표시';
  static const rowFit = '잘 맞는 점';
  static const rowFields = '주요 분야';
  static const rowFollowers = '팔로워';
  static const rowRevision = '수정 범위';
  static const rowExtraShoot = '추가 촬영';
  static const rowRepost = '재게시';
  static const rowAds = '광고 활용';
  static const rowPayout = '지급 시점';
  static const rowAdMark = '광고 표시';
  static const negotiable = '별도 협의';
  static const adMark = '게시물·영상에 명확히';
  static const modify = '조건 수정 제안';
  static const accept = '이 판본 수락';
  static const back = '뒤로';

  // 06 캔버스 밖: 기다리는 버튼과 연동 안내, 실패 문구
  static const waiting = '상대의 응답을 기다리고 있어요';
  static const needsInstagram = '인스타그램을 연동하면 수락할 수 있어요';
  static const connectInstagram = '연동하기';
  static const loadFailed = '조건을 불러오지 못했어요';
  static const actionFailed = '처리하지 못했어요. 다시 시도해 주세요.';

  // 07
  static const brandPill = '브랜드 관점';
  static const creatorPill = '크리에이터 관점';
  static const heading = '콘텐츠 방향을 함께 잡아요.';
  static const nextAction = '지금 할 일';
  static const secured = '이번 협업 확보액';
  static const budgetLeft = '남은 캠페인 예산';
  static const progressTitle = '진행 단계';
  static const stepNames = [
    '서로 관심 확인',
    '조건 검토 의사 표시',
    '양쪽 조건 확정·계약',
    '기획안 검토·제작',
    '광고 표시·초안 검토',
    '게시·성과 확인',
  ];
  static const waitingOther = '상대의 동의를 기다리고 있어요';
  static const waitingContract = '계약을 진행해 주세요';
  static String doneCount(int n) => '$n / 6 완료';

  // 07 캔버스 밖: 예산을 넘었을 때, 내 이름을 못 읽었을 때의 대신 글
  static String overBudget(int over) => '예산을 ${wonLabel(over)} 넘었어요.';
  static const me = '나';

  // 브랜드의 협업 탭 목록(캔버스 밖)
  static const hubTitle = '협업';
  static const hubEmpty = '아직 진행 중인 협업이 없어요.';
  static const hubLoadFailed = '진행 중인 협업을 불러오지 못했어요.';

  // 남은 캠페인 예산 자리 화면: F3 제안함의 빈 목록과 같은 글(5번 계획이 브랜드의 줄을 채우기 전까지)
  static const proposalsTitle = '제안함';
  static const proposalsEmpty = '아직 받은 제안이 없어요';
}
