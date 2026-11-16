import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'creator_profile.dart';

/// 내 크리에이터 프로필을 서버와 주고받는 포트.
abstract class CreatorProfileRepository {
  /// 내 프로필. 아직 만들지 않았으면 null. 서버에 닿지 못하면 [CreatorProfileFailure].
  Future<CreatorProfile?> fetchMine();

  /// 프로필을 만들거나 통째로 바꾼다. [photoPath]·[cardPhotoPath]는 [PhotoUploader]가 돌려준 저장 위치다.
  ///
  /// 서버는 이 요청을 전체 교체로 받아 카드 값을 빠뜨리면 지운다. 그래서 [cardHeadline]·
  /// [cardPhotoPath]가 null이면 서버에 저장된 현재 카드 값을 그대로 보낸다(프로필만 고치는
  /// 저장이 카드를 지우지 않게 한다). 한 줄을 지우려면 빈 글자를 준다. 실패하면 [CreatorProfileFailure].
  Future<CreatorProfile> save({
    required String displayName,
    required String regionSido,
    String? regionSigungu,
    String? contentFocus,
    String? instagramHandle,
    String? photoPath,
    String? cardHeadline,
    String? cardPhotoPath,
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
