import '../../discovery/domain/discovery_card.dart' show MatchReason;
import '../../offer_terms/domain/offer_terms.dart' show ContentFormat, ViewPay;
import 'brand_usage_rights.dart';

/// 수정 범위. 서버의 `RevisionScope`와 같다.
enum RevisionScope { none, guideOnce, draftOnce, draftTwice }

/// 조건 판본을 낸 쪽. [system]은 서로 관심이 닿을 때 서버가 만든 판본 1이다.
enum TermsProposer { brand, creator, system }

/// 조건의 아홉 항목(광고 표시는 고정이라 없다). 서버의 `TermsField`와 같고, 항상 이 순서다.
enum TermsField {
  title,
  fee,
  performance,
  startDate,
  deliverable,
  product,
  revision,
  usage,
  payout,
}

/// 최신 판본의 확인 상태. 서버의 `TermsAgreement`와 같다.
enum TermsAgreement { none, waitingBrand, waitingCreator, agreed }

/// 브랜드 계약의 조건 판본 하나. 서버의 `TermsVersionModel`과 같은 항목이고, 앱은 다시 계산하지 않는다.
class TermsVersion {
  const TermsVersion({
    required this.version,
    required this.title,
    required this.fee,
    required this.productProvided,
    required this.format,
    required this.pieces,
    required this.startDate,
    required this.revisionScope,
    required this.usageRights,
    required this.payoutDays,
    required this.maxCash,
    required this.brandConfirmed,
    required this.creatorConfirmed,
    required this.proposedBy,
    this.performance,
    this.changedFields = const [],
    this.createdAt,
    this.previousMaxCash,
  });

  final int version;

  /// 콘텐츠 제목(40자까지).
  final String title;

  /// 현금 고정비(원).
  final int fee;
  final bool productProvided;

  /// 성과 추가(조회수 수당). 없으면 null.
  final ViewPay? performance;
  final ContentFormat format;
  final int pieces;

  /// 제작 시작. 날짜만 뜻이 있어 그날의 0시로 둔다.
  final DateTime startDate;
  final RevisionScope revisionScope;
  final BrandUsageRights usageRights;

  /// 게시 뒤 지급까지 걸리는 날(7 또는 14).
  final int payoutDays;

  /// 최대 현금 부담 = 현금 고정비 + 성과 추가 상한(없으면 0).
  final int maxCash;
  final bool brandConfirmed;
  final bool creatorConfirmed;
  final TermsProposer proposedBy;

  /// 바로 앞 판본과 달라진 항목(고정 순서). 판본 1은 비어 있다.
  final List<TermsField> changedFields;

  /// 판본이 만들어진 시각. 모르면 null.
  final DateTime? createdAt;

  /// 바로 앞 판본의 최대 현금 부담. 판본 1이면 null이다.
  final int? previousMaxCash;

  /// 양쪽이 확인했다.
  bool get agreed => brandConfirmed && creatorConfirmed;
}

/// 협업의 최신 조건 판본과 그것을 보는 내 처지(06). 서버의 `TermsLatestModel`과 같다.
class TermsLatest {
  const TermsLatest({
    required this.terms,
    required this.mine,
    required this.myTurn,
    required this.needsInstagram,
    this.notice,
    this.reasons = const [],
    this.fields = const [],
    this.followers,
  });

  final TermsVersion terms;

  /// 최신 판본을 내가 냈다.
  final bool mine;

  /// 최신 판본을 내가 아직 확인하지 않았다.
  final bool myTurn;

  /// 내가 크리에이터이고, 성과 추가가 켜져 있고, 형식이 릴스나 카드뉴스이고, 인스타그램이 연동돼 있지 않다.
  final bool needsInstagram;

  /// 크리에이터의 협업 원칙에서 만든 안내 줄. 없으면 null.
  final String? notice;

  /// 크리에이터의 협업 원칙과 캠페인이 겹치는 규칙.
  final List<MatchReason> reasons;

  /// 크리에이터가 협업 원칙에서 고른 분야의 이름표(고른 순서). 원칙이 없으면 빈 목록이다.
  final List<String> fields;

  /// 크리에이터가 연동한 인스타그램의 팔로워 수. 연동이 없으면 null.
  final int? followers;
}

/// 협업의 조건 판본 목록과 합의 상태(12). 서버의 `TermsHistoryModel`과 같다.
class TermsHistory {
  const TermsHistory({
    required this.versions,
    required this.agreement,
    required this.editable,
  });

  /// 판본 목록. 최신이 먼저다.
  final List<TermsVersion> versions;
  final TermsAgreement agreement;

  /// 지금 조건 수정 제안을 낼 수 있다(협의할 수 있는 단계이고 브랜드 결제가 진행 중이 아니다).
  final bool editable;

  TermsVersion get latest => versions.first;

  /// [latest] 바로 앞 판본. 판본 1이면 null이다.
  TermsVersion? get previous => versions.length > 1 ? versions[1] : null;
}

/// 새 판본으로 보낼 조건 전체. 바꾼 항목만이 아니라 아홉 항목을 모두 담는다: 생성된 클라이언트는 빈 칸을 null로
/// 보내고 서버는 `performance: null`을 `성과 추가 끄기`로 읽어서, 안 바꾼 성과 추가도 명시해야 꺼지지 않는다.
class TermsChanges {
  const TermsChanges({
    required this.title,
    required this.fee,
    required this.productProvided,
    required this.performance,
    required this.startDate,
    required this.format,
    required this.pieces,
    required this.revisionScope,
    required this.usageRights,
    required this.payoutDays,
  });

  final String title;
  final int fee;
  final bool productProvided;

  /// 성과 추가. 없으면 null(끔).
  final ViewPay? performance;
  final DateTime startDate;
  final ContentFormat format;
  final int pieces;
  final RevisionScope revisionScope;
  final BrandUsageRights usageRights;
  final int payoutDays;
}
