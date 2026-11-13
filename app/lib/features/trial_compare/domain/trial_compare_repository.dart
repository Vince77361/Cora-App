import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'trial_comparison.dart';
import 'trial_info.dart';

/// 체험단과의 비교(G3)와 체험단 계약 정보를 서버와 주고받는 포트.
abstract class TrialCompareRepository {
  /// 석 달 비교. 체험단 계약 정보를 넣지 않았으면 [TrialCompareFailure.notFound]다.
  Future<TrialComparison> fetchComparison();

  Future<void> saveInfo(TrialInfo info);
  Future<void> deleteInfo();

  /// 홈의 체험단 줄을 7일 숨긴다(`나중에`).
  Future<void> snooze();

  /// 계약 정보 안내를 봤다고 알린다. 다시 나오지 않는다.
  Future<void> markHintSeen();
}

/// 서버에 닿지 못했거나 서버가 거절했다. 서버 응답의 문구는 담지 않는다.
class TrialCompareFailure implements Exception {
  const TrialCompareFailure({this.notFound = false});

  /// 서버가 404로 답했다(계약 정보가 없다).
  final bool notFound;

  @override
  String toString() => 'TrialCompareFailure(notFound: $notFound)';
}

/// 기본값은 일부러 던진다. main.dart가 API 구현으로, 테스트가 가짜로 바꿔 끼운다.
final trialCompareRepositoryProvider = Provider<TrialCompareRepository>(
  (ref) => throw UnimplementedError(
    'trialCompareRepositoryProvider must be overridden',
  ),
);
