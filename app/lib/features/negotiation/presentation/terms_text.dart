import '../../../core/text/josa.dart';
import '../../../core/text/count_and_date_labels.dart';
import '../../collaboration/domain/collaboration.dart'
    show Collaboration, CollaborationNextAction;
import '../../discovery/domain/discovery_card.dart' show MatchReason;
import '../../discovery/presentation/discovery_text.dart';
import '../../offer_terms/domain/offer_terms.dart' show ContentFormat, ViewPay;
import '../../offer_terms/presentation/offer_terms_text.dart'
    show brandViewPayLine, formatLabel, won, wonExact;
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
    date == null ? '일정 협의' : afterDateLabel(date);

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
String followersLabel(int followers) => '${withCommas(followers)}명';

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

// ---- 12 조건 합의·변경 기록과 조건 수정 제안 ----

/// 12·수정 제안의 항목 이름. 변경 기록 줄에도 이 이름을 쓴다(`제작비·일정`).
String fieldName(TermsField field) => switch (field) {
  TermsField.title => '콘텐츠 제목',
  TermsField.fee => '제작비',
  TermsField.performance => '성과 추가',
  TermsField.startDate => '일정',
  TermsField.deliverable => '제작물',
  TermsField.product => '제품 제공',
  TermsField.revision => '수정 범위',
  TermsField.usage => '활용 권한',
  TermsField.payout => '지급 조건',
};

/// 12 조건 칸의 이름. 변경 기록 줄은 [fieldName]의 `일정`을, 칸은 캔버스의 `제작 시작`을 쓴다.
String cellName(TermsField field) =>
    field == TermsField.startDate ? '제작 시작' : fieldName(field);

/// 12 `제작 시작`의 날짜. `11월 23일`(날짜만 뜻이 있다).
String monthDayLabel(DateTime date) => '${date.month}월 ${date.day}일';

/// 수정 제안의 제작 시작 고르기 줄. `11월 23일 (월)`.
String startDateOptionLabel(DateTime date) =>
    '${monthDayLabel(date)} (${'월화수목금토일'[date.weekday - 1]})';

/// 12 `지급 조건`. `게시 후 7일 이내`.
String payoutTermLabel(int days) => '게시 후 $days일 이내';

/// 12 `성과 추가`. `1,000회당 2,000원 · 최대 60,000원`, 없으면 `없음`.
String performanceLabel(TermsVersion terms) {
  final p = terms.performance;
  return p == null ? '없음' : brandViewPayLine(p);
}

/// 12 `제품 제공`. `포함` / `미포함`.
String productLabel(bool provided) => provided ? '포함' : '미포함';

/// 12의 항목 값(캔버스 글자: 금액은 만 원 단위로 줄이지 않는다).
String termsFieldValue(TermsField field, TermsVersion t) => switch (field) {
  TermsField.title => t.title,
  TermsField.fee => wonExact(t.fee),
  TermsField.performance => performanceLabel(t),
  TermsField.startDate => monthDayLabel(t.startDate),
  TermsField.deliverable => deliverableLabel(t.format, t.pieces),
  TermsField.product => productLabel(t.productProvided),
  TermsField.revision => revisionLabel(t.revisionScope),
  TermsField.usage => usageLabel(t.usageRights),
  TermsField.payout => payoutTermLabel(t.payoutDays),
};

/// 바뀐 항목의 이전 값. 화면은 이 값에 취소선을 긋고 뒤에 `에서 변경`을 붙인다.
String changedFromValue(TermsField field, TermsVersion previous) =>
    termsFieldValue(field, previous);

/// 바뀐 항목의 새 값 아래 글. `300,000원에서 변경`.
String changedFromLabel(TermsField field, TermsVersion previous) =>
    '${changedFromValue(field, previous)}에서 변경';

/// 12 `최대 현금 부담` 줄의 값. 앞 판본과 값이 다르면 `300,000원 → 350,000원`, 같거나 판본 1이면 `350,000원`.
String maxCashLine(TermsVersion terms) {
  final previous = terms.previousMaxCash;
  return previous == null || previous == terms.maxCash
      ? wonExact(terms.maxCash)
      : '${wonExact(previous)} → ${wonExact(terms.maxCash)}';
}

