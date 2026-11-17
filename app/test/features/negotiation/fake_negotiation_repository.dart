import 'dart:async';

import 'package:cora/features/discovery/domain/discovery_card.dart'
    show MatchReason;
import 'package:cora/features/negotiation/domain/brand_usage_rights.dart';
import 'package:cora/features/negotiation/domain/contract.dart';
import 'package:cora/features/payment/domain/payment_quote.dart';
import 'package:cora/features/payment/domain/payment_repository.dart'
    show PaymentMethod;
import 'package:cora/features/negotiation/domain/negotiation_repository.dart';
import 'package:cora/features/negotiation/domain/terms_version.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart'
    show ContentFormat, ViewPay;
import 'package:cora/features/proposals/domain/proposal.dart'
    show BrandContractRow, ProposalEndKind, ProposalGroup;

/// 제안함(F3)의 브랜드 계약 줄 하나. 기본은 내가 응답할 차례인 판본 1이다.
BrandContractRow brandContractRow({
  String collaborationId = 'col-1',
  String name = '모아 스튜디오',
  ProposalGroup group = ProposalGroup.myTurn,
  ContentFormat format = ContentFormat.reels,
  int pieces = 1,
  int version = 1,
  bool counter = false,
  ProposalEndKind? endKind,
  DropReason? myDropReason,
}) => BrandContractRow(
  collaborationId: collaborationId,
  name: name,
  group: group,
  format: format,
  pieces: pieces,
  version: version,
  counter: counter,
  endKind: endKind,
  myDropReason: myDropReason,
);

/// 캔버스 06의 견본 판본: 현금 30만 원, 제품 제공, 성과 추가 없음, 릴스 1편, 11월 16일 이후. 서로 관심이 닿을 때
/// 서버가 만든 판본 1이라 아무도 확인하지 않았다.
TermsVersion termsVersion({
  int version = 1,
  String title = '출근 전 30초, 오늘의 손목 루틴',
  int fee = 300000,
  bool productProvided = true,
  ViewPay? performance,
  ContentFormat format = ContentFormat.reels,
  int pieces = 1,
  RevisionScope revisionScope = RevisionScope.guideOnce,
  BrandUsageRights usageRights = BrandUsageRights.repostOnly,
  int payoutDays = 7,
  int? maxCash,
  bool brandConfirmed = false,
  bool creatorConfirmed = false,
  TermsProposer proposedBy = TermsProposer.system,
  DateTime? startDate,
  List<TermsField> changedFields = const [],
  int? previousMaxCash,
}) => TermsVersion(
  version: version,
  title: title,
  fee: fee,
  productProvided: productProvided,
  performance: performance,
  format: format,
  pieces: pieces,
  startDate: startDate ?? DateTime(2026, 11, 16),
  revisionScope: revisionScope,
  usageRights: usageRights,
  payoutDays: payoutDays,
  maxCash: maxCash ?? fee + (performance?.cap ?? 0),
  brandConfirmed: brandConfirmed,
  creatorConfirmed: creatorConfirmed,
  proposedBy: proposedBy,
  changedFields: changedFields,
  previousMaxCash: previousMaxCash,
);

/// 판본 [v]에서 확인 표시만 바꾼 사본.
TermsVersion withConfirmed(TermsVersion v, {bool? brand, bool? creator}) =>
    TermsVersion(
      version: v.version,
      title: v.title,
      fee: v.fee,
      productProvided: v.productProvided,
      performance: v.performance,
      format: v.format,
      pieces: v.pieces,
      startDate: v.startDate,
      revisionScope: v.revisionScope,
      usageRights: v.usageRights,
      payoutDays: v.payoutDays,
      maxCash: v.maxCash,
      brandConfirmed: brand ?? v.brandConfirmed,
      creatorConfirmed: creator ?? v.creatorConfirmed,
      proposedBy: v.proposedBy,
      changedFields: v.changedFields,
      createdAt: v.createdAt,
      previousMaxCash: v.previousMaxCash,
    );

