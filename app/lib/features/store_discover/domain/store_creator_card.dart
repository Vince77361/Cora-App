import '../../discovery/domain/featured_post_ref.dart';

/// 사장님이 전체 둘러보기에서 한 장씩 넘겨 보는 크리에이터 카드. 사진과 한 줄은 대표 게시물이 정한다.
class StoreCreatorCard {
  const StoreCreatorCard({
    required this.creatorId,
    required this.displayName,
    this.contentFocus,
    this.followers,
    this.headline,
    this.photoUrl,
    this.posts = const [],
    this.tags = const [],
  });

  final String creatorId;

  /// 활동 이름.
  final String displayName;

  /// 콘텐츠 분야(크리에이터가 쓴 글). 없으면 null.
  final String? contentFocus;

  /// 연결한 인스타그램 계정의 팔로워 수. 연결이 없으면 null.
  final int? followers;

  /// 1번 대표 게시물의 한 줄과 사진.
  final String? headline;
  final String? photoUrl;

  /// 대표 게시물(1~4개, 차례대로).
  final List<FeaturedPostRef> posts;

  /// 꼬리표(`#` 없이). 협업 원칙이 없는 크리에이터는 빈 목록이다.
  final List<String> tags;

  // 같은 크리에이터는 같은 카드다. 덱이 `==`로 카드를 알아보고, 되돌리기가 카드를 다시 넣는다.
  @override
  bool operator ==(Object other) =>
      other is StoreCreatorCard && other.creatorId == creatorId;

  @override
  int get hashCode => creatorId.hashCode;
}
