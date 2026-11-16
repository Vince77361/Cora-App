import '../../negotiation/domain/brand_usage_rights.dart';
import 'offer_terms.dart';

/// 제안(조건)을 만드는 화면(F1 보상·예산 설정, F2 보내기 전 검토)이 누구에게 무엇을 만드는지.
///
/// provider 인자로 쓰이므로 값이 같으면 같은 대상이다. 같은 대상의 F1과 F2는 고르는 중인
/// 조건을 함께 쓴다.
sealed class ProposalTarget {
  const ProposalTarget();

  /// 이번에 만들어질 판본 번호. 새로 보내는 오퍼와 모집 조건은 1이다.
  int get versionNumber;
}

/// 가게의 모집 조건. 받는 사람이 없고 공개된다.
final class RecruitTarget extends ProposalTarget {
  const RecruitTarget();

  @override
  int get versionNumber => 1;

  @override
  bool operator ==(Object other) => other is RecruitTarget;

  @override
  int get hashCode => (RecruitTarget).hashCode;
}

/// 크리에이터에게 새로 보내는 오퍼. 지원자에게 보내거나(G2), 끝난 협업의 크리에이터에게 다시 보낸다(G1).
///
/// 고르는 조건은 [start]에서 시작한다. 주지 않으면 가게의 모집 조건에서 시작한다. G1의 `다시 만나기`가
/// 지난 협업의 조건을 [start]로 준다.
final class NewOfferTarget extends ProposalTarget {
  const NewOfferTarget({
    required this.creatorId,
    required this.creatorName,
    this.start,
  });

  final String creatorId;
  final String creatorName;

  /// 고르는 조건의 처음 값(지난 협업의 조건).
  final OfferTerms? start;

  @override
  int get versionNumber => 1;

  @override
  bool operator ==(Object other) =>
      other is NewOfferTarget &&
      other.creatorId == creatorId &&
      other.creatorName == creatorName &&
      other.start == start;

  @override
  int get hashCode =>
      Object.hash(NewOfferTarget, creatorId, creatorName, start);
}

/// 받은 제안에 사장님이 답으로 내는 새 판본(Task 12가 쓴다). 고르는 조건은 [start](그 제안의 최신 판본 조건)에서
/// 시작한다. 주지 않으면 서버 설정의 기본값에서 시작한다.
final class ReplyTarget extends ProposalTarget {
  const ReplyTarget({
    required this.offerId,
    required this.counterpartName,
    required this.nextVersion,
    this.start,
  });

  final String offerId;
  final String counterpartName;
  final int nextVersion;

  /// 고르는 조건의 처음 값(최신 판본의 조건).
  final OfferTerms? start;

  @override
  int get versionNumber => nextVersion;

  @override
  bool operator ==(Object other) =>
      other is ReplyTarget &&
      other.offerId == offerId &&
      other.counterpartName == counterpartName &&
      other.nextVersion == nextVersion &&
      other.start == start;

  @override
  int get hashCode =>
      Object.hash(ReplyTarget, offerId, counterpartName, nextVersion, start);
}

/// 크리에이터가 가게의 모집 조건이나 받은 오퍼에 내는 역제안(Task 10이 쓴다). 새 제안이면
/// [storeId]를, 받은 오퍼에 답하는 판본이면 [offerId]를 준다. 고르는 조건은 [start](가게의 모집 조건)에서
/// 시작한다. 주지 않으면 서버 설정의 기본값에서 시작한다.
final class CounterTarget extends ProposalTarget {
  const CounterTarget({
    this.storeId,
    this.offerId,
    required this.storeName,
    required this.nextVersion,
    this.start,
  }) : assert(
         (storeId == null) != (offerId == null),
         'storeId or offerId, not both',
       );

  final String? storeId;
  final String? offerId;
  final String storeName;
  final int nextVersion;

  /// 고르는 조건의 처음 값(가게의 모집 조건).
  final OfferTerms? start;

  @override
  int get versionNumber => nextVersion;

  @override
  bool operator ==(Object other) =>
      other is CounterTarget &&
      other.storeId == storeId &&
      other.offerId == offerId &&
      other.storeName == storeName &&
      other.nextVersion == nextVersion &&
      other.start == start;

