import 'dart:async';

import 'package:cora/features/brand_onboarding/domain/brand_profile.dart';
import 'package:cora/features/brand_onboarding/domain/brand_repository.dart';
import 'package:cora/features/store_onboarding/domain/my_store.dart';

/// 손으로 쓴 가짜 브랜드 프로필 저장소. 서버가 가진 프로필을 흉내 낸다.
class FakeBrandRepository implements BrandRepository {
  /// [profile]이 서버에 저장된 프로필이다. null이면 아직 만들지 않은 브랜드.
  FakeBrandRepository({this.profile});

  BrandProfile? profile;

  bool failFetch = false;
  bool failSave = false;

  /// 설정하면 [save]가 이 Completer가 끝날 때까지 기다린다(저장 중 상태 확인용).
  Completer<void>? holdSave;

  int saveCalls = 0;

  /// 마지막 [save]에 넘어온 값.
  ({
    String name,
    IndustryCategory industry,
    String? tagline,
    String? photoPath,
  })?
  saved;

  @override
  Future<BrandProfile?> fetchMine() async {
    if (failFetch) throw const BrandFailure();
    return profile;
  }

  @override
  Future<BrandProfile> save({
    required String name,
    required IndustryCategory industry,
    String? tagline,
    String? photoPath,
  }) async {
    saveCalls++;
    saved = (
      name: name,
      industry: industry,
      tagline: tagline,
      photoPath: photoPath,
    );
    final hold = holdSave;
    if (hold != null) await hold.future;
    if (failSave) throw const BrandFailure();
    return profile = BrandProfile(
      name: name,
      industry: industry,
      tagline: tagline,
    );
  }
}

/// 테스트가 기본으로 쓰는 브랜드 프로필.
const defaultBrandProfile = BrandProfile(
  name: '느린 결',
  tagline: '일상의 주얼리',
  industry: IndustryCategory.accessory,
);
