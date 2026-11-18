import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/swipe_deck/swipe_physics.dart' show SwipeOutcome;
import '../../discovery/domain/pass_reason.dart';
import 'store_creator_card.dart';

/// 사장님의 전체 둘러보기가 서버와 주고받는 포트.
abstract class StoreDiscoverRepository {
  /// 오늘 사장님에게 보일 크리에이터 카드. [cards]는 아직 결정하지 않은 것이고, [total]은 이미 결정한
  /// 카드를 포함한 오늘의 수라 "다 봤는지"는 [cards]로 판단한다. 실패하면 [StoreDiscoverFailure].
  Future<({int total, List<StoreCreatorCard> cards})> fetchCards();

  /// 하트(`like`)·넘김(`pass`)·저장(`hold`)을 보낸다. 사장님 하트에는 글을 붙이지 않는다.
  /// 실패하면 [StoreDiscoverFailure].
  Future<void> decide(String creatorId, SwipeOutcome outcome);

  /// 방금 넘긴 [creatorId]에 이유를 남긴다. 실패하면 [StoreDiscoverFailure].
  Future<void> setPassReason(String creatorId, PassReason reason);

  /// 마지막 결정을 되돌리고 그 크리에이터 id를 돌려준다. 되돌릴 것이 없거나 서로 관심이 된 카드면
  /// null이다. 실패하면 [StoreDiscoverFailure].
  Future<String?> undoLast();
}

/// 서버와 주고받지 못했다. 서버 응답의 문구는 담지 않는다.
class StoreDiscoverFailure implements Exception {
  const StoreDiscoverFailure();

  @override
  String toString() => 'StoreDiscoverFailure';
}

/// 기본값은 일부러 던진다. main.dart가 API 구현으로, 테스트가 가짜로 바꿔 끼운다.
final storeDiscoverRepositoryProvider = Provider<StoreDiscoverRepository>(
  (ref) => throw UnimplementedError(
    'storeDiscoverRepositoryProvider must be overridden',
  ),
);
