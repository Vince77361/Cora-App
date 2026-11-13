import '../../offer_terms/domain/offer_terms.dart';
import '../../offers/domain/offer_view.dart';
import 'offer_version.dart';

/// 제안함의 두 탭.
enum ProposalTab { active, ended }

/// 제안함 묶음. 진행 중 탭은 [myTurn] → [waiting], 종료 탭은 [ended]다.
enum ProposalGroup { myTurn, waiting, ended }

/// 끝난 제안의 갈래. 합의해 협업이 생겼거나, 사유를 골라 끝냈거나, 기한이 지났다.
enum ProposalEndKind { agreed, ended, expired }

/// 제안을 끝낼 때 고르는 사유 네 가지.
enum EndReason { schedule, terms, otherPartner, noReason }

/// 앞 판본과 달라진 항목. 화면이 보여 주는 순서다.
enum ProposalField {
  format,
  voucher,
  fixedCash,
  viewPay,
  usageRights,
  idea,
  principles,
  series,
}

/// 제안함의 줄 하나. 서버가 내 차례인지 묶음까지 정해서 준다.
class ProposalRow {
  const ProposalRow({
    required this.offerId,
    required this.name,
    required this.group,
    required this.format,
    required this.pieces,
    required this.version,
    this.photoUrl,
    this.counter = false,
    this.daysLeft,
    this.endKind,
    this.endReason,
    this.collaborationId,
  });

  final String offerId;

  /// 상대의 이름. 사장님에게는 크리에이터, 크리에이터에게는 가게다.
  final String name;
  final String? photoUrl;
  final ProposalGroup group;
  final ContentFormat format;
  final int pieces;

  /// 최신 판본의 번호.
  final int version;

  /// 상대가 쓴 최신 판본이 2번 이상이다(역제안).
  final bool counter;

  /// 상대 대기일 때 남은 응답 기한(올림). 하루가 안 남았으면 0.
  final int? daysLeft;
  final ProposalEndKind? endKind;
  final EndReason? endReason;

  /// 합의해 만들어진 협업. 합의 전이면 null.
  final String? collaborationId;
}

/// 제안 상세에 보이는 상대.
class ProposalPerson {
  const ProposalPerson({required this.name, this.photoUrl});

  final String name;
  final String? photoUrl;
}

/// 제안 상세. 당사자 둘 다 읽는다.
class ProposalDetail {
  const ProposalDetail({
    required this.offerId,
    required this.myParty,
    required this.group,
    required this.status,
    required this.counterpart,
    required this.storeId,
    required this.storeName,
    required this.latest,
    required this.expiresAt,
    required this.feeRate,
    this.recruitLine,
    this.previous,
    this.changed = const {},
    this.needsInstagram = false,
    this.endKind,
    this.endReason,
    this.collaborationId,
  });

  final String offerId;
  final ProposalParty myParty;
  final ProposalGroup group;
  final OfferView status;

  /// 상대. 사장님에게는 크리에이터, 크리에이터에게는 가게의 사장님이다(이름과 사진은 가게의 것).
  final ProposalPerson counterpart;
  final String storeId;
  final String storeName;

  /// 가게의 한 줄 모집 문구. 없을 수 있다.
  final String? recruitLine;
  final OfferVersion latest;
  final OfferVersion? previous;
  final Set<ProposalField> changed;
  final DateTime expiresAt;

  /// 결제 때 더해지는 수수료율(%). 사장님에게만 보인다.
  final int feeRate;

  /// 답을 기다리는 제안이고 조회수 수당이 켜져 있는데 크리에이터가 인스타그램을 연동하지 않았다.
  final bool needsInstagram;
  final ProposalEndKind? endKind;
  final EndReason? endReason;
  final String? collaborationId;

  bool get myTurn => group == ProposalGroup.myTurn;
  bool get waiting => group == ProposalGroup.waiting;
  bool get ended => group == ProposalGroup.ended;
}
