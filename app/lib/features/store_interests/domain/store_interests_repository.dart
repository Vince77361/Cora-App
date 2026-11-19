import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'store_interest.dart';

/// 사장님 저장함이 서버에서 읽는 포트. 보낸 제안 탭은 제안함(F3)의 저장소를 그대로 쓴다.
abstract class StoreInterestsRepository {
  /// 내가 저장한(HOLD) 크리에이터. 최근에 저장한 순이다. 실패하면 [StoreInterestsFailure].
  Future<List<StoreInterest>> fetchSaved();

  /// 내가 하트를 보낸(LIKE) 크리에이터. 서로 관심인 사람은 [StoreInterest.mutual]이 true다. 실패하면
  /// [StoreInterestsFailure].
  Future<List<StoreInterest>> fetchSent();
}

/// 서버와 주고받지 못했다. 서버 응답의 문구는 담지 않는다.
class StoreInterestsFailure implements Exception {
  const StoreInterestsFailure();

  @override
  String toString() => 'StoreInterestsFailure';
}

/// 기본값은 일부러 던진다. main.dart가 API 구현으로, 테스트가 가짜로 바꿔 끼운다.
final storeInterestsRepositoryProvider = Provider<StoreInterestsRepository>(
  (ref) => throw UnimplementedError(
    'storeInterestsRepositoryProvider must be overridden',
  ),
);
