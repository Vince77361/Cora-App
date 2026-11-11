import '../../offer_terms/domain/offer_terms.dart';
import 'my_store.dart';
import 'source_link.dart';

/// 내 가게를 서버와 주고받는 포트.
abstract class StoreRepository {
  /// 내 가게. 아직 만들지 않았으면 null.
  Future<MyStore?> fetchMine();

  /// [links]를 분석해 등록 중인 가게를 만든다(이미 있으면 덮어쓴다). 읽지 못해도 빈 가게로 이어
  /// 가며 `analysisFailed`가 true다.
  Future<({MyStore store, bool analysisFailed})> analyze(
    List<SourceLink> links,
  );

  Future<MyStore> update(StoreEdit edit);

  /// 등록 단계를 [step]으로 올린다. 같거나 앞 단계면 그대로다.
  Future<MyStore> advance(StoreOnboardingStep step);

  Future<MyStore> setDefaultTerms(OfferTermsInput input);

  Future<MyStore> publish();
}

/// 서버에 닿지 않았거나 서버가 거절했다. 서버 응답의 문구는 담지 않는다.
class StoreFailure implements Exception {
  const StoreFailure({this.isConflict = false, this.isRateLimited = false});

  /// 이미 공개한 가게를 다시 만들려는 것처럼 지금 상태에서는 할 수 없는 일(409).
  final bool isConflict;

  /// 요청이 너무 많다(429).
  final bool isRateLimited;

  @override
  String toString() =>
      'StoreFailure(conflict: $isConflict, rateLimited: $isRateLimited)';
}
