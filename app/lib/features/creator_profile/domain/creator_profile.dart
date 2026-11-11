/// 크리에이터의 최소 프로필(가게 사장님에게 보이는 이름·활동 지역·사진).
class CreatorProfile {
  const CreatorProfile({
    required this.displayName,
    required this.regionSido,
    this.regionSigungu,
    this.contentFocus,
    this.instagramHandle,
    this.photoUrl,
  });

  final String displayName;
  final String regionSido;
  final String? regionSigungu;
  final String? contentFocus;
  final String? instagramHandle;

  /// 사진을 볼 수 있는 주소. 사진이 없으면 null.
  final String? photoUrl;

  @override
  bool operator ==(Object other) =>
      other is CreatorProfile &&
      other.displayName == displayName &&
      other.regionSido == regionSido &&
      other.regionSigungu == regionSigungu &&
      other.contentFocus == contentFocus &&
      other.instagramHandle == instagramHandle &&
      other.photoUrl == photoUrl;

  @override
  int get hashCode => Object.hash(
    displayName,
    regionSido,
    regionSigungu,
    contentFocus,
    instagramHandle,
    photoUrl,
  );
}
