import 'package:cora_api/api.dart' as api;
import 'package:flutter/foundation.dart';

import '../../../core/network/api_error.dart';
import '../../discovery/domain/discovery_card.dart' show MatchReason;
import '../../offer_terms/data/offer_terms_from_wire.dart' show formatToWire;
import '../domain/brand_usage_rights.dart';
import '../domain/negotiation_repository.dart';
import '../domain/terms_version.dart';
import 'terms_version_from_wire.dart';

/// 생성된 API 클라이언트(`cora_api`)로 조건 판본을 읽고 확인한다. 생성된 타입은 이 파일 밖으로 내보내지 않는다.
class ApiNegotiationRepository implements NegotiationRepository {
  ApiNegotiationRepository(api.ApiClient client)
    : _terms = api.TermsApi(client),
      _collaborations = api.CollaborationsApi(client);

  final api.TermsApi _terms;
  final api.CollaborationsApi _collaborations;

  @override
  Future<TermsLatest> fetchLatest(String collaborationId) async {
    try {
      final m = await _terms.getLatestTerms(collaborationId);
      if (m == null) throw const NegotiationFailure();
      return _latest(m);
    } on NegotiationFailure {
      rethrow;
    } catch (error) {
      _log('읽기', error);
      throw const NegotiationFailure();
    }
  }

  @override
  Future<TermsHistory> fetchHistory(String collaborationId) async {
    try {
      final m = await _terms.listTermsVersions(collaborationId);
      if (m == null || m.versions.isEmpty) throw const NegotiationFailure();
      return TermsHistory(
        versions: [for (final v in m.versions) _version(v)],
        agreement: switch (m.agreement) {
          api.TermsAgreement.NONE => TermsAgreement.none,
          api.TermsAgreement.WAITING_BRAND => TermsAgreement.waitingBrand,
          api.TermsAgreement.WAITING_CREATOR => TermsAgreement.waitingCreator,
          _ => TermsAgreement.agreed,
        },
        editable: m.editable,
      );
    } on NegotiationFailure {
      rethrow;
    } catch (error) {
      _log('목록 읽기', error);
      throw const NegotiationFailure();
    }
  }

  @override
  Future<TermsVersion> propose(
    String collaborationId,
    int baseVersion,
    TermsChanges changes,
  ) async {
    try {
      final performance = changes.performance;
      final made = await _terms.proposeReward(
        collaborationId,
        api.ProposeRewardDto(
          baseVersion: baseVersion,
          title: changes.title,
          fee: changes.fee,
          productProvided: changes.productProvided,
          // 빠지면(null) 서버는 `끄기`로 읽는다. 안 바꾼 성과 추가도 이 값으로 명시한다.
          performance: performance == null
              ? null
              : api.RewardPerformanceDto(
                  ratePer1000: performance.ratePerThousand,
                  cap: performance.cap,
                ),
          startDate: changes.startDate,
          format: formatToWire(changes.format),
          pieces: changes.pieces,
          revisionScope: switch (changes.revisionScope) {
            RevisionScope.none => api.RevisionScope.NONE,
            RevisionScope.guideOnce => api.RevisionScope.GUIDE_1,
            RevisionScope.draftOnce => api.RevisionScope.DRAFT_1,
            RevisionScope.draftTwice => api.RevisionScope.DRAFT_2,
          },
          usageRights: switch (changes.usageRights) {
            BrandUsageRights.repostOnly => api.BrandUsageRights.REPOST_ONLY,
            BrandUsageRights.adsToo => api.BrandUsageRights.ADS_TOO,
            BrandUsageRights.none => api.BrandUsageRights.NONE,
          },
          payoutDays: changes.payoutDays,
        ),
      );
      if (made == null) throw const NegotiationFailure();
      return _version(made);
    } on NegotiationFailure {
      rethrow;
    } catch (error) {
      final parsed = _log('수정 제안', error);
      if (parsed.isStaleVersion) throw NegotiationStale(parsed.latestVersion);
      // 서버가 사용자 문구와 함께 거절한 409(결제 진행 중, 인스타그램 연동)와 400(바꾼 조건 없음)은 그 문구를 보인다.
      final status = parsed.status;
      if ((parsed.isConflict || status == 400) &&
          status != null &&
          status < 500) {
        throw NegotiationRejected(parsed.message);
      }
      throw const NegotiationFailure();
    }
  }

  @override
  Future<void> confirm(String collaborationId, int version) async {
    try {
      await _terms.confirmTerms(collaborationId, version);
    } catch (error) {
      final parsed = _log('수락', error);
      if (parsed.isStaleVersion) throw NegotiationStale(parsed.latestVersion);
      // 서버가 사용자 문구와 함께 거절한 409(인스타그램 연동)는 그 문구를 보인다. 5xx 본문은 보이지 않는다.
      final status = parsed.status;
      if (parsed.isConflict && status != null && status < 500) {
        throw NegotiationRejected(parsed.message);
      }
      throw const NegotiationFailure();
    }
  }

  @override
  Future<void> drop(String collaborationId, DropReason reason) async {
    try {
      await _collaborations.dropCollaboration(
        collaborationId,
        api.DropCollaborationDto(reason: _dropReason(reason)),
      );
    } catch (error) {
      final parsed = _log('그만두기', error);
      // 지금은 그만둘 수 없다는 409는 서버가 사용자 문구를 준다(5xx 본문은 보이지 않는다).
      final status = parsed.status;
      if (parsed.isConflict && status != null && status < 500) {
        throw NegotiationRejected(parsed.message);
      }
      throw const NegotiationFailure();
    }
  }

  static api.DropReasonChoice _dropReason(DropReason reason) =>
      switch (reason) {
        DropReason.schedule => api.DropReasonChoice.SCHEDULE,
        DropReason.budget => api.DropReasonChoice.BUDGET,
        DropReason.direction => api.DropReasonChoice.DIRECTION,
        DropReason.other => api.DropReasonChoice.OTHER,
      };

  /// 원인만 한 줄 남긴다(응답 본문과 문구는 남기지 않는다).
  static ApiError _log(String action, Object error) {
    final parsed = ApiError.from(error);
    if (kDebugMode) {
      debugPrint(
        '[negotiation] $action 실패: 종류=${error.runtimeType} '
        '상태=${parsed.status} 코드=${parsed.code}',
      );
    }
    return parsed;
  }

  static TermsLatest _latest(api.TermsLatestModel m) => TermsLatest(
    terms: _version(m.terms),
    mine: m.mine,
    myTurn: m.myTurn,
    needsInstagram: m.needsInstagram,
    notice: m.notice,
    reasons: [for (final r in m.reasons) _reason(r)],
    fields: List.of(m.fields),
    followers: m.followers,
  );

  static TermsVersion _version(api.TermsVersionModel t) =>
      termsVersionFromWire(t);

  static MatchReason _reason(api.MatchReason r) => switch (r) {
    api.MatchReason.FIELD => MatchReason.field,
    api.MatchReason.FACE => MatchReason.face,
    api.MatchReason.SCRIPT => MatchReason.script,
    api.MatchReason.FEE => MatchReason.fee,
    _ => MatchReason.trial,
  };
}
