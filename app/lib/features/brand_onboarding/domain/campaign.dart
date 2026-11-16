import '../../offer_terms/domain/offer_terms.dart' show ContentFormat;
import '../../principles/domain/principles.dart' show ProductTrialDays;

/// 캠페인이 "요구하지 않는 것". 서버의 `NotRequired`와 같은 세 가지다.
enum NotRequired {
  face('얼굴 출연'),
  fixedLines('정해진 대사'),
  scriptReading('대본 낭독');

  const NotRequired(this.label);

  /// 화면에 보이는 이름.
  final String label;
}

enum CampaignStatus { active, closed }

/// 캠페인 입력의 고정 값. 서버의 `CAMPAIGN_RULES`(`api/src/campaigns/campaign-rules.ts`)와 같다.
abstract final class CampaignRules {
  /// 제작비와 예산은 1만 원 단위다.
  static const moneyStep = 10000;
  static const feeMin = 10000;
  static const feeMax = 10000000;
  static const budgetMax = 100000000;
  static const headlineMax = 40;
  static const mustIncludeMax = 3;
  static const mustIncludeLength = 20;
}

/// 브랜드가 만든 캠페인. 브랜드는 진행 중인 캠페인을 하나만 가진다.
class Campaign {
  const Campaign({
    required this.id,
    required this.headline,
    required this.fee,
    required this.budget,
    required this.productProvided,
    required this.format,
    required this.startFrom,
    required this.trialDays,
    required this.mustInclude,
    required this.notRequired,
    required this.status,
  });

  final String id;
  final String headline;

  /// 크리에이터 한 명에게 주는 현금 고정비의 기본값(원).
  final int fee;

  /// 이 캠페인에 쓰려는 현금의 합(원).
  final int budget;
  final bool productProvided;
  final ContentFormat format;

  /// 시작 가능한 날(날짜만).
  final DateTime startFrom;
  final ProductTrialDays trialDays;
  final List<String> mustInclude;
  final List<NotRequired> notRequired;
  final CampaignStatus status;
}

/// 캠페인을 만들거나 고칠 때 보내는 값. 고치기도 모든 칸을 보낸다.
class CampaignInput {
  const CampaignInput({
    required this.headline,
    required this.fee,
    required this.budget,
    required this.productProvided,
    required this.format,
    required this.startFrom,
    required this.trialDays,
    required this.mustInclude,
    required this.notRequired,
  });

  final String headline;
  final int fee;
  final int budget;
  final bool productProvided;
  final ContentFormat format;
  final DateTime startFrom;
  final ProductTrialDays trialDays;
  final List<String> mustInclude;
  final List<NotRequired> notRequired;
}