/// 판본 목록(최신이 먼저)과 합의 상태. 합의 상태는 최신 판본의 확인 표시에서 정한다.
TermsHistory termsHistory(List<TermsVersion> versions, {bool editable = true}) {
  final latest = versions.first;
  return TermsHistory(
    versions: versions,
    agreement: latest.brandConfirmed && latest.creatorConfirmed
        ? TermsAgreement.agreed
        : latest.brandConfirmed
        ? TermsAgreement.waitingCreator
        : latest.creatorConfirmed
        ? TermsAgreement.waitingBrand
        : TermsAgreement.none,
    editable: editable,
  );
}

/// 캔버스 06의 견본: 내가 응답할 차례, 안내 한 줄, 이유 하나, 팔로워 8,200명.
TermsLatest termsLatest({
  TermsVersion? terms,
  bool mine = false,
  bool myTurn = true,
  bool needsInstagram = false,
  String? notice = '얼굴 출연과 제품 설명문 낭독은 진행하지 않아요.',
  List<MatchReason> reasons = const [MatchReason.field],
  List<String> fields = const ['리빙·소품', '패션'],
  int? followers = 8200,
}) => TermsLatest(
  terms: terms ?? termsVersion(),
  mine: mine,
  myTurn: myTurn,
  needsInstagram: needsInstagram,
  notice: notice,
  reasons: reasons,
  fields: fields,
  followers: followers,
);

/// 서버가 만드는 확인란 세 줄(`consentTexts`)과 같은 모양. 크리에이터의 둘째 줄은 `광고 표시 의무를 지킬게요`, 브랜드는
/// `광고 표시를 요청할게요`다.
List<String> consentTextsOf({
  required bool brand,
  int version = 2,
  String usage = '콘텐츠는 브랜드 계정 재게시에만 쓰여요',
}) => [
  '합의한 조건 버전 ${version == 2 ? '2를' : '$version을'} 확인했어요',
  brand ? '광고 표시를 요청할게요' : '광고 표시 의무를 지킬게요',
  usage,
];

/// 서버 견적을 흉내 낸 값: 제작비 35만 원 + 수수료 10%. 성과 추가 상한이 있으면 보관액에 더한다.
PaymentQuote contractQuote({
  int fixedCash = 350000,
  int? viewPayCap,
  int? fee,
}) {
  final escrow = fixedCash + (viewPayCap ?? 0);
  final feeValue = fee ?? escrow ~/ 10;
  return PaymentQuote(
    creatorName: '서윤의 작은 취향',
    creatorPhotoUrl: null,
    format: ContentFormat.reels,
    pieces: 1,
    fixedCash: fixedCash,
    viewPayCap: viewPayCap,
    escrow: escrow,
    fee: feeValue,
    total: escrow + feeValue,
  );
}

/// 캔버스 D4의 견본 계약: 합의한 버전 2, 제작비 350,000원 + 제품, 11월 23일 시작, 게시 후 7일 이내 지급.
/// [brand]는 내가 브랜드인지(확인란 문구와 견적이 달라진다).
Contract sampleContract({
  ContractStatus status = ContractStatus.awaitingCreator,
  bool brand = false,
  TermsVersion? terms,
  List<String>? texts,
  PaymentQuote? quote,
  bool voidedNotice = false,
  DateTime? concludedAt,
}) {
  final t =
      terms ??
      termsVersion(
        version: 2,
        fee: 350000,
        startDate: DateTime(2026, 11, 23),
        brandConfirmed: true,
        creatorConfirmed: true,
      );
  final preview = status == ContractStatus.notReady;
  return Contract(
    status: status,
    brandName: '모아 스튜디오',
    creatorName: '서윤의 작은 취향',
    terms: t,
    myConsentTexts: texts ?? consentTextsOf(brand: brand, version: t.version),
    voidedNotice: voidedNotice,
    quote:
        quote ??
        (brand &&
                !preview &&
                (status == ContractStatus.awaitingBrand ||
                    status == ContractStatus.paying)
            ? contractQuote(fixedCash: t.fee, viewPayCap: t.performance?.cap)
            : null),
    creatorConsentedAt:
        status == ContractStatus.awaitingBrand ||
            status == ContractStatus.paying ||
            status == ContractStatus.concluded
        ? DateTime.utc(2026, 11, 20, 3)
        : null,
    concludedAt: status == ContractStatus.concluded
        ? (concludedAt ?? DateTime.utc(2026, 11, 23, 3))
        : null,
  );
}

