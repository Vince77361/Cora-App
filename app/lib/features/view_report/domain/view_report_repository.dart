import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'view_report.dart';

/// 조회 자료 확인(F4)을 읽고 확인·이의 제기·캡처 제출을 하는 포트. 쓰는 쪽은 협업 ID 하나만 안다.
abstract class ViewReportRepository {
  /// 협업 [collaborationId]의 조회 자료. 없거나 내 것이 아니면 [ViewReportFailure.notFound]다.
  Future<ViewReport> fetch(String collaborationId);

  /// 맡기는 쪽이 `자료 확인했어요`를 누른다. 정산이 이어진다.
  Future<ViewReport> confirm(String collaborationId);

  /// 이의를 낸다([reason]은 1~200자). 운영팀이 확인할 때까지 지급이 멈춘다.
  Future<ViewReport> dispute(String collaborationId, String reason);

  /// 크리에이터가 인사이트 캡처([path]는 올린 사진의 저장 위치)와 거기 적힌 조회수를 낸다.
  Future<ViewReport> submitEvidence(
    String collaborationId,
    String path,
    int views,
  );
}

/// 서버에 닿지 못했거나 서버가 거절했다.
///
/// [message]는 서버가 화면에 그대로 보이라고 보낸 문구다(4xx일 때만). 서버 내부 오류(5xx)나 연결
/// 문제는 문구 없이 [message]가 null이라 화면이 일반 문구를 쓴다.
class ViewReportFailure implements Exception {
  const ViewReportFailure({
    this.notFound = false,
    this.conflict = false,
    this.message,
  });

  /// 서버가 404로 답했다(볼 수 없는 협업이다).
  final bool notFound;

  /// 서버가 409로 답했다(그사이 바뀌었거나 지금은 할 수 없다).
  final bool conflict;
  final String? message;

  @override
  String toString() =>
      'ViewReportFailure(notFound: $notFound, conflict: $conflict)';
}

/// 기본값은 일부러 던진다. main.dart가 API 구현으로, 테스트가 가짜로 바꿔 끼운다.
final viewReportRepositoryProvider = Provider<ViewReportRepository>(
  (ref) => throw UnimplementedError(
    'viewReportRepositoryProvider must be overridden',
  ),
);
