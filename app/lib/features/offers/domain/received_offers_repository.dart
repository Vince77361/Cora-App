import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'received_offer.dart';

/// 크리에이터가 받은 오퍼를 읽고 답하는 포트.
abstract class ReceivedOffersRepository {
  /// 새 오퍼: 답을 기다리는 오퍼와 방금 거절해 되돌릴 수 있는 오퍼. 도착한 순서다.
  Future<List<ReceivedOffer>> fetchNew();

  /// [version]은 화면이 보고 있는 판본 번호다. 최신이 아니면 서버가 409 STALE_VERSION으로 거절한다.
  Future<void> accept(String id, int version);

  /// 거절은 누르는 즉시 서버에 저장된다. 30초 안에는 [undoDecline]으로 되돌린다.
  Future<void> decline(String id);
  Future<void> undoDecline(String id);
}

/// 서버에 닿지 못했거나 서버가 거절했다. 서버 응답의 문구는 담지 않는다.
class ReceivedOffersFailure implements Exception {
  const ReceivedOffersFailure({this.conflict = false, this.staleVersion});

  /// 서버가 409로 답했다(이미 처리된 오퍼).
  final bool conflict;

  /// 수락하려던 판본이 최신이 아니다(409 `STALE_VERSION`). 서버가 알려 준 최신 판본 번호다.
  final int? staleVersion;

  @override
  String toString() =>
      'ReceivedOffersFailure(conflict: $conflict, staleVersion: $staleVersion)';
}

/// 기본값은 일부러 던진다. main.dart가 API 구현으로, 테스트가 가짜로 바꿔 끼운다.
final receivedOffersRepositoryProvider = Provider<ReceivedOffersRepository>(
  (ref) => throw UnimplementedError(
    'receivedOffersRepositoryProvider must be overridden',
  ),
);
