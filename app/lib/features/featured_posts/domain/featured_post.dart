import 'dart:typed_data';

/// 대표 게시물이 어디서 왔는지(서버 `FeaturedPostSource`).
enum FeaturedPostSource { instagram, gallery }

/// 사진인지 영상인지. 인스타 영상도 지금은 첫 화면 그림만 가져온다(서버 판단, 영상 보관은 7번 계획).
enum FeaturedPostKind { photo, video }

/// 크리에이터의 대표 게시물 한 개(최대 4개, 순서가 곧 목록의 차례).
///
/// 서버에 저장된 것은 [id]가 있고, 아직 저장하지 않은 것(인스타에서 가져온 초안, 사진첩에서 올린 사진)은
/// [id]가 null이며 저장할 때 [mediaPath] 등으로 서버에 보낸다. 순서는 목록의 차례라서 따로 들고 있지 않는다
/// (끌어 바꿀 때 번호가 어긋나지 않게).
class FeaturedPost {
  const FeaturedPost({
    this.id,
    required this.source,
    required this.kind,
    required this.photoUrl,
    required this.caption,
    this.instagramMediaId,
    this.mediaPath,
    this.thumbnailPath,
    this.previewBytes,
  });

  /// 서버 행의 ID. 아직 저장하지 않은 초안이면 null.
  final String? id;
  final FeaturedPostSource source;
  final FeaturedPostKind kind;

  /// 카드에 보이는 그림의 주소. 사진첩에서 막 올린 초안은 주소가 없어 [previewBytes]가 대신 그려진다.
  final String? photoUrl;

  /// 한 줄 설명(1~40자). 서버가 옛 데이터를 비워 둘 수 있어 null일 수 있다.
  final String? caption;

  /// 원본 인스타그램 게시물 ID. 인스타그램 출처에만 있다.
  final String? instagramMediaId;

  /// 초안의 저장 필드: 서버가 가져와 올려 둔 파일 경로(`featured-posts/…`). 서버에 저장된 행은 null.
  final String? mediaPath;
  final String? thumbnailPath;

  /// 사진첩에서 올린 초안의 미리보기 바이트(서버 주소가 없을 때만).
  final Uint8List? previewBytes;

  bool get isDraft => id == null;
}

/// 인스타그램 게시물 목록의 한 칸(고르기 화면). 서버 `InstagramPostModel`.
class InstagramPost {
  const InstagramPost({
    required this.id,
    required this.kind,
    required this.thumbnailUrl,
    this.caption,
    this.durationSec,
    this.sizeBytes,
  });

  final String id;
  final FeaturedPostKind kind;
  final String thumbnailUrl;
  final String? caption;
  final int? durationSec;
  final int? sizeBytes;

  /// 영상 한도(60초, 100MB)를 넘으면 가져올 수 없다. 길이·크기를 모르면(null) 서버가 막지 않는다.
  bool get importable =>
      kind != FeaturedPostKind.video ||
      ((durationSec ?? 0) <= maxVideoSeconds &&
          (sizeBytes ?? 0) <= maxVideoBytes);

  static const maxVideoSeconds = 60;
  static const maxVideoBytes = 100 * 1024 * 1024;
}

/// 대표 게시물의 한도. 서버 `featured-post-rules.ts`와 같은 값이다.
abstract final class FeaturedPostLimits {
  static const maxPosts = 4;
  static const maxCaptionLength = 40;

  /// 사진첩에서 올리는 사진은 서버 사진 한도(5MB)를 넘지 않게 올리기 전에 긴 변 2048, 품질 85로 줄인다(설계 7.3).
  static const photoMaxSide = 2048;
  static const photoQuality = 85;
}
