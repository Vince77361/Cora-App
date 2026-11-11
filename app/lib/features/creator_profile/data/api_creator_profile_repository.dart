import 'package:cora_api/api.dart' as api;

import '../../../core/network/api_error.dart';
import '../domain/creator_profile.dart';
import '../domain/creator_profile_repository.dart';

/// 생성된 API 클라이언트(`cora_api`)로 내 프로필을 주고받는다. 생성된 타입은 이 파일 밖으로
/// 내보내지 않는다.
class ApiCreatorProfileRepository implements CreatorProfileRepository {
  ApiCreatorProfileRepository(api.ApiClient client)
    : _creators = api.CreatorsApi(client);

  final api.CreatorsApi _creators;

  @override
  Future<CreatorProfile?> fetchMine() async {
    try {
      final model = await _creators.getMyCreatorProfile();
      // 서버는 프로필이 없으면 404로 답한다. 본문이 비는 성공은 없으므로 실패로 본다.
      if (model == null) throw const CreatorProfileFailure();
      return _fromModel(model);
    } on CreatorProfileFailure {
      rethrow;
    } catch (error) {
      if (ApiError.from(error).isNotFound) return null;
      throw const CreatorProfileFailure();
    }
  }

  @override
  Future<CreatorProfile> save({
    required String displayName,
    required String regionSido,
    String? regionSigungu,
    String? contentFocus,
    String? instagramHandle,
    String? photoPath,
  }) async {
    try {
      final model = await _creators.upsertMyCreatorProfile(
        api.UpsertCreatorProfileDto(
          displayName: displayName,
          regionSido: regionSido,
          regionSigungu: regionSigungu,
          contentFocus: contentFocus,
          instagramHandle: instagramHandle,
          photoPath: photoPath,
        ),
      );
      if (model == null) throw const CreatorProfileFailure();
      return _fromModel(model);
    } on CreatorProfileFailure {
      rethrow;
    } catch (_) {
      throw const CreatorProfileFailure();
    }
  }

  static CreatorProfile _fromModel(api.CreatorProfileModel m) => CreatorProfile(
    displayName: m.displayName,
    regionSido: m.regionSido,
    regionSigungu: m.regionSigungu,
    contentFocus: m.contentFocus,
    instagramHandle: m.instagramHandle,
    photoUrl: m.photoUrl,
  );
}
