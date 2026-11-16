import '../../store_onboarding/domain/my_store.dart' show IndustryCategory;

/// 브랜드 담당자의 프로필(크리에이터에게 보이는 브랜드 이름·한 줄 소개·업종·대표 사진).
class BrandProfile {
  const BrandProfile({
    required this.name,
    required this.industry,
    this.tagline,
    this.photoUrl,
  });

  final String name;

  /// 한 줄 소개. 없으면 null.
  final String? tagline;
  final IndustryCategory industry;

  /// 대표 사진을 볼 수 있는 주소. 없으면 null.
  final String? photoUrl;

  @override
  bool operator ==(Object other) =>
      other is BrandProfile &&
      other.name == name &&
      other.tagline == tagline &&
      other.industry == industry &&
      other.photoUrl == photoUrl;

  @override
  int get hashCode => Object.hash(name, tagline, industry, photoUrl);
}
