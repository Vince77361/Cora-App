import 'package:cora/features/discovery/domain/discovery_target.dart';
import 'package:cora/features/discovery/domain/reward_proposal.dart';
import 'package:cora/features/interests/domain/compare_result.dart';
import 'package:cora/features/interests/domain/interest_card.dart';
import 'package:cora/features/interests/domain/interests_repository.dart';
import 'package:cora/features/interests/domain/match_info.dart';
import 'package:cora/features/interests/domain/proposal_base.dart';
import 'package:cora/features/negotiation/domain/brand_usage_rights.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart'
    show ContentFormat, ViewPay;
import 'package:cora/features/principles/domain/principles.dart' show FeeBand;

/// 손으로 쓴 가짜 관심 저장소. 저장한 카드, 비교, 서로 관심 정보를 흉내 낸다.
class FakeInterestsRepository implements InterestsRepository {
  FakeInterestsRepository({
    List<InterestCard>? cards,
    this.compareResult,
    this.match,
    this.proposalBase,
  }) : cards = cards ?? [];

  /// 서버가 주는 저장한 카드(서버 순서).
  List<InterestCard> cards;
  CompareResult? compareResult;
  MatchInfo? match;

  /// 05의 `내가 먼저 제안하기`가 F1을 여는 데 읽는 협업의 값.
  ProposalBase? proposalBase;

  /// 설정하면 [proposeReward]가 이 예외를 던진다(옛 판본, 서버의 거절 문구, 그 밖의 실패).
  Exception? proposeFailure;
  bool failProposalBase = false;

  /// 낸 새 판본들.
  final proposed = <({String id, int baseVersion, RewardProposal proposal})>[];

  bool failFetch = false;
  bool failCompare = false;
  bool failMatch = false;

  int fetchCalls = 0;
  final compared = <({String a, String b})>[];
  final matchesFetched = <String>[];

  @override
  Future<List<InterestCard>> fetchSaved() async {
    fetchCalls++;
    if (failFetch) throw const InterestsFailure();
    return List.of(cards);
  }

  @override
  Future<CompareResult> compare(String a, String b) async {
    compared.add((a: a, b: b));
    if (failCompare) throw const InterestsFailure();
    return compareResult ?? (throw const InterestsFailure());
  }

  @override
  Future<MatchInfo> fetchMatch(String collaborationId) async {
    matchesFetched.add(collaborationId);
    if (failMatch) throw const InterestsFailure();
    return match ?? (throw const InterestsFailure());
  }

  @override
  Future<ProposalBase> fetchProposalBase(String collaborationId) async {
    if (failProposalBase) throw const InterestsFailure();
    return proposalBase ?? (throw const InterestsFailure());
  }

  @override
  Future<void> proposeReward(
    String collaborationId, {
    required int baseVersion,
    required RewardProposal proposal,
  }) async {
    proposed.add((
      id: collaborationId,
      baseVersion: baseVersion,
      proposal: proposal,
    ));
    final failure = proposeFailure;
    if (failure != null) throw failure;
  }
}

InterestCard brandCard(
  String id, {
  String? name,
  String? shortName,
  InterestState state = InterestState.waiting,
  String? headline = '출근 전 30초, 오늘의 손목 루틴',
  int? fee,
  FeeBand? feeBand = FeeBand.w300k,
  DateTime? startFrom,
  String? collaborationId,
}) => InterestCard(
  target: DiscoveryTarget.creator(id),
  name: name ?? id,
  shortName: shortName ?? name ?? id,
  headline: headline,
  state: state,
  fee: fee,
  feeBand: feeBand,
  startFrom: startFrom,
  collaborationId:
      collaborationId ?? (state == InterestState.mutual ? 'collab-$id' : null),
);

InterestCard campaignCard(
  String id, {
  String? name,
  InterestState state = InterestState.waiting,
  String? headline = '느린 결, 일상의 주얼리',
  int fee = 300000,
  DateTime? startFrom,
  String? collaborationId,
}) => InterestCard(
  target: DiscoveryTarget.campaign(id),
  name: name ?? id,
  shortName: name ?? id,
  headline: headline,
  state: state,
  fee: fee,
  startFrom: startFrom,
  collaborationId:
      collaborationId ?? (state == InterestState.mutual ? 'collab-$id' : null),
);

CompareSide compareSide(
  String id, {
  String? name,
  String? shortName,
  InterestState state = InterestState.waiting,
  ContentFormat format = ContentFormat.reels,
  int pieces = 1,
  bool productProvided = true,
  int? fee,
  FeeBand feeBand = FeeBand.w300k,
  int? perfRate,
  int? perfCap,
  BrandUsageRights usage = BrandUsageRights.repostOnly,
  DateTime? startDate,
  bool faceOk = false,
  String? collaborationId,
}) => CompareSide(
  creatorId: id,
  name: name ?? id,
  shortName: shortName ?? name ?? id,
  state: state,
  format: format,
  pieces: pieces,
  productProvided: productProvided,
  fee: fee,
  feeBand: feeBand,
  perfRate: perfRate,
  perfCap: perfCap,
  usageRights: usage,
  startDate: startDate,
  faceOk: faceOk,
  collaborationId:
      collaborationId ?? (state == InterestState.mutual ? 'collab-$id' : null),
);

MatchInfo matchInfo({
  String collaborationId = 'collab-1',
  String brandName = '모아 스튜디오',
  String? brandTagline = '느린 결, 일상의 주얼리',
  String creatorName = '서윤의 작은 취향',
  bool isBrand = true,
  int pendingProposals = 1,
  int baseVersion = 1,
}) => MatchInfo(
  collaborationId: collaborationId,
  brandName: brandName,
  brandTagline: brandTagline,
  creatorName: creatorName,
  isBrand: isBrand,
  pendingProposals: pendingProposals,
  baseVersion: baseVersion,
);

/// 05의 `내가 먼저 제안하기`가 읽는 협업의 값(릴스, 제품 제공, 30만 원, 성과 추가 없음).
ProposalBase proposalBase({
  bool proposedByBrand = true,
  ViewPay? performance,
  int fee = 300000,
}) => ProposalBase(
  counterpartName: proposedByBrand ? '서윤의 작은 취향' : '모아 스튜디오',
  recruitLine: '모아 스튜디오 · 나만의 아침 루틴 속 작은 포인트',
  format: ContentFormat.reels,
  pieces: 1,
  usageRights: BrandUsageRights.repostOnly,
  fee: fee,
  productProvided: true,
  performance: performance,
  proposedByBrand: proposedByBrand,
);
