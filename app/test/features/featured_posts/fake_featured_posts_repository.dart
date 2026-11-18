import 'dart:async';

import 'package:cora/features/featured_posts/domain/featured_post.dart';
import 'package:cora/features/featured_posts/domain/featured_posts_repository.dart';

/// 손으로 쓴 가짜 대표 게시물 저장소. 서버가 가진 목록과 인스타그램 게시물을 흉내 낸다.
class FakeFeaturedPostsRepository implements FeaturedPostsRepository {
  FakeFeaturedPostsRepository({
    List<FeaturedPost> posts = const [],
    this.instagramPosts = const [],
  }) : posts = [...posts];

  /// 서버에 저장된 목록(번호 순서).
  List<FeaturedPost> posts;

  /// 연동한 계정의 게시물 목록.
  List<InstagramPost> instagramPosts;

  bool failFetch = false;
  bool failSave = false;
  bool failImport = false;
  bool failListInstagram = false;

  /// 설정하면 [replaceMine]이 이 Completer가 끝날 때까지 기다린다(저장 중 상태 확인용).
  Completer<void>? holdSave;

  int fetchCalls = 0;

  /// [replaceMine]에 넘어온 목록들(부른 차례대로).
  final saved = <List<FeaturedPost>>[];

  /// [importInstagram]에 넘어온 ID 목록들.
  final imported = <List<String>>[];

  int _nextId = 1;

  @override
  Future<List<FeaturedPost>> fetchMine() async {
    fetchCalls++;
    if (failFetch) throw const FeaturedPostsFailure();
    return [...posts];
  }

  @override
  Future<List<FeaturedPost>> replaceMine(List<FeaturedPost> next) async {
    saved.add([...next]);
    final hold = holdSave;
    if (hold != null) await hold.future;
    if (failSave) throw const FeaturedPostsFailure();
    // 서버처럼 초안에는 새 ID를 주고, 이미 있는 것은 그대로 둔다.
    posts = [
      for (final p in next)
        p.id != null
            ? p
            : FeaturedPost(
                id: 'saved-${_nextId++}',
                source: p.source,
                kind: p.kind,
                photoUrl: p.photoUrl ?? 'https://photos.test/${p.mediaPath}',
                caption: p.caption,
                instagramMediaId: p.instagramMediaId,
              ),
    ];
    return [...posts];
  }

  @override
  Future<List<InstagramPost>> listInstagramPosts() async {
    if (failListInstagram) throw const FeaturedPostsFailure();
    return [...instagramPosts];
  }

  @override
  Future<List<FeaturedPost>> importInstagram(List<String> postIds) async {
    imported.add([...postIds]);
    if (failImport) throw const FeaturedPostsFailure();
    return [
      for (final id in postIds)
        FeaturedPost(
          source: FeaturedPostSource.instagram,
          kind: FeaturedPostKind.photo,
          photoUrl: 'https://picsum.test/$id.jpg',
          caption: '견본 게시물 $id',
          instagramMediaId: id,
          mediaPath: 'featured-posts/user-1/$id.jpg',
        ),
    ];
  }
}

/// 서버에 저장된 대표 게시물 하나.
FeaturedPost savedPost(
  int n, {
  FeaturedPostSource source = FeaturedPostSource.instagram,
  String? caption,
  String? instagramMediaId,
}) => FeaturedPost(
  id: 'post-$n',
  source: source,
  kind: FeaturedPostKind.photo,
  photoUrl: 'https://photos.test/featured-posts/post-$n.jpg',
  caption: caption ?? '게시물 $n',
  instagramMediaId: source == FeaturedPostSource.instagram
      ? (instagramMediaId ?? 'ig-$n')
      : null,
);

/// 연동한 계정의 인스타그램 게시물 하나(고르기 격자의 칸).
InstagramPost igPost(
  String id, {
  FeaturedPostKind kind = FeaturedPostKind.photo,
  int? durationSec,
  int? sizeBytes,
}) => InstagramPost(
  id: id,
  kind: kind,
  thumbnailUrl: 'https://picsum.test/$id.jpg',
  caption: '인스타 $id',
  durationSec: durationSec,
  sizeBytes: sizeBytes,
);
