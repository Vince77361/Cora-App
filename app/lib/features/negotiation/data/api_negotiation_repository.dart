import 'package:cora_api/api.dart' as api;
import 'package:flutter/foundation.dart';

import '../../../core/network/api_error.dart';
import '../../discovery/domain/discovery_card.dart' show MatchReason;
import '../domain/negotiation_repository.dart';
import '../domain/terms_version.dart';
import 'terms_version_from_wire.dart';

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