/// 12 변경 기록 한 줄의 글(앞의 `버전 n`은 따로 그린다). 판본 1은 `브랜드의 최초 제안`, 그 뒤는
/// `내가 제작비·일정 수정 제안` / `브랜드가 수정 범위 수정 제안`이다. [counterpartRoleName]은 상대의 이름표다
/// (`브랜드` / `크리에이터`).
String historyText(
  TermsVersion terms, {
  required bool mine,
  required String counterpartRoleName,
}) {
  if (terms.version == 1) {
    return terms.proposedBy == TermsProposer.creator
        ? '크리에이터의 최초 제안'
        : '브랜드의 최초 제안';
  }
  final who = mine ? '내가' : '$counterpartRoleName가';
  final fields = terms.changedFields.map(fieldName).join('·');
  return fields.isEmpty ? '$who 수정 제안' : '$who $fields 수정 제안';
}

/// 변경 기록 한 줄 전체. `버전 2 · 내가 제작비·일정 수정 제안`.
String historyLine(
  TermsVersion terms, {
  required bool mine,
  required String counterpartRoleName,
}) =>
    '버전 ${terms.version} · '
    '${historyText(terms, mine: mine, counterpartRoleName: counterpartRoleName)}';

/// 12 머리 상자의 상태.
String agreementStatus(TermsAgreement agreement) => switch (agreement) {
  TermsAgreement.waitingBrand => '브랜드 확인 대기 중',
  TermsAgreement.waitingCreator => '크리에이터 확인 대기 중',
  TermsAgreement.none => '양쪽 확인 대기 중',
  TermsAgreement.agreed => '합의됨',
};

/// 12 머리 상자의 확인 표시. `나 · 확인함` / `브랜드 · 대기`.
String confirmLine(String who, {required bool confirmed}) =>
    '$who · ${confirmed ? '확인함' : '대기'}';

/// 12 맨 아래 안내. 판본 1은 뒤 문장만, 2 이상이면 앞 판본의 수락이 이 판본에 적용되지 않는다는 말이 붙는다.
String versionNotice(int version) => version <= 1
    ? '합의 기록과 최종 계약 체결은 별도예요.'
    : '버전 ${version - 1}에 했던 수락은 버전 $version에 적용되지 않아요. 합의 기록과 최종 계약 체결은 별도예요.';

/// 수정 제안을 보낸 뒤 12에서 잠깐 보이는 알림. `조건 버전 3을 제안했어요.`
String proposedToast(int version) =>
    '${josa('조건 버전 $version', JosaPair.eulReul)} 제안했어요.';

/// 수정 제안 머리 아래 글. `버전 2를 바탕으로 고쳐요.`
String proposalBasis(int version) =>
    '${josa('버전 $version', JosaPair.eulReul)} 바탕으로 고쳐요.';

/// 12·수정 제안의 고정 문구. 캔버스(Agreement) 글자 그대로이고, 아래 표시한 것만 캔버스에 없다.
abstract final class AgreementTexts {
  static const title = '조건 합의';
  static const maxCash = '최대 현금 부담';
  static const heading = '대화에서 정한 조건';
  static const legend = '초록색은 이번 버전에서 바뀐 조건이에요.';
  static const history = '변경 기록';
  static const adMark = '광고 표시';
  static const adMarkValue = '영상·게시물에 명확히';
  static const modify = '수정 제안';
  static const preview = '계약서 미리 보기';
  static const accept = '이 버전 수락';
  static const me = '나';
  static const brand = '브랜드';
  static const creator = '크리에이터';

  // 캔버스 밖(설계·계획 문구)
  static const goContract = '계약하러 가기';
  static const viewContract = '계약서 보기';
  static const afterContract = '계약한 뒤에는 조건을 바꿀 수 없어요.';
  static const ended = '협의가 끝난 조건이에요.';
  static const dropMenu = '협의 그만두기';
  static const menu = '더보기';
  static const needsInstagram = '인스타그램을 연동하면 수락할 수 있어요';
  static const connectInstagram = '연동하기';
  static const loadFailed = '조건을 불러오지 못했어요';
  static const actionFailed = '처리하지 못했어요. 다시 시도해 주세요.';

  // 수정 제안(캔버스 없음)
  static const proposalTitle = '조건 수정 제안';
  static const send = '제안 보내기';
  static const sendFailed = '제안을 보내지 못했어요. 다시 시도해 주세요.';
  static const staleProposal = '상대가 먼저 새 조건을 제안했어요. 최신 조건을 확인해 주세요.';
  static const titleHelp = '40자까지 쓸 수 있어요.';
  static const pieces = '편 수';
  static const format = '형식';
  static const startPick = '날짜 고르기';
  static const changedDot = '바뀐 항목';
}
