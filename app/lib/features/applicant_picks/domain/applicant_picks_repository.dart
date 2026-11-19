import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'applicant_pick.dart';

/// 사장님 홈의 `추천 3명`(지원자 추천 G2)을 읽는 포트. 쓰기는 없다(넘기기는 없어졌다).
abstract class ApplicantPicksRepository {
  Future<ApplicantPicks> fetchPicks();
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
