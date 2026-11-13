import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'applicant_pick.dart';

/// 지원자 추천(G2)을 읽고 추천에서 넘기는 포트.
abstract class ApplicantPicksRepository {
  Future<ApplicantPicks> fetchPicks();

  /// 추천에서 넘긴다. 지원 자체는 그대로고 지원자 목록에 남는다.
  Future<void> skip(String applicationId);
}

/// 서버에 닿지 못했거나 서버가 거절했다. 서버 응답의 문구는 담지 않는다.
class ApplicantPicksFailure implements Exception {
  const ApplicantPicksFailure();

  @override
  String toString() => 'ApplicantPicksFailure';
}

/// 기본값은 일부러 던진다. main.dart가 API 구현으로, 테스트가 가짜로 바꿔 끼운다.
final applicantPicksRepositoryProvider = Provider<ApplicantPicksRepository>(
  (ref) => throw UnimplementedError(
    'applicantPicksRepositoryProvider must be overridden',
  ),
);
