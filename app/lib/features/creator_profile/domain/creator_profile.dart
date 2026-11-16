/// 크리에이터의 최소 프로필(가게 사장님에게 보이는 이름·활동 지역·사진).
class CreatorProfile {
  const CreatorProfile({
    required this.displayName,
    required this.regionSido,
    this.regionSigungu,
    this.contentFocus,
    this.instagramHandle,
    this.photoUrl,
    this.cardHeadline,
    this.cardPhotoUrl,
  });

  final String displayName;
  final String regionSido;
  final String? regionSigungu;
  final String? contentFocus;
  final String? instagramHandle;

  /// 사진을 볼 수 있는 주소. 사진이 없으면 null.
  final String? photoUrl;

  /// 브랜드가 보는 카드의 `대표 콘텐츠 한 줄`(최대 40자)과 `대표 사진`의 주소. 없으면 null.
  final String? cardHeadline;
  final String? cardPhotoUrl;

  @override
  bool operator ==(Object other) =>
      other is CreatorProfile &&
      other.displayName == displayName &&
      other.regionSido == regionSido &&
      other.regionSigungu == regionSigungu &&
      other.contentFocus == contentFocus &&
      other.instagramHandle == instagramHandle &&
      other.photoUrl == photoUrl &&
      other.cardHeadline == cardHeadline &&
      other.cardPhotoUrl == cardPhotoUrl;

  @override
  int get hashCode => Object.hash(
    displayName,
    regionSido,
    regionSigungu,
    contentFocus,
    instagramHandle,
    photoUrl,
    cardHeadline,
    cardPhotoUrl,
  );
}
