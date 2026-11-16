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
    String? cardHeadline,
    String? cardPhotoPath,
  }) async {
    try {
      // PUT은 전체 교체라서 카드 값을 빠뜨리면 서버가 지운다. 호출한 쪽이 주지 않은 것은 서버의
      // 현재 값을 읽어 그대로 다시 보낸다.
      final keep = cardHeadline == null || cardPhotoPath == null
          ? await _currentCard()
          : null;
      final model = await _creators.upsertMyCreatorProfile(
        api.UpsertCreatorProfileDto(
          displayName: displayName,
          regionSido: regionSido,
          regionSigungu: regionSigungu,
          contentFocus: contentFocus,
          instagramHandle: instagramHandle,
          photoPath: photoPath,
          cardHeadline: cardHeadline ?? keep?.headline,
          cardPhotoPath: cardPhotoPath ?? keep?.photoPath,
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

  /// 서버에 저장된 카드 값. 프로필이 아직 없으면(404) 지킬 값도 없다.
  Future<({String? headline, String? photoPath})> _currentCard() async {
    final api.CreatorProfileModel? current;
    try {
      current = await _creators.getMyCreatorProfile();
    } catch (error) {
      if (ApiError.from(error).isNotFound) {
        return (headline: null, photoPath: null);
      }
      rethrow;
    }
    if (current == null) throw const CreatorProfileFailure();
    final url = current.cardPhotoUrl;
    final path = url == null ? null : _storagePathOf(url);
    // 사진이 있는데 경로를 알 수 없으면 저장하지 않는다. 모른 채 보내면 사진이 지워진다.
    if (url != null && path == null) throw const CreatorProfileFailure();
    return (headline: current.cardHeadline, photoPath: path);
  }

  /// 공개 주소에서 저장 경로(`creator-cards/<사용자>/<파일>`)를 되찾는다. 서버가 카드 사진을 올리는
  /// 폴더 이름(`api/src/uploads/uploads.service.ts`의 `CREATOR_CARD`)으로 찾는다.
  static String? _storagePathOf(String url) {
    final at = url.indexOf(_cardDir);
    if (at < 0) return null;
    final path = url.substring(at);
    final end = path.indexOf(RegExp('[?#]'));
    return end < 0 ? path : path.substring(0, end);
  }

  static const _cardDir = 'creator-cards/';

  static CreatorProfile _fromModel(api.CreatorProfileModel m) => CreatorProfile(
    displayName: m.displayName,
    regionSido: m.regionSido,
    regionSigungu: m.regionSigungu,
    contentFocus: m.contentFocus,
    instagramHandle: m.instagramHandle,
    photoUrl: m.photoUrl,
    cardHeadline: m.cardHeadline,
    cardPhotoUrl: m.cardPhotoUrl,
  );
}
