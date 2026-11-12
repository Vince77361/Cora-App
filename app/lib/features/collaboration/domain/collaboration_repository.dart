import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'collaboration.dart';

/// 협업을 읽고 제출·취소하는 포트.
abstract class CollaborationRepository {
  /// 진행 중인 협업(결제 대기·보관 중·집계 중·멈춤).
  Future<List<Collaboration>> fetchActive();

  /// 끝난 협업(정산 완료·환급·취소·중단). 최근 것부터.
  Future<List<Collaboration>> fetchDone();

  Future<Collaboration> fetch(String id);

  /// 올린 콘텐츠의 링크를 낸다. 성공하면 집계가 시작된 협업을 돌려준다.
  Future<Collaboration> submitLink(String id, String url);

  /// 크리에이터가 협업을 그만둔다(돈이 보관된 단계에서만).
  Future<void> cancel(String id);

  /// 사장님이 취소를 요청한다.
  Future<void> requestCancel(String id);

  /// 크리에이터가 사장님의 취소 요청에 동의한다.
  Future<void> acceptCancel(String id, String requestId);
}

/// 서버에 닿지 못했거나 서버가 거절했다.
///
/// [message]는 서버가 화면에 그대로 보이라고 보낸 문구다(4xx일 때만). 서버 내부 오류(5xx)나 연결
/// 문제는 문구 없이 [message]가 null이라 화면이 일반 문구를 쓴다.
class CollaborationFailure implements Exception {
  const CollaborationFailure({this.conflict = false, this.message});

  /// 서버가 409로 답했다(이미 처리됐거나 지금은 할 수 없다).
  final bool conflict;
  final String? message;

  @override
  String toString() => 'CollaborationFailure(conflict: $conflict)';
}

/// 기본값은 일부러 던진다. main.dart가 API 구현으로, 테스트가 가짜로 바꿔 끼운다.
final collaborationRepositoryProvider = Provider<CollaborationRepository>(
  (ref) => throw UnimplementedError(
    'collaborationRepositoryProvider must be overridden',
  ),
);
