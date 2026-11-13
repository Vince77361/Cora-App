import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/offers/domain/offer_view.dart';
import 'package:cora/features/proposals/domain/offer_version.dart';
import 'package:cora/features/proposals/domain/proposal.dart';
import 'package:cora/features/proposals/domain/proposal_repository.dart';

const reelsTerms = OfferTerms(
  format: ContentFormat.reels,
  reward: Reward(
    voucher: Voucher(name: '식사권', value: 40000, people: 2),
    viewPay: ViewPay(ratePerThousand: 2000, cap: 60000),
  ),
);

ProposalRow proposalRow({
  String offerId = 'p1',
  String name = '하루 한 컵',
  ProposalGroup group = ProposalGroup.myTurn,
  ContentFormat format = ContentFormat.cardNews,
  int version = 2,
  bool counter = true,
  int? daysLeft,
  ProposalEndKind? endKind,
  EndReason? endReason,
  String? collaborationId,
}) => ProposalRow(
  offerId: offerId,
  name: name,
  group: group,
  format: format,
  pieces: 1,
  version: version,
  counter: counter,
  daysLeft: daysLeft,
  endKind: endKind,
  endReason: endReason,
  collaborationId: collaborationId,
);

ProposalDetail proposalDetail({
  String offerId = 'p1',
  ProposalParty myParty = ProposalParty.store,
  ProposalGroup group = ProposalGroup.myTurn,
  OfferView status = OfferView.waiting,
  OfferVersion? latest,
  OfferVersion? previous,
  Set<ProposalField> changed = const {},
  bool needsInstagram = false,
  ProposalEndKind? endKind,
  EndReason? endReason,
  String? collaborationId,
  String counterpartName = '하루 한 컵',
}) => ProposalDetail(
  offerId: offerId,
  myParty: myParty,
  group: group,
  status: status,
  counterpart: ProposalPerson(name: counterpartName),
  storeId: '1',
  storeName: '한그릇 라멘',
  latest:
      latest ??
      const OfferVersion(
        number: 2,
        authorParty: ProposalParty.creator,
        terms: reelsTerms,
        idea: '첫 숟가락을 클로즈업해요',
        principles: ['손만나옴'],
        series: OfferVersionSeries(
          name: '한 그릇 일기',
          format: ContentFormat.reels,
          note: '30초 릴스 · 손 중심',
        ),
      ),
  previous: previous,
  changed: changed,
  expiresAt: DateTime.utc(2026, 11, 15),
  feeRate: 10,
  needsInstagram: needsInstagram,
  endKind: endKind,
  endReason: endReason,
  collaborationId: collaborationId,
);

/// 손으로 쓴 가짜 제안함 저장소. 목록과 상세를 주고, 수락·끝내기·새 판본을 기록한다.
class FakeProposalRepository implements ProposalRepository {
  FakeProposalRepository({
    List<ProposalRow>? active,
    List<ProposalRow>? ended,
    Map<String, ProposalDetail>? details,
  }) : active = active ?? [],
       ended = ended ?? [],
       details = details ?? {};

  List<ProposalRow> active;
  List<ProposalRow> ended;
  Map<String, ProposalDetail> details;

  bool failFetch = false;
  ProposalFailure? failAccept;
  ProposalFailure? failEnd;
  ProposalFailure? failReply;
  ProposalFailure? failCancel;

  /// 수락이 돌려주는 협업 id.
  String? acceptedCollaborationId = 'collab-1';

  final accepted = <({String offerId, int version})>[];
  final endedWith = <({String offerId, EndReason reason})>[];
  final replies = <({String offerId, OfferTerms terms})>[];
  final cancelled = <String>[];

  /// 수락·끝내기·새 판본 뒤에 부른다(서버가 상세를 바꾼 것을 흉내 내려고).
  void Function(String offerId)? afterChange;

  @override
  Future<List<ProposalRow>> fetch(ProposalTab tab) async {
    if (failFetch) throw const ProposalFailure();
    return List.of(tab == ProposalTab.active ? active : ended);
  }

  @override
  Future<ProposalDetail> fetchDetail(String offerId) async {
    if (failFetch) throw const ProposalFailure();
    final detail = details[offerId];
    if (detail == null) throw const ProposalFailure(notFound: true);
    return detail;
  }

  @override
  Future<String?> accept(String offerId, int version) async {
    final failure = failAccept;
    if (failure != null) throw failure;
    accepted.add((offerId: offerId, version: version));
    afterChange?.call(offerId);
    return acceptedCollaborationId;
  }

  @override
  Future<void> end(String offerId, EndReason reason) async {
    final failure = failEnd;
    if (failure != null) throw failure;
    endedWith.add((offerId: offerId, reason: reason));
    afterChange?.call(offerId);
  }

  @override
  Future<void> cancel(String offerId) async {
    final failure = failCancel;
    if (failure != null) throw failure;
    cancelled.add(offerId);
    afterChange?.call(offerId);
  }

  @override
  Future<void> reply(String offerId, OfferTerms terms) async {
    final failure = failReply;
    if (failure != null) throw failure;
    replies.add((offerId: offerId, terms: terms));
    afterChange?.call(offerId);
  }
}
