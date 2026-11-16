import 'package:cora_api/api.dart' as api;
import 'package:flutter/foundation.dart';

import '../../../core/network/api_error.dart';

import '../../discovery/domain/discovery_target.dart';
import '../../discovery/domain/reward_proposal.dart';
import '../../negotiation/domain/brand_usage_rights.dart';
import '../../offer_terms/data/offer_terms_from_wire.dart' show formatFromWire;
import '../../offer_terms/domain/offer_terms.dart' show ViewPay;
import '../../principles/domain/principles.dart' show FeeBand;
import '../domain/compare_result.dart';
import '../domain/interest_card.dart';
import '../domain/interests_repository.dart';
import '../domain/match_info.dart';
import '../domain/proposal_base.dart';

/// 생성된 API 클라이언트(`cora_api`)로 관심 목록, 후보 비교, 서로 관심 정보를 읽는다. 생성된 타입은
/// 이 파일 밖으로 내보내지 않는다.
class ApiInterestsRepository implements InterestsRepository {
  ApiInterestsRepository(api.ApiClient client)
    : _discovery = api.DiscoveryApi(client),
      _collaborations = api.CollaborationsApi(client),
      _terms = api.TermsApi(client),
      _brands = api.BrandsApi(client),
      _creators = api.CreatorsApi(client),
      _cardDetails = api.CardDetailsApi(client);

  final api.DiscoveryApi _discovery;
  final api.CollaborationsApi _collaborations;
  final api.TermsApi _terms;
  final api.BrandsApi _brands;
  final api.CreatorsApi _creators;
  final api.CardDetailsApi _cardDetails;

  @override
  Future<List<InterestCard>> fetchSaved() => _guard(() async {
    final rows = await _discovery.listInterests(tab: api.InterestTab.saved);
    if (rows == null) throw const InterestsFailure();
    return [for (final m in rows) _card(m)];
  });

  @override
  Future<CompareResult> compare(String a, String b) => _guard(() async {
    final m = await _discovery.compareCandidates(a, b);
    if (m == null || m.sides.length != 2) throw const InterestsFailure();
    return CompareResult(
      sides: [for (final s in m.sides) _side(s)],
      differs: {for (final f in m.differs) _row(f)},
    );
  });

  @override
  Future<MatchInfo> fetchMatch(String collaborationId) => _guard(() async {
    final collaboration = await _collaborations.getCollaboration(
      collaborationId,
    );
    final latest = await _terms.getLatestTerms(collaborationId);
    if (collaboration == null || latest == null) {
      throw const InterestsFailure();
    }
    final isBrand = collaboration.role == api.CollaborationRole.COMMISSIONER;
    final counterpart = collaboration.counterpart;
    final pending = latest.myTurn ? 1 : 0;
    final baseVersion = latest.terms.version;

    if (isBrand) {
      // 브랜드 쪽: 상대(크리에이터)는 협업이 알려 주고, 내 브랜드의 이름·소개·사진은 내 프로필이다.
      final brand = await _brands.getMyBrand();
      if (brand == null) throw const InterestsFailure();
      return MatchInfo(
        collaborationId: collaborationId,
        brandName: brand.name,
        brandTagline: brand.tagline,
        brandPhotoUrl: brand.photoUrl,
        creatorName: counterpart.name,
        creatorPhotoUrl: counterpart.photoUrl,
        isBrand: true,
        pendingProposals: pending,
        baseVersion: baseVersion,
      );
    }
    // 크리에이터 쪽: 브랜드의 이름은 협업의 캠페인에, 한 줄 소개는 캠페인 상세에 있다(읽지 못하면 표지가
    // 브랜드 이름으로 대신하므로 소개만 없는 채로 둔다). 내 이름과 사진은 내 프로필이다.
    final me = await _creators.getMyCreatorProfile();
    if (me == null) throw const InterestsFailure();
    final campaignId = collaboration.campaign?.id;
    String? tagline;
    if (campaignId != null) {
      try {
        tagline = (await _cardDetails.getCampaignDetail(
          campaignId,
        ))?.brandTagline;
      } catch (_) {
        tagline = null;
      }
    }
    return MatchInfo(
      collaborationId: collaborationId,
      brandName: collaboration.campaign?.brandName ?? counterpart.name,
      brandTagline: tagline,
      brandPhotoUrl: counterpart.photoUrl,
      creatorName: me.displayName,
      creatorPhotoUrl: me.photoUrl,
      isBrand: false,
      pendingProposals: pending,
      baseVersion: baseVersion,
    );
  });

  @override
  Future<ProposalBase> fetchProposalBase(String collaborationId) => _guard(
    () async {
      final collaboration = await _collaborations.getCollaboration(
        collaborationId,
      );
      final latest = await _terms.getLatestTerms(collaborationId);
      if (collaboration == null || latest == null) {
        throw const InterestsFailure();
      }
      final t = latest.terms;
      final campaign = collaboration.campaign;
      final brandName = campaign?.brandName;
      final headline = campaign?.headline;
      final isBrand = collaboration.role == api.CollaborationRole.COMMISSIONER;
      final recruitLine = brandName == null
          ? (headline ?? '')
          : (headline == null || headline.isEmpty
                ? brandName
                : '$brandName · $headline');
      return ProposalBase(
        counterpartName: collaboration.counterpart.name,
        counterpartPhotoUrl: collaboration.counterpart.photoUrl,
        recruitLine: recruitLine,
        format: formatFromWire(t.format),
        pieces: t.pieces,
        usageRights: _usage(t.usageRights),
        fee: t.fee,
        productProvided: t.productProvided,
        performance: t.performance == null
            ? null
            : ViewPay(
                ratePerThousand: t.performance!.ratePer1000,
                cap: t.performance!.cap,
              ),
        proposedByBrand: isBrand,
      );
    },
  );

