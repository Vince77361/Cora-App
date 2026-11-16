import '../../principles/domain/principles.dart' show ProductTrialDays;
import 'discovery_card.dart';

/// 캠페인이 요구하지 않는 것(서버의 `NotRequired`).
enum NotRequiredItem {
  face('얼굴 출연'),
  fixedLines('정해진 대사'),
  scriptReading('대본 낭독');

  const NotRequiredItem(this.label);

  /// D1의 `요구하지 않아요` 목록에 보이는 문구(캔버스).
  final String label;
}

/// D1 캠페인 상세. 카드에 일정, 제품 사용 기간, 꼭 담을 것, 요구하지 않는 것, 겹치는 규칙의 수가 더해진다.
/// 캠페인의 예산은 크리에이터에게 내려오지 않는다.
class CampaignDetail {
  const CampaignDetail({
    required this.campaignId,
    required this.brandName,
    required this.headline,
    required this.fee,
    required this.productProvided,
    required this.startFrom,
    required this.trialDays,
    this.brandTagline,
    this.photoUrl,
    this.tags = const [],
    this.reasons = const [],
    this.mustInclude = const [],
    this.notRequired = const [],
    required this.overlapCount,
  });

  final String campaignId;
  final String brandName;
  final String? brandTagline;
  final String headline;

  /// 제작비(원).
  final int fee;
  final bool productProvided;
  final String? photoUrl;
  final List<String> tags;

  /// 내 협업 원칙과 겹치는 규칙. 많을수록 잘 맞는다.
  final List<MatchReason> reasons;

  /// 시작 가능한 날.
  final DateTime startFrom;
  final ProductTrialDays trialDays;
  final List<String> mustInclude;
  final List<NotRequiredItem> notRequired;

  /// `내 협업 원칙과 {n}개가 겹쳐요`의 n.
  final int overlapCount;

  /// 결정(넘기기·관심 보내기)을 보낼 때 쓰는 카드 모양.
  CampaignCard get asCard => CampaignCard(
    campaignId: campaignId,
    brandName: brandName,
    brandTagline: brandTagline,
    headline: headline,
    fee: fee,
    productProvided: productProvided,
    photoUrl: photoUrl,
    tags: tags,
    reasons: reasons,
  );
}
