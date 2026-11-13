import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../offer_terms/domain/offer_terms.dart';
import 'creator_series.dart';

/// 크리에이터가 내 시리즈를 읽고 만들고, 가게에 내 방식으로 제안하는 포트.
abstract class CounterProposalRepository {
  Future<List<CreatorSeries>> fetchSeries();

  /// 시리즈를 만든다. 5개를 넘으면 [CounterProposalFailure]의 [CounterProposalFailure.message]가 서버 문구다.
  Future<CreatorSeries> addSeries({
    required String name,
    required ContentFormat format,
    String? note,
  });

  /// 가게 페이지에서 새 제안을 낸다. 가게의 모집 조건이 판본 1이고 이 제안이 판본 [version]이다.
  Future<({String offerId, int version})> sendToStore(
    String storeId,
    CounterProposal proposal,
  );

  /// 열린 오퍼에 내 차례의 다음 판본을 낸다.
  Future<void> sendVersion(String offerId, CounterProposal proposal);
}

/// 서버에 닿지 못했거나 서버가 거절했다. [message]는 서버가 화면에 그대로 보이라고 보낸 문구(4xx일 때만)이고,
/// 없으면 화면이 일반 문구를 쓴다.
class CounterProposalFailure implements Exception {
  const CounterProposalFailure({this.message});

  final String? message;

  @override
  String toString() => 'CounterProposalFailure()';
}

/// 기본값은 일부러 던진다. main.dart가 API 구현으로, 테스트가 가짜로 바꿔 끼운다.
final counterProposalRepositoryProvider = Provider<CounterProposalRepository>(
  (ref) => throw UnimplementedError(
    'counterProposalRepositoryProvider must be overridden',
  ),
);
