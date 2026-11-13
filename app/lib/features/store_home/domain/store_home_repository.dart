import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../offer_terms/domain/offer_terms.dart';
import 'applicant.dart';
import 'sent_offer.dart';
import 'store_home_summary.dart';

/// 사장님 홈이 서버와 주고받는 포트: 숫자, 지원자, 보낸 오퍼, 오퍼 보내기.
abstract class StoreHomeRepository {
  Future<StoreHomeSummary> fetchSummary();
  Future<List<Applicant>> fetchApplicants();
  Future<List<SentOffer>> fetchSentOffers();

  /// 이미 열린 오퍼가 있으면 [StoreHomeFailure.conflict].
  Future<void> sendOffer(String creatorId, OfferTerms terms);
}

/// 서버에 닿지 못했거나 서버가 거절했다. 서버 응답의 문구는 담지 않는다.
class StoreHomeFailure implements Exception {
  const StoreHomeFailure({this.conflict = false});

  /// 서버가 409로 답했다.
  final bool conflict;

  @override
  String toString() => 'StoreHomeFailure(conflict: $conflict)';
}

/// 기본값은 일부러 던진다. main.dart가 API 구현으로, 테스트가 가짜로 바꿔 끼운다.
final storeHomeRepositoryProvider = Provider<StoreHomeRepository>(
  (ref) => throw UnimplementedError(
    'storeHomeRepositoryProvider must be overridden',
  ),
);