/// 손으로 쓴 가짜 조건 저장소. 수락하면 내 확인을 기록해 다시 읽을 때 `상대 대기`가 되게 한다.
class FakeNegotiationRepository implements NegotiationRepository {
  FakeNegotiationRepository({TermsLatest? latest, TermsHistory? history})
    : latest = latest ?? termsLatest(),
      history = history ?? termsHistory([(latest ?? termsLatest()).terms]);

  TermsLatest latest;

  /// 12가 읽는 판본 목록. 주지 않으면 [latest]의 판본 하나다.
  TermsHistory history;
  bool failFetch = false;

  /// [fetchProposalInbox]가 돌려줄 줄과 실패 여부.
  List<BrandContractRow> inbox = [];
  bool failInbox = false;
  int inboxCalls = 0;

  /// 내가 브랜드다(확인과 새 판본이 브랜드 쪽 표시를 바꾼다). false면 크리에이터다.
  bool iAmBrand = true;

  /// 설정하면 [propose]가 이 예외를 던진다. 옛 판본 예외면 [newerHistory]로 바꿔 둔다.
  Exception? proposeFailure;

  /// 옛 판본 예외 뒤 다시 읽을 때 돌려줄 목록(상대가 먼저 낸 새 판본).
  TermsHistory? newerHistory;

  final proposed = <({String id, int baseVersion, TermsChanges changes})>[];
  int historyCalls = 0;

  /// 설정하면 [confirm]이 이 예외를 던진다(옛 판본, 서버의 거절 문구, 그 밖의 실패).
  Exception? confirmFailure;

  /// 옛 판본 예외 뒤 다시 읽을 때 돌려줄 최신 판본. 설정하면 [confirm]이 실패하고 [latest]가 이것으로 바뀐다.
  TermsLatest? newerLatest;

  /// 설정하면 [drop]이 이 예외를 던진다.
  Exception? dropFailure;

  /// 설정하면 [drop]이 이 Completer가 끝날 때까지 기다린다.
  Completer<void>? holdDrop;

  /// [drop]이 성공했을 때 부르는 곳(서버가 방을 바꾸는 것을 흉내 낸다).
  void Function(String collaborationId)? onDropped;

  /// D4가 읽는 계약. 동의가 성공하면 서버처럼 바뀐다([consentAsCreator]).
  Contract contract = sampleContract();
  bool failContract = false;
  int contractCalls = 0;

  /// 설정하면 동의가 이 예외를 던진다. 옛 판본이면 [newerContract]로 바꿔 둔다.
  Exception? creatorConsentFailure;
  Exception? brandConsentFailure;
  Contract? newerContract;

  /// 브랜드 동의가 성공했을 때 부르는 곳(결제창이 열리기 전에 서버가 결제를 만드는 것을 흉내 낸다).
  void Function()? onBrandConsented;

  final creatorConsents = <({String id, int version, List<String> accepted})>[];
  final brandConsents =
      <
        ({String id, int version, List<String> accepted, PaymentMethod method})
      >[];

  int fetchCalls = 0;
  final dropped = <({String id, DropReason reason})>[];
  final confirmed = <({String id, int version})>[];

  @override
  Future<TermsLatest> fetchLatest(String collaborationId) async {
    fetchCalls++;
    if (failFetch) throw const NegotiationFailure();
    return latest;
  }

  @override
  Future<TermsHistory> fetchHistory(String collaborationId) async {
    historyCalls++;
    if (failFetch) throw const NegotiationFailure();
    return history;
  }

