import 'package:cora_api/api.dart' as api;
import 'package:flutter/foundation.dart';

import '../../../core/network/api_error.dart';
import '../../discovery/domain/discovery_card.dart' show MatchReason;
import '../../offer_terms/data/offer_terms_from_wire.dart' show formatFromWire;
import '../../offer_terms/domain/offer_terms.dart' show ViewPay;
import '../domain/brand_usage_rights.dart';
import '../domain/negotiation_repository.dart';
import '../domain/terms_version.dart';

/// 생성된 API 클라이언트(`cora_api`)로 조건 판본을 읽고 확인한다. 생성된 타입은 이 파일 밖으로 내보내지 않는다.
class ApiNegotiationRepository implements NegotiationRepository {
  ApiNegotiationRepository(api.ApiClient client)
    : _terms = api.TermsApi(client);

  final api.TermsApi _terms;

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
    followers: m.followers,
  );

  static TermsVersion _version(api.TermsVersionModel t) => TermsVersion(
    version: t.version,
    title: t.title,
    fee: t.fee,
    productProvided: t.productProvided,
    performance: t.performance == null
        ? null
        : ViewPay(
            ratePerThousand: t.performance!.ratePer1000,
            cap: t.performance!.cap,
          ),
    format: formatFromWire(t.format),
    pieces: t.pieces,
    startDate: _dateOnly(t.startDate),
    revisionScope: switch (t.revisionScope) {
      api.RevisionScope.NONE => RevisionScope.none,
      api.RevisionScope.GUIDE_1 => RevisionScope.guideOnce,
      api.RevisionScope.DRAFT_1 => RevisionScope.draftOnce,
      _ => RevisionScope.draftTwice,
    },
    usageRights: switch (t.usageRights) {
      api.BrandUsageRights.REPOST_ONLY => BrandUsageRights.repostOnly,
      api.BrandUsageRights.ADS_TOO => BrandUsageRights.adsToo,
      _ => BrandUsageRights.none,
    },
    payoutDays: t.payoutDays,
    maxCash: t.maxCash,
    brandConfirmed: t.brandConfirmed,
    creatorConfirmed: t.creatorConfirmed,
    proposedBy: switch (t.proposedBy) {
      api.TermsProposer.BRAND => TermsProposer.brand,
      api.TermsProposer.CREATOR => TermsProposer.creator,
      _ => TermsProposer.system,
    },
  );

  static MatchReason _reason(api.MatchReason r) => switch (r) {
    api.MatchReason.FIELD => MatchReason.field,
    api.MatchReason.FACE => MatchReason.face,
    api.MatchReason.SCRIPT => MatchReason.script,
    api.MatchReason.FEE => MatchReason.fee,
    _ => MatchReason.trial,
  };

  /// 서버의 날짜(`2026-11-16`)는 시각이 없다. 어느 시간대로 읽었든 연·월·일 칸만 취해 그날의 0시로 둔다.
  static DateTime _dateOnly(DateTime at) => DateTime(at.year, at.month, at.day);
}
