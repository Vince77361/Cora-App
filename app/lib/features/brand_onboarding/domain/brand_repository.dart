import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../store_onboarding/domain/my_store.dart' show IndustryCategory;
import 'brand_profile.dart';

/// 내 브랜드 프로필을 서버와 주고받는 포트.
abstract class BrandRepository {
  /// 내 프로필. 아직 만들지 않았으면 null. 서버에 닿지 못하면 [BrandFailure].
  Future<BrandProfile?> fetchMine();

  /// 프로필을 만들거나 통째로 바꾼다. [photoPath]는 [PhotoUploader]가 돌려준 저장 위치다.
  ///
  /// 서버는 이 요청을 전체 교체로 받아 사진 경로를 빠뜨리면 지운다. 그래서 [photoPath]가 null이면
  /// 서버에 저장된 현재 사진을 그대로 다시 보낸다(사진을 고르지 않은 저장이 사진을 지우지
  /// 않게 한다). 실패하면 [BrandFailure].
  Future<BrandProfile> save({
    required String name,
    required IndustryCategory industry,
    String? tagline,
    String? photoPath,
  });
}

/// 프로필을 서버와 주고받지 못했다. 서버 응답의 문구는 담지 않는다.
class BrandFailure implements Exception {
  const BrandFailure();

  @override
  String toString() => 'BrandFailure';
}

/// 기본값은 일부러 던진다. main.dart가 API 구현으로, 테스트가 가짜로 바꿔 끼운다.
final brandRepositoryProvider = Provider<BrandRepository>(
  (ref) =>
      throw UnimplementedError('brandRepositoryProvider must be overridden'),
);
