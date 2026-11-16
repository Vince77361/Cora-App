import 'package:cora/features/discovery/domain/discovery_target.dart';
import 'package:cora/features/interests/domain/compare_result.dart';
import 'package:cora/features/interests/domain/interest_card.dart';
import 'package:cora/features/interests/domain/interests_repository.dart';
import 'package:cora/features/interests/domain/match_info.dart';
import 'package:cora/features/negotiation/domain/brand_usage_rights.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart'
    show ContentFormat;
import 'package:cora/features/principles/domain/principles.dart' show FeeBand;

/// 손으로 쓴 가짜 관심 저장소. 저장한 카드, 비교, 서로 관심 정보를 흉내 낸다.
class FakeInterestsRepository implements InterestsRepository {
  FakeInterestsRepository({
    List<InterestCard>? cards,
    this.compareResult,
    this.match,
  }) : cards = cards ?? [];

  /// 서버가 주는 저장한 카드(서버 순서).
  List<InterestCard> cards;
  CompareResult? compareResult;
  MatchInfo? match;

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
