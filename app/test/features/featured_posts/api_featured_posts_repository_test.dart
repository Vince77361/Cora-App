import 'dart:convert';

import 'package:cora/features/featured_posts/data/api_featured_posts_repository.dart';
import 'package:cora/features/featured_posts/domain/featured_post.dart';
import 'package:cora/features/featured_posts/domain/featured_posts_repository.dart';
import 'package:cora_api/api.dart' as api;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../support/fake_http_client.dart';

ApiFeaturedPostsRepository _repo(FakeHttpClient fake) =>
    ApiFeaturedPostsRepository(
      api.ApiClient(basePath: 'http://127.0.0.1:3000')..client = fake,
    );

Map<String, Object?> _model(
  String id, {
  String source = 'INSTAGRAM',
  String kind = 'PHOTO',
  String? caption = '한 줄',
  String? mediaId = 'ig-1',
}) => {
  'id': id,
  'position': 1,
  'source': source,
  'kind': kind,
  'photoUrl': 'https://x.supabase.co/storage/v1/object/public/photos/$id.jpg',
  'mediaUrl': 'https://x.supabase.co/storage/v1/object/public/photos/$id.jpg',
  'caption': caption,
  'instagramMediaId': mediaId,
};

Map<String, dynamic> _body(http.BaseRequest request) =>
    jsonDecode((request as http.Request).body) as Map<String, dynamic>;

