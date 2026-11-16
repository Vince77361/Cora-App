import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'compare_result.dart';
import 'interest_card.dart';
import 'match_info.dart';

/// 관심·보류(03), 후보 비교(04), 서로 관심(05)이 서버와 주고받는 포트. 결정(관심·넘김)은
/// 발견의 `DiscoveryRepository.decide`가 맡는다.
abstract class InterestsRepository {
  /// 내가 저장한(관심 + 보류) 카드 전부. 탭은 앱이 상태로 가른다. 실패하면 [InterestsFailure].
  Future<List<InterestCard>> fetchSaved();

  /// 이 캠페인에서 내가 저장한 두 크리에이터를 견준다. 실패하면 [InterestsFailure].
  Future<CompareResult> compare(String a, String b);

  /// 협업 [collaborationId]의 05 정보. 실패하면 [InterestsFailure].
  Future<MatchInfo> fetchMatch(String collaborationId);
}

/// 서버와 주고받지 못했다. 서버 응답의 문구는 담지 않는다.
class InterestsFailure implements Exception {
  const InterestsFailure();

  @override
  String toString() => 'InterestsFailure';
}

/// 기본값은 일부러 던진다. main.dart가 API 구현으로, 테스트가 가짜로 바꿔 끼운다.
final interestsRepositoryProvider = Provider<InterestsRepository>(
  (ref) => throw UnimplementedError(
    'interestsRepositoryProvider must be overridden',
  ),
);
