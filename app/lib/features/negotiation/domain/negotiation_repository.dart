import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'terms_version.dart';

/// 협업의 조건 판본을 읽고 확인(수락)하는 포트(06). 협업 자체는 `CollaborationRepository`가 읽는다.
abstract class NegotiationRepository {
  /// 협업 [collaborationId]의 최신 판본. 실패하면 [NegotiationFailure].
  Future<TermsLatest> fetchLatest(String collaborationId);

  /// 판본 [version]을 확인한다. 그사이 새 판본이 나왔으면 [NegotiationStale], 서버가 사용자 문구와 함께
  /// 거절하면(인스타그램 연동 필요 등) [NegotiationRejected], 그 밖의 실패는 [NegotiationFailure]다.
  Future<void> confirm(String collaborationId, int version);
}

/// 수락하려던 판본이 최신이 아니다(409 `STALE_VERSION`). [latestVersion]은 서버가 알려 준 최신 판본
/// 번호이고 알 수 없으면 null이다.
class NegotiationStale implements Exception {
  const NegotiationStale(this.latestVersion);

  final int? latestVersion;

  @override
  String toString() => 'NegotiationStale(latestVersion: $latestVersion)';
}

/// 서버가 사용자에게 보일 문구와 함께 거절했다(인스타그램을 연동하지 않았을 때 등).
class NegotiationRejected implements Exception {
  const NegotiationRejected(this.message);

  final String? message;

  @override
  String toString() => 'NegotiationRejected';
}

/// 서버와 주고받지 못했다. 서버 응답의 문구는 담지 않는다.
class NegotiationFailure implements Exception {
  const NegotiationFailure();

  @override
  String toString() => 'NegotiationFailure';
}

/// 기본값은 일부러 던진다. main.dart가 API 구현으로, 테스트가 가짜로 바꿔 끼운다.
final negotiationRepositoryProvider = Provider<NegotiationRepository>(
  (ref) => throw UnimplementedError(
    'negotiationRepositoryProvider must be overridden',
  ),
);
