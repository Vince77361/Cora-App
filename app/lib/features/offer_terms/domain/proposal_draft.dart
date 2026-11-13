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

/// 지원한 크리에이터에게 새로 보내는 오퍼.
final class NewOfferTarget extends ProposalTarget {
  const NewOfferTarget({required this.creatorId, required this.creatorName});

  final String creatorId;
  final String creatorName;

  @override
  int get versionNumber => 1;

  @override
  bool operator ==(Object other) =>
      other is NewOfferTarget &&
      other.creatorId == creatorId &&
      other.creatorName == creatorName;

  @override
  int get hashCode => Object.hash(NewOfferTarget, creatorId, creatorName);
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

/// 보내는 쪽이 F2에 돌려주는 실패. F2는 [message]가 있으면 그것을, 없으면 자기 기본 문구를 보인다
/// (보내는 화면마다 실패 이유에 맞는 말이 다르다: 예, 이미 보낸 오퍼가 있어요).
class ProposalSendFailure implements Exception {
  const ProposalSendFailure([this.message]);

  final String? message;

  @override
  String toString() => 'ProposalSendFailure';
}