  @override
  Future<List<BrandContractRow>> fetchProposalInbox() async {
    inboxCalls++;
    if (failInbox) throw const NegotiationFailure();
    return List.of(inbox);
  }

  @override
  Future<TermsVersion> propose(
    String collaborationId,
    int baseVersion,
    TermsChanges changes,
  ) async {
    proposed.add((
      id: collaborationId,
      baseVersion: baseVersion,
      changes: changes,
    ));
    final failure = proposeFailure;
    if (failure != null) {
      final newer = newerHistory;
      if (newer != null) history = newer;
      throw failure;
    }
    final previous = history.latest;
    final maxCash = changes.fee + (changes.performance?.cap ?? 0);
    final made = TermsVersion(
      version: previous.version + 1,
      title: changes.title,
      fee: changes.fee,
      productProvided: changes.productProvided,
      performance: changes.performance,
      format: changes.format,
      pieces: changes.pieces,
      startDate: changes.startDate,
      revisionScope: changes.revisionScope,
      usageRights: changes.usageRights,
      payoutDays: changes.payoutDays,
      maxCash: maxCash,
      brandConfirmed: iAmBrand,
      creatorConfirmed: !iAmBrand,
      proposedBy: iAmBrand ? TermsProposer.brand : TermsProposer.creator,
      previousMaxCash: previous.maxCash,
    );
    history = termsHistory([made, ...history.versions]);
    latest = termsLatest(terms: made, mine: true, myTurn: false);
    return made;
  }

  @override
  Future<void> drop(String collaborationId, DropReason reason) async {
    dropped.add((id: collaborationId, reason: reason));
    await holdDrop?.future;
    final failure = dropFailure;
    if (failure != null) throw failure;
    onDropped?.call(collaborationId);
  }

  @override
  Future<void> confirm(String collaborationId, int version) async {
    confirmed.add((id: collaborationId, version: version));
    final failure = confirmFailure;
    if (failure != null) {
      final newer = newerLatest;
      if (newer != null) latest = newer;
      throw failure;
    }
    final marked = withConfirmed(
      history.latest,
      brand: iAmBrand ? true : null,
      creator: iAmBrand ? null : true,
    );
    history = termsHistory([marked, ...history.versions.skip(1)]);
    latest = TermsLatest(
      terms: latest.terms,
      mine: latest.mine,
      myTurn: false,
      needsInstagram: false,
      notice: latest.notice,
      reasons: latest.reasons,
      fields: latest.fields,
      followers: latest.followers,
    );
  }

  @override
  Future<Contract> fetchContract(String collaborationId) async {
    contractCalls++;
    if (failContract) throw const NegotiationFailure();
    return contract;
  }

  @override
  Future<Contract> consentAsCreator(
    String collaborationId,
    int version,
    List<String> accepted,
  ) async {
    creatorConsents.add((
      id: collaborationId,
      version: version,
      accepted: accepted,
    ));
    final failure = creatorConsentFailure;
    if (failure != null) {
      final newer = newerContract;
      if (newer != null) contract = newer;
      throw failure;
    }
    contract = sampleContract(
      status: ContractStatus.awaitingBrand,
      terms: contract.terms,
      texts: contract.myConsentTexts,
    );
    return contract;
  }

  @override
  Future<({String paymentId, String checkoutUrl})> consentAsBrand(
    String collaborationId,
    int version,
    List<String> accepted,
    PaymentMethod method,
  ) async {
    brandConsents.add((
      id: collaborationId,
      version: version,
      accepted: accepted,
      method: method,
    ));
    final failure = brandConsentFailure;
    if (failure != null) {
      final newer = newerContract;
      if (newer != null) contract = newer;
      throw failure;
    }
    onBrandConsented?.call();
    return (
      paymentId: 'pay-1',
      checkoutUrl: 'cora-dev://fake-pay?paymentId=pay-1',
    );
  }
}
