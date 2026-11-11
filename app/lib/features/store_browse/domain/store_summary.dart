import '../../offer_terms/domain/offer_terms.dart';

/// 크리에이터가 목록에서 보는 공개된 가게 한 곳.
class StoreSummary {
  const StoreSummary({
    required this.id,
    required this.name,
    required this.defaultTerms,
    this.category,
    this.neighborhood,
    this.regionSido,
    this.regionSigungu,
    this.coverPhotoUrl,
  });

  final String id;
  final String name;

  /// 표시용 업종(예: `라멘집`).
  final String? category;
  final String? neighborhood;
  final String? regionSido;
  final String? regionSigungu;
  final String? coverPhotoUrl;

  /// 사장님이 정한 기본 오퍼 조건. 가게 페이지에 모집 조건으로 보인다.
  final OfferTerms defaultTerms;

  /// `라멘집, 성수동`처럼 사진 위에 보이는 한 줄. 둘 다 없으면 null.
  String? get categoryAndNeighborhood {
    final parts = [
      category,
      neighborhood,
    ].whereType<String>().map((s) => s.trim()).where((s) => s.isNotEmpty);
    return parts.isEmpty ? null : parts.join(', ');
  }
}
