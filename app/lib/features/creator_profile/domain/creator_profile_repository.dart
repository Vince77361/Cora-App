import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'creator_profile.dart';

/// 내 크리에이터 프로필을 서버와 주고받는 포트.
abstract class CreatorProfileRepository {
  /// 내 프로필. 아직 만들지 않았으면 null. 서버에 닿지 못하면 [CreatorProfileFailure].
  Future<CreatorProfile?> fetchMine();

  /// 프로필을 만들거나 통째로 바꾼다. [photoPath]는 [PhotoUploader]가 돌려준 저장 위치다.
  ///
  /// 카드의 한 줄과 사진은 대표 게시물(1번)이 정하므로 여기서 보내지 않는다(서버도 받아 무시한다). 실패하면
  /// [CreatorProfileFailure].
  Future<CreatorProfile> save({
    required String displayName,
    required String regionSido,
    String? regionSigungu,
    String? contentFocus,
    String? instagramHandle,
    String? photoPath,
  });
}

/// 프로필을 서버와 주고받지 못했다. 서버 응답의 문구는 담지 않는다.
class CreatorProfileFailure implements Exception {
  const CreatorProfileFailure();

  @override
  String toString() => 'CreatorProfileFailure';
}

/// 기본값은 일부러 던진다. main.dart가 API 구현으로, 테스트가 가짜로 바꿔 끼운다.
final creatorProfileRepositoryProvider = Provider<CreatorProfileRepository>(
  (ref) => throw UnimplementedError(
    'creatorProfileRepositoryProvider must be overridden',
  ),
);