  @override
  int get hashCode => Object.hash(
    CounterTarget,
    storeId,
    offerId,
    storeName,
    nextVersion,
    start,
  );
}

/// 브랜드 계약의 보상 제안(4번 계획 Task 10b). 서로 관심 전에는 크리에이터에게 관심과 함께 보내고(04),
/// 서로 관심 뒤에는 협업의 새 판본으로 낸다(05). 같은 F1·F2 화면을 쓰되 줄 이름, 범위, 사용권, 이용료율을
/// 이 대상이 정한다. 가게를 읽지 않는다.
///
/// 고르는 값은 [startFee], [startProductProvided], [startPerformance]에서 시작한다. 성과 추가는 주지 않으면
/// 꺼져 있다. 사용권은 그 판본의 값이라 화면에서 고칠 수 없다.
final class BrandProposalTarget extends ProposalTarget {
  const BrandProposalTarget({
    required this.recipientName,
    required this.recruitLine,
    required this.format,
    required this.usageRights,
    required this.startFee,
    required this.startProductProvided,
    this.startPerformance,
    this.pieces = 1,
    this.nextVersion = 1,
    this.proposedByBrand = true,
  });

  /// 받는 사람의 이름(크리에이터의 활동 이름, 크리에이터가 내면 브랜드 이름).
  final String recipientName;

  /// F2의 `모집` 줄. `{브랜드 이름} · {캠페인 한 줄}`.
  final String recruitLine;

  /// 캠페인의 형식. 블로그 글이면 성과 추가를 켤 수 없다.
  final ContentFormat format;
  final int pieces;

  /// 고칠 수 없는 사용권.
  final BrandUsageRights usageRights;

  final int startFee;
  final bool startProductProvided;
  final ViewPay? startPerformance;
  final int nextVersion;

  /// 브랜드가 내는 제안이다. 크리에이터가 내면 이용료 문장이 없다(이용료는 브랜드가 낸다).
  final bool proposedByBrand;

  /// 제품 제공 여부를 담는 표지. 초안은 가게와 같은 [OfferTerms]를 쓰므로 `제품 제공`을 이름만 있는
  /// 혜택으로 둔다. 금액이 없어 현금 부담에 들어가지 않는다.
  static const productVoucher = Voucher(name: '제품 제공', value: 0);

  /// 현금 고정비의 빠른 선택. 서버 범위(1만~1,000만 원)에 맞춘 화면의 편의 값이다.
  static const fixedCashPresets = [100000, 300000, 500000, 1000000];

  /// F1이 시작하는 조건.
  OfferTerms get startTerms => OfferTerms(
    format: format,
    pieces: pieces,
    reward: Reward(
      voucher: startProductProvided ? productVoucher : null,
      fixedCash: startFee,
      viewPay: format == ContentFormat.blog ? null : startPerformance,
    ),
  );

  @override
  int get versionNumber => nextVersion;

  @override
  bool operator ==(Object other) =>
      other is BrandProposalTarget &&
      other.recipientName == recipientName &&
      other.recruitLine == recruitLine &&
      other.format == format &&
      other.pieces == pieces &&
      other.usageRights == usageRights &&
      other.startFee == startFee &&
      other.startProductProvided == startProductProvided &&
      other.startPerformance == startPerformance &&
      other.nextVersion == nextVersion &&
      other.proposedByBrand == proposedByBrand;

  @override
  int get hashCode => Object.hash(
    BrandProposalTarget,
    recipientName,
    recruitLine,
    format,
    pieces,
    usageRights,
    startFee,
    startProductProvided,
    startPerformance,
    nextVersion,
    proposedByBrand,
  );
}

/// 보내는 쪽이 F2에 돌려주는 실패. F2는 [message]가 있으면 그것을, 없으면 자기 기본 문구를 보인다
/// (보내는 화면마다 실패 이유에 맞는 말이 다르다: 예, 이미 보낸 오퍼가 있어요).
class ProposalSendFailure implements Exception {
  const ProposalSendFailure([this.message]);

  final String? message;

  @override
  String toString() => 'ProposalSendFailure';
}