  @override
  Future<void> proposeReward(
    String collaborationId, {
    required int baseVersion,
    required RewardProposal proposal,
  }) async {
    try {
      final p = proposal.performance;
      await _terms.proposeReward(
        collaborationId,
        api.ProposeRewardDto(
          baseVersion: baseVersion,
          fee: proposal.fee,
          productProvided: proposal.productProvided,
          performance: p == null
              ? null
              : api.RewardPerformanceDto(
                  ratePer1000: p.ratePer1000,
                  cap: p.cap,
                ),
        ),
      );
    } catch (error) {
      final parsed = ApiError.from(error);
      if (kDebugMode) {
        debugPrint(
          '[interests] 제안 실패: 종류=${error.runtimeType} '
          '상태=${parsed.status} 코드=${parsed.code}',
        );
      }
      if (parsed.isStaleVersion) {
        throw RewardProposalStale(parsed.latestVersion);
      }
      // 서버가 사용자 문구와 함께 거절한 409(인스타그램 연동)와 400(바꾼 조건 없음)은 그 문구를 보인다.
      if ((parsed.isConflict || parsed.status == 400) &&
          parsed.message != null) {
        throw RewardProposalRejected(parsed.message);
      }
      throw const InterestsFailure();
    }
  }

  static BrandUsageRights _usage(api.BrandUsageRights r) => switch (r) {
    api.BrandUsageRights.REPOST_ONLY => BrandUsageRights.repostOnly,
    api.BrandUsageRights.ADS_TOO => BrandUsageRights.adsToo,
    _ => BrandUsageRights.none,
  };

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on InterestsFailure {
      rethrow;
    } catch (error) {
      // 사용자에게는 같은 실패지만 원인을 알 수 있게 종류와 상태 코드만 남긴다(응답 본문과 문구는 남기지 않는다).
      if (kDebugMode) {
        final parsed = ApiError.from(error);
        debugPrint(
          '[interests] 읽기 실패: 종류=${error.runtimeType} '
          '상태=${parsed.status} 코드=${parsed.code}',
        );
      }
      throw const InterestsFailure();
    }
  }

  static InterestCard _card(api.InterestCardModel m) => InterestCard(
    target: DiscoveryTarget(
      m.targetKind == api.SwipeTargetKind.CREATOR
          ? DiscoveryTargetKind.creator
          : DiscoveryTargetKind.campaign,
      m.targetId,
    ),
    name: m.name,
    shortName: m.shortName,
    headline: m.headline,
    photoUrl: m.photoUrl,
    state: _state(m.state),
    fee: m.feeLabel,
    feeBand: m.feeBand == null ? null : _feeBand(m.feeBand!),
    startFrom: _dateOnly(m.startFrom),
    hasProposal: m.hasProposal,
    collaborationId: m.collaborationId,
  );

  static CompareSide _side(api.CompareSideModel s) => CompareSide(
    creatorId: s.creatorId,
    name: s.name,
    shortName: s.shortName,
    photoUrl: s.photoUrl,
    state: _state(s.state),
    collaborationId: s.collaborationId,
    format: formatFromWire(s.format),
    pieces: s.pieces,
    productProvided: s.productProvided,
    fee: s.fee,
    feeBand: _feeBand(s.feeBand),
    perfCap: s.perfCap,
    usageRights: _usage(s.usageRights),
    startDate: _dateOnly(s.startDate),
    faceOk: s.faceOk,
  );

  static InterestState _state(api.InterestState s) => switch (s) {
    api.InterestState.MUTUAL => InterestState.mutual,
    api.InterestState.WAITING => InterestState.waiting,
    _ => InterestState.held,
  };

  static CompareRow _row(api.CompareField f) => switch (f) {
    api.CompareField.DELIVERABLE => CompareRow.deliverable,
    api.CompareField.BENEFIT => CompareRow.benefit,
    api.CompareField.FEE => CompareRow.fee,
    api.CompareField.PERF_CAP => CompareRow.perfCap,
    api.CompareField.USAGE => CompareRow.usage,
    api.CompareField.START => CompareRow.start,
    _ => CompareRow.face,
  };

  static FeeBand _feeBand(api.FeeBand b) => switch (b) {
    api.FeeBand.W200K => FeeBand.w200k,
    api.FeeBand.W300K => FeeBand.w300k,
    api.FeeBand.W400K => FeeBand.w400k,
    _ => FeeBand.w500kPlus,
  };

  /// 서버의 날짜(`2026-11-16`)는 시각이 없다. 어느 시간대로 읽었든 연·월·일 칸만 취해 그날의 0시로 둔다.
  static DateTime? _dateOnly(DateTime? at) =>
      at == null ? null : DateTime(at.year, at.month, at.day);
}
