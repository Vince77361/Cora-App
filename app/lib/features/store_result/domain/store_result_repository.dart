import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'store_result.dart';

/// 사장님의 7일 결과(G1)를 읽는 포트.
abstract class StoreResultRepository {
  /// 협업 [collaborationId]의 결과. 없거나 내 것이 아니거나 아직 정산 전이거나 식사권만 있던 협업이면
  /// [StoreResultFailure.notFound]다.
  Future<StoreResult> fetch(String collaborationId);
}

/// 서버에 닿지 못했거나 서버가 거절했다. 서버 응답의 문구는 담지 않는다.
class StoreResultFailure implements Exception {
  const StoreResultFailure({this.notFound = false});

  /// 서버가 404로 답했다(결과를 볼 수 없는 협업이다).
  final bool notFound;

  @override
  String toString() => 'StoreResultFailure(notFound: $notFound)';
}

/// 기본값은 일부러 던진다. main.dart가 API 구현으로, 테스트가 가짜로 바꿔 끼운다.
final storeResultRepositoryProvider = Provider<StoreResultRepository>(
  (ref) => throw UnimplementedError(
    'storeResultRepositoryProvider must be overridden',
  ),
);
