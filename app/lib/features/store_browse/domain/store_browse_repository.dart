import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'store_detail.dart';
import 'store_summary.dart';

/// 크리에이터가 공개된 가게를 둘러보고 지원하는 포트.
abstract class StoreBrowseRepository {
  Future<List<StoreSummary>> fetchPublished();
  Future<StoreDetail> fetchDetail(String storeId);

  /// 가게에 지원한다. 이미 지원했거나 오퍼를 받았으면 [StoreBrowseFailure.conflict].
  Future<void> apply(String storeId);

  /// 지원을 취소한다. 사장님이 오퍼를 보낸 뒤에는 [StoreBrowseFailure.conflict].
  Future<void> cancelApplication(String storeId);
}

/// 서버에 닿지 못했거나 서버가 거절했다. 서버 응답의 문구는 담지 않는다.
class StoreBrowseFailure implements Exception {
  const StoreBrowseFailure({this.conflict = false});

  /// 서버가 409로 답했다(그사이 지원 상태가 바뀌었다).
  final bool conflict;

  @override
  String toString() => 'StoreBrowseFailure(conflict: $conflict)';
}

/// 기본값은 일부러 던진다. main.dart가 API 구현으로, 테스트가 가짜로 바꿔 끼운다.
final storeBrowseRepositoryProvider = Provider<StoreBrowseRepository>(
  (ref) => throw UnimplementedError(
    'storeBrowseRepositoryProvider must be overridden',
  ),
);
