import 'package:cora_api/api.dart' as api;

import '../../../core/network/api_error.dart';
import '../../offer_terms/data/offer_terms_from_wire.dart';
import '../domain/store_browse_repository.dart';
import '../domain/store_detail.dart';
import '../domain/store_summary.dart';

/// 생성된 API 클라이언트(`cora_api`)로 공개된 가게를 읽고 지원한다. 생성된 타입은 이 파일 밖으로
/// 내보내지 않는다.
class ApiStoreBrowseRepository implements StoreBrowseRepository {
  ApiStoreBrowseRepository(api.ApiClient client)
    : _stores = api.StoresApi(client),
      _applications = api.ApplicationsApi(client);

  final api.StoresApi _stores;
  final api.ApplicationsApi _applications;

  @override
  Future<List<StoreSummary>> fetchPublished() => _guard(() async {
    final rows = await _stores.listPublishedStores();
    if (rows == null) throw const StoreBrowseFailure();
    return [for (final m in rows) summaryFromWire(m)];
  });

  @override
  Future<StoreDetail> fetchDetail(String storeId) => _guard(() async {
    final m = await _stores.getPublishedStore(storeId);
    if (m == null) throw const StoreBrowseFailure();
    return StoreDetail(
      summary: StoreSummary(
        id: m.id,
        name: m.name,
        category: m.category,
        neighborhood: m.neighborhood,
        regionSido: m.regionSido,
        regionSigungu: m.regionSigungu,
        coverPhotoUrl: m.coverPhotoUrl,
        defaultTerms: offerTermsFromWire(m.defaultTerms),
      ),
      myApplicationStatus: switch (m.myApplicationStatus) {
        api.MyApplicationStatus.APPLIED => MyApplicationStatus.applied,
        api.MyApplicationStatus.OFFERED => MyApplicationStatus.offered,
        _ => MyApplicationStatus.none,
      },
      intro: m.intro,
      bestShootingTime: m.bestShootingTime,
    );
  });

  @override
  Future<void> apply(String storeId) =>
      _guard(() => _applications.applyToStore(storeId));

  @override
  Future<void> cancelApplication(String storeId) =>
      _guard(() => _applications.cancelMyApplication(storeId));

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on StoreBrowseFailure {
      rethrow;
    } catch (error) {
      throw StoreBrowseFailure(conflict: ApiError.from(error).isConflict);
    }
  }
}

/// 목록과 받은 오퍼가 같은 가게 모양을 쓴다.
StoreSummary summaryFromWire(api.StoreSummaryModel m) => StoreSummary(
  id: m.id,
  name: m.name,
  category: m.category,
  neighborhood: m.neighborhood,
  regionSido: m.regionSido,
  regionSigungu: m.regionSigungu,
  coverPhotoUrl: m.coverPhotoUrl,
  defaultTerms: offerTermsFromWire(m.defaultTerms),
);
