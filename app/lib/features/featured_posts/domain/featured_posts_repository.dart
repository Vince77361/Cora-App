import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'featured_post.dart';

/// 내 대표 게시물을 서버와 주고받는 포트.
abstract class FeaturedPostsRepository {
  /// 내 대표 게시물, 번호 순서대로. 서버에 닿지 못하면 [FeaturedPostsFailure].
  Future<List<FeaturedPost>> fetchMine();

  /// 목록 전체를 한 번에 바꾼다(부분 저장 없음). [posts]의 차례가 곧 새 순서다. 서버에 이미 있는 것은 ID만, 초안은
  /// 저장 필드만 보낸다. 저장된 목록을 돌려준다.
  Future<List<FeaturedPost>> replaceMine(List<FeaturedPost> posts);

  /// 연동한 인스타그램 계정의 게시물 목록. 연동하지 않았으면 [FeaturedPostsFailure].
  Future<List<InstagramPost>> listInstagramPosts();

  /// 고른 인스타그램 게시물을 서버에 복사해 오고 저장 전 초안으로 돌려준다(저장은 [replaceMine]).
  Future<List<FeaturedPost>> importInstagram(List<String> postIds);
}

/// 서버에 닿지 못했거나 서버가 거절했다. [message]는 서버가 화면에 그대로 보이라고 보낸 문구(4xx일 때만)이고,
/// 없으면 화면이 일반 문구를 쓴다.
class FeaturedPostsFailure implements Exception {
  const FeaturedPostsFailure({this.message});

  final String? message;

  @override
  String toString() => 'FeaturedPostsFailure()';
}

/// 기본값은 일부러 던진다. main.dart가 API 구현으로, 테스트가 가짜로 바꿔 끼운다.
final featuredPostsRepositoryProvider = Provider<FeaturedPostsRepository>(
  (ref) => throw UnimplementedError(
    'featuredPostsRepositoryProvider must be overridden',
  ),
);