void main() {
  test('fetchMine reads my posts in order', () async {
    final fake = FakeHttpClient()
      ..body = jsonEncode([
        _model('p1'),
        _model('p2', source: 'GALLERY', mediaId: null, caption: null),
      ]);

    final posts = await _repo(fake).fetchMine();

    expect(fake.requests.single.method, 'GET');
    expect(fake.requests.single.url.path, '/creators/me/featured-posts');
    expect(posts.map((p) => p.id), ['p1', 'p2']);
    expect(posts.first.source, FeaturedPostSource.instagram);
    expect(posts.first.photoUrl, contains('p1.jpg'));
    expect(posts.first.instagramMediaId, 'ig-1');
    expect(posts.last.source, FeaturedPostSource.gallery);
    expect(posts.last.caption, isNull);
    expect(posts.every((p) => !p.isDraft), isTrue);
  });

  test(
    'replaceMine sends only the id for saved posts and only save fields for drafts',
    () async {
      final fake = FakeHttpClient()
        ..body = jsonEncode([_model('p1'), _model('p9')]);

      await _repo(fake).replaceMine([
        const FeaturedPost(
          id: 'p1',
          source: FeaturedPostSource.instagram,
          kind: FeaturedPostKind.photo,
          photoUrl: 'https://x/p1.jpg',
          caption: '한 줄',
          instagramMediaId: 'ig-1',
        ),
        const FeaturedPost(
          source: FeaturedPostSource.instagram,
          kind: FeaturedPostKind.video,
          // 초안의 미리보기 주소는 서버가 모르는 필드라 보내면 400이다.
          photoUrl: 'https://picsum.photos/x.jpg',
          caption: '영상 한 줄',
          instagramMediaId: 'ig-2',
          mediaPath: 'featured-posts/u/a.jpg',
          thumbnailPath: 'featured-posts/u/a.jpg',
        ),
        const FeaturedPost(
          source: FeaturedPostSource.gallery,
          kind: FeaturedPostKind.photo,
          photoUrl: null,
          caption: '사진첩',
          mediaPath: 'featured-posts/u/b.png',
        ),
      ]);

      final request = fake.requests.single;
      expect(request.method, 'PUT');
      expect(request.url.path, '/creators/me/featured-posts');
      final items = (_body(request)['items'] as List)
          .cast<Map<String, dynamic>>();
      expect(items, hasLength(3));
      expect(items[0]['id'], 'p1');
      expect(items[0]['mediaPath'], isNull);
      expect(items[0]['source'], isNull);
      expect(items[1]['id'], isNull);
      expect(items[1]['source'], 'INSTAGRAM');
      expect(items[1]['kind'], 'VIDEO');
      expect(items[1]['mediaPath'], 'featured-posts/u/a.jpg');
      expect(items[1]['thumbnailPath'], 'featured-posts/u/a.jpg');
      expect(items[1]['caption'], '영상 한 줄');
      expect(items[1]['instagramMediaId'], 'ig-2');
      expect(items[1].containsKey('photoUrl'), isFalse);
      expect(items[2]['source'], 'GALLERY');
      expect(items[2]['kind'], 'PHOTO');
      expect(items[2]['instagramMediaId'], isNull);
      expect(items[2].containsKey('photoUrl'), isFalse);
    },
  );

  test('replaceMine returns the saved list', () async {
    final fake = FakeHttpClient()..body = jsonEncode([_model('p1')]);

    final saved = await _repo(fake).replaceMine(const []);

    expect(saved.single.id, 'p1');
    expect(_body(fake.requests.single)['items'], isEmpty);
  });

  test('listInstagramPosts maps the grid cells', () async {
    final fake = FakeHttpClient()
      ..body = jsonEncode([
        {
          'id': 'ig-1',
          'kind': 'PHOTO',
          'caption': '글',
          'thumbnailUrl': 'https://picsum.photos/1.jpg',
          'durationSec': null,
          'sizeBytes': null,
        },
        {
          'id': 'ig-2',
          'kind': 'VIDEO',
          'caption': null,
          'thumbnailUrl': 'https://picsum.photos/2.jpg',
          'durationSec': 90,
          'sizeBytes': 1000,
        },
      ]);

    final posts = await _repo(fake).listInstagramPosts();

    expect(fake.requests.single.url.path, '/instagram/posts');
    expect(posts.first.importable, isTrue);
    expect(posts.last.kind, FeaturedPostKind.video);
    expect(posts.last.durationSec, 90);
    // 60초를 넘는 영상은 가져올 수 없다.
    expect(posts.last.importable, isFalse);
  });

  test('importInstagram posts the ids and returns drafts', () async {
    final fake = FakeHttpClient()
      ..body = jsonEncode([
        {
          'source': 'INSTAGRAM',
          'kind': 'VIDEO',
          'instagramMediaId': 'ig-2',
          'caption': '첫 줄',
          'mediaPath': 'featured-posts/u/t.jpg',
          'thumbnailPath': 'featured-posts/u/t.jpg',
          'photoUrl': 'https://x/t.jpg',
        },
      ]);

    final drafts = await _repo(fake).importInstagram(['ig-2']);

    final request = fake.requests.single;
    expect(request.method, 'POST');
    expect(request.url.path, '/instagram/posts/import');
    expect(_body(request), {
      'postIds': ['ig-2'],
    });
    final draft = drafts.single;
    expect(draft.isDraft, isTrue);
    expect(draft.kind, FeaturedPostKind.video);
    expect(draft.instagramMediaId, 'ig-2');
    expect(draft.mediaPath, 'featured-posts/u/t.jpg');
    expect(draft.thumbnailPath, 'featured-posts/u/t.jpg');
    expect(draft.photoUrl, 'https://x/t.jpg');
  });

  test('keeps the message of a 4xx but not of a 5xx', () async {
    final rejected = FakeHttpClient()
      ..statusCode = 409
      ..body = jsonEncode({
        'error': {
          'code': 'CONFLICT',
          'message': '이미 대표 게시물로 가져온 게시물이에요.',
          'details': null,
        },
      });
    await expectLater(
      _repo(rejected).importInstagram(['ig-1']),
      throwsA(
        isA<FeaturedPostsFailure>().having(
          (e) => e.message,
          'message',
          '이미 대표 게시물로 가져온 게시물이에요.',
        ),
      ),
    );

    final broken = FakeHttpClient()
      ..statusCode = 500
      ..body = jsonEncode({
        'error': {'code': 'INTERNAL', 'message': 'boom', 'details': null},
      });
    await expectLater(
      _repo(broken).replaceMine(const []),
      throwsA(
        isA<FeaturedPostsFailure>().having((e) => e.message, 'message', isNull),
      ),
    );
  });
}
