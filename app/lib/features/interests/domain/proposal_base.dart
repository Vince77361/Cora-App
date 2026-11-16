import '../../negotiation/domain/brand_usage_rights.dart';
import '../../offer_terms/domain/offer_terms.dart' show ContentFormat, ViewPay;

/// 이미 있는 협업에서 새 판본을 내려고 F1을 열 때 필요한 것. 받는 사람은 협업의 상대이고, 처음 값은
/// 최신 판본의 값이다.
class ProposalBase {
  const ProposalBase({
    required this.counterpartName,
    required this.recruitLine,
    required this.format,
    required this.pieces,
    required this.usageRights,
    required this.fee,
    required this.productProvided,
    required this.proposedByBrand,
    this.counterpartPhotoUrl,
    this.performance,
  });

  final String counterpartName;
  final String? counterpartPhotoUrl;

  /// `{브랜드 이름} · {캠페인 한 줄}`.
  final String recruitLine;
  final ContentFormat format;
  final int pieces;
  final BrandUsageRights usageRights;
  final int fee;
  final bool productProvided;
  final ViewPay? performance;

  /// 내가 브랜드 쪽이다.
  final bool proposedByBrand;
}
