import 'package:cora_api/api.dart' as api;

import '../../../core/network/api_error.dart';
import '../../offer_terms/data/offer_terms_from_wire.dart';
import '../domain/store_result.dart';
import '../domain/store_result_repository.dart';

/// 생성된 API 클라이언트(`cora_api`)로 7일 결과를 읽는다. 생성된 타입은 이 파일 밖으로 내보내지 않는다.
class ApiStoreResultRepository implements StoreResultRepository {
  ApiStoreResultRepository(api.ApiClient client)
    : _api = api.StoreResultApi(client);

  final api.StoreResultApi _api;

  @override
  Future<StoreResult> fetch(String collaborationId) async {
    try {
      final m = await _api.getStoreResult(collaborationId);
      if (m == null) throw const StoreResultFailure();
      return StoreResult(
        creator: StoreResultCreator(
          userId: m.creator.userId,
          name: m.creator.name,
          photoUrl: m.creator.photoUrl,
        ),
        format: formatFromWire(m.format),
        postedAt: m.postedAt,
        postUrl: m.postUrl,
        views: m.views,
        usualViews: m.usualViews,
        multiplierTenths: m.multiplierTenths,
        payout: m.payout,
        refund: m.refund,
        fixedCash: m.fixedCash,
        fixedCashOnly: m.fixedCashOnly,
      );
    } on StoreResultFailure {
      rethrow;
    } catch (error) {
      throw StoreResultFailure(notFound: ApiError.from(error).isNotFound);
    }
  }
}
