import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../offer_terms/domain/offer_terms.dart';
import 'proposal.dart';

/// 제안함을 읽고, 제안에 답하는 포트: 목록, 상세, 수락, 끝내기, 새 판본.
abstract class ProposalRepository {
  Future<List<ProposalRow>> fetch(ProposalTab tab);

  /// 없는 제안이거나 남의 제안이면 [ProposalFailure.notFound].
  Future<ProposalDetail> fetchDetail(String offerId);

  /// [version]은 지금 보고 있는 판본이다. 그사이 새 판본이 나왔으면 [ProposalFailure.staleVersion]이 최신
  /// 번호를 담는다. 만들어진 협업의 id를 돌려준다(사장님은 이것으로 결제 화면에 간다).
  Future<String?> accept(String offerId, int version);

  /// 사유를 골라 제안을 끝낸다. 되돌릴 수 없다.
  Future<void> end(String offerId, EndReason reason);

  /// 사장님이 수락했지만 결제 전인 오퍼를 취소한다(사유 없이). 이미 처리됐으면 [ProposalFailure.conflict].
  Future<void> cancel(String offerId);

  /// 내 차례에 [terms]로 다음 판본을 낸다(사장님이 고쳐서 다시 보내기).
  Future<void> reply(String offerId, OfferTerms terms);
}

/// 서버에 닿지 못했거나 서버가 거절했다.
class ProposalFailure implements Exception {
  const ProposalFailure({
    this.conflict = false,
    this.staleVersion,
    this.notFound = false,
    this.message,
  });

  /// 서버가 409로 답했다(이미 처리됐거나 지금은 할 수 없다).
  final bool conflict;

  /// 수락하려던 판본이 최신이 아니다. 값은 상대가 보낸 최신 판본 번호다.
  final int? staleVersion;
  final bool notFound;

  /// 서버가 화면에 그대로 보이라고 보낸 문구(4xx일 때만). 없으면 화면이 일반 문구를 쓴다.
  final String? message;

  @override
  String toString() =>
      'ProposalFailure(conflict: $conflict, staleVersion: $staleVersion, notFound: $notFound)';
}

/// 기본값은 일부러 던진다. main.dart가 API 구현으로, 테스트가 가짜로 바꿔 끼운다.
final proposalRepositoryProvider = Provider<ProposalRepository>(
  (ref) =>
      throw UnimplementedError('proposalRepositoryProvider must be overridden'),
);
