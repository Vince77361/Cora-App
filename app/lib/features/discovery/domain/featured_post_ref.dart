/// 카드가 보여 주는 대표 게시물 하나(사진과 한 줄). 크리에이터가 넣은 순서대로 카드에 들어 있다.
class FeaturedPostRef {
  const FeaturedPostRef({required this.photoUrl, this.caption});

  /// 카드에 보이는 그림. 없거나 불러오지 못하면 바탕색만 보인다.
  final String? photoUrl;

  /// 한 줄(1~40자). 옛 데이터는 없을 수 있다.
  final String? caption;
}
