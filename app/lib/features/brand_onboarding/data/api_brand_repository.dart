import 'package:cora_api/api.dart' as api;

import '../../../core/network/api_error.dart';
import '../../store_onboarding/domain/my_store.dart' show IndustryCategory;
import '../domain/brand_profile.dart';
import '../domain/brand_repository.dart';

/// 생성된 API 클라이언트(`cora_api`)로 내 브랜드 프로필을 주고받는다. 생성된 타입은 이 파일 밖으로
/// 내보내지 않는다.
class ApiBrandRepository implements BrandRepository {
  ApiBrandRepository(api.ApiClient client) : _brands = api.BrandsApi(client);

  final api.BrandsApi _brands;

  @override
  Future<BrandProfile?> fetchMine() async {
    try {
      final model = await _brands.getMyBrand();
      // 서버는 프로필이 없으면 404로 답한다. 본문이 비는 성공은 없으므로 실패로 본다.
      if (model == null) throw const BrandFailure();
      return _fromModel(model);
    } on BrandFailure {
      rethrow;
    } catch (error) {
      if (ApiError.from(error).isNotFound) return null;
      throw const BrandFailure();
    }
  }

  @override
  Future<BrandProfile> save({
    required String name,
    required IndustryCategory industry,
    String? tagline,
    String? photoPath,
  }) async {
    try {
      // PUT은 전체 교체라서 사진 경로를 빠뜨리면 서버가 사진을 지운다. 새 사진을 고르지 않았으면
      // 서버의 현재 사진 경로를 그대로 다시 보낸다.
      final keep = photoPath == null ? await _currentPhotoPath() : null;
      final model = await _brands.upsertMyBrand(
        api.UpsertBrandProfileDto(
          name: name,
          industry: _industries[industry]!,
          tagline: tagline,
          photoPath: photoPath ?? keep,
        ),
      );
      if (model == null) throw const BrandFailure();
      return _fromModel(model);
    } on BrandFailure {
      rethrow;
    } catch (_) {
      throw const BrandFailure();
    }
  }

  /// 서버에 저장된 대표 사진의 저장 경로. 프로필이 아직 없으면(404) 지킬 사진도 없다.
  Future<String?> _currentPhotoPath() async {
    final api.BrandProfileModel? current;
    try {
      current = await _brands.getMyBrand();
    } catch (error) {
      if (ApiError.from(error).isNotFound) return null;
      rethrow;
    }
    if (current == null) throw const BrandFailure();
    final url = current.photoUrl;
    if (url == null) return null;
    final path = _storagePathOf(url);
    // 사진이 있는데 경로를 알 수 없으면 저장하지 않는다. 모른 채 보내면 사진이 지워진다.
    if (path == null) throw const BrandFailure();
    return path;
  }

  /// 공개 주소에서 저장 경로(`brands/<사용자>/<파일>`)를 되찾는다. 서버가 브랜드 사진을 올리는
  /// 폴더 이름(`api/src/uploads/uploads.service.ts`의 `BRAND_PHOTO`)으로 찾는다.
  static String? _storagePathOf(String url) {
    final at = url.indexOf(_photoDir);
    if (at < 0) return null;
    final path = url.substring(at);
    final end = path.indexOf(RegExp('[?#]'));
    return end < 0 ? path : path.substring(0, end);
  }

  static const _photoDir = 'brands/';

  static BrandProfile _fromModel(api.BrandProfileModel m) => BrandProfile(
    name: m.name,
    tagline: m.tagline,
    industry: _industries.entries.firstWhere((e) => e.value == m.industry).key,
    photoUrl: m.photoUrl,
  );
}

const _industries = <IndustryCategory, api.IndustryCategory>{
  IndustryCategory.foodCafe: api.IndustryCategory.FOOD_CAFE,
  IndustryCategory.beauty: api.IndustryCategory.BEAUTY,
  IndustryCategory.fashion: api.IndustryCategory.FASHION,
  IndustryCategory.accessory: api.IndustryCategory.ACCESSORY,
  IndustryCategory.living: api.IndustryCategory.LIVING,
  IndustryCategory.grocery: api.IndustryCategory.GROCERY,
  IndustryCategory.digital: api.IndustryCategory.DIGITAL,
  IndustryCategory.health: api.IndustryCategory.HEALTH,
  IndustryCategory.other: api.IndustryCategory.OTHER,
  IndustryCategory.alcohol: api.IndustryCategory.ALCOHOL,
  IndustryCategory.gambling: api.IndustryCategory.GAMBLING,
  IndustryCategory.loan: api.IndustryCategory.LOAN,
  IndustryCategory.dietSupplement: api.IndustryCategory.DIET_SUPPLEMENT,
};
