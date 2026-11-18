import 'package:cora_api/api.dart' as api;

import '../../../core/network/api_error.dart';
import '../domain/featured_post.dart';
import '../domain/featured_posts_repository.dart';

/// 생성된 API 클라이언트(`cora_api`)로 대표 게시물을 주고받는다. 생성된 타입은 이 파일 밖으로 내보내지 않는다.
class ApiFeaturedPostsRepository implements FeaturedPostsRepository {
  ApiFeaturedPostsRepository(api.ApiClient client)
    : _creators = api.CreatorsApi(client),
      _instagram = api.InstagramApi(client);

  final api.CreatorsApi _creators;
  final api.InstagramApi _instagram;

  @override
  Future<List<FeaturedPost>> fetchMine() async {
    try {
      final models = await _creators.getMyFeaturedPosts();
      if (models == null) throw const FeaturedPostsFailure();
      return [for (final m in models) _fromModel(m)];
    } on FeaturedPostsFailure {
      rethrow;
    } catch (error) {
      throw _failure(error);
    }
  }

  @override
  Future<List<FeaturedPost>> replaceMine(List<FeaturedPost> posts) async {
    try {
      final models = await _creators.replaceMyFeaturedPosts(
        api.ReplaceFeaturedPostsDto(
          items: [for (final p in posts) _toInput(p)],
        ),
      );
      if (models == null) throw const FeaturedPostsFailure();
      return [for (final m in models) _fromModel(m)];
    } on FeaturedPostsFailure {
      rethrow;
    } catch (error) {
      throw _failure(error);
    }
  }

  @override
  Future<List<InstagramPost>> listInstagramPosts() async {
    try {
      final models = await _instagram.listInstagramPosts();
      if (models == null) throw const FeaturedPostsFailure();
      return [
        for (final m in models)
          InstagramPost(
            id: m.id,
            kind: _kind(m.kind),
            thumbnailUrl: m.thumbnailUrl,
            caption: m.caption,
            durationSec: m.durationSec,
            sizeBytes: m.sizeBytes,
          ),
      ];
    } on FeaturedPostsFailure {
      rethrow;
    } catch (error) {
      throw _failure(error);
    }
  }

  @override
  Future<List<FeaturedPost>> importInstagram(List<String> postIds) async {
    try {
      final drafts = await _instagram.importInstagramPosts(
        api.ImportInstagramPostsDto(postIds: postIds),
      );
      if (drafts == null) throw const FeaturedPostsFailure();
      return [
        for (final d in drafts)
          FeaturedPost(
            source: _source(d.source_),
            kind: _kind(d.kind),
            photoUrl: d.photoUrl,
            caption: d.caption,
            instagramMediaId: d.instagramMediaId,
            mediaPath: d.mediaPath,
            thumbnailPath: d.thumbnailPath,
          ),
      ];
    } on FeaturedPostsFailure {
      rethrow;
    } catch (error) {
      throw _failure(error);
    }
  }

  /// 서버가 받는 저장 필드만 보낸다. 초안의 `photoUrl`은 미리보기용이라 보내면 400이다(서버가 모르는 필드를 막는다).
  static api.FeaturedPostInputDto _toInput(FeaturedPost p) {
    final id = p.id;
    // 이미 있는 게시물은 ID만 보낸다. 서버가 그 행을 그대로 두고 이 차례에 놓는다.
    if (id != null) return api.FeaturedPostInputDto(id: id);
    return api.FeaturedPostInputDto(
      source_: switch (p.source) {
        FeaturedPostSource.instagram => api.FeaturedPostSource.INSTAGRAM,
        FeaturedPostSource.gallery => api.FeaturedPostSource.GALLERY,
      },
      kind: switch (p.kind) {
        FeaturedPostKind.photo => api.FeaturedPostKind.PHOTO,
        FeaturedPostKind.video => api.FeaturedPostKind.VIDEO,
      },
      mediaPath: p.mediaPath,
      thumbnailPath: p.thumbnailPath,
      caption: p.caption,
      instagramMediaId: p.instagramMediaId,
    );
  }

  static FeaturedPost _fromModel(api.FeaturedPostModel m) => FeaturedPost(
    id: m.id,
    source: _source(m.source_),
    kind: _kind(m.kind),
    photoUrl: m.photoUrl,
    caption: m.caption,
    instagramMediaId: m.instagramMediaId,
  );

  static FeaturedPostSource _source(api.FeaturedPostSource s) =>
      s == api.FeaturedPostSource.INSTAGRAM
      ? FeaturedPostSource.instagram
      : FeaturedPostSource.gallery;

  static FeaturedPostKind _kind(api.FeaturedPostKind k) =>
      k == api.FeaturedPostKind.VIDEO
      ? FeaturedPostKind.video
      : FeaturedPostKind.photo;

  /// 서버 문구는 4xx일 때만 담는다. 5xx 본문은 화면에 보이지 않는다.
  static FeaturedPostsFailure _failure(Object error) {
    final e = ApiError.from(error);
    final status = e.status;
    return FeaturedPostsFailure(
      message: status != null && status >= 400 && status < 500
          ? e.message
          : null,
    );
  }
}
