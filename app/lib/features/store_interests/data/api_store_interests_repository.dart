import 'package:cora_api/api.dart' as api;

import '../domain/store_interest.dart';
import '../domain/store_interests_repository.dart';

/// 생성된 API 클라이언트(`cora_api`)로 사장님 저장함의 저장·보낸 관심 목록을 읽는다. 생성된 타입은 이 파일 밖으로
/// 내보내지 않는다.
class ApiStoreInterestsRepository implements StoreInterestsRepository {
  ApiStoreInterestsRepository(api.ApiClient client)
    : _discovery = api.DiscoveryApi(client);

  final api.DiscoveryApi _discovery;

  @override
  Future<List<StoreInterest>> fetchSaved() => _read(api.StoreInterestTab.saved);

  @override
  Future<List<StoreInterest>> fetchSent() => _read(api.StoreInterestTab.sent);

  Future<List<StoreInterest>> _read(api.StoreInterestTab tab) async {
    try {
      final rows = await _discovery.listStoreInterests(tab: tab);
      if (rows == null) throw const StoreInterestsFailure();
      return [for (final m in rows) _row(m)];
    } on StoreInterestsFailure {
      rethrow;
    } catch (_) {
      throw const StoreInterestsFailure();
    }
  }

  static StoreInterest _row(api.StoreInterestCardModel m) => StoreInterest(
    creatorId: m.creatorId,
    name: m.name,
    shortName: m.shortName,
    contentFocus: m.contentFocus,
    followers: m.followers,
    photoUrl: m.photoUrl,
    mutual: m.mutual,
  );
}
