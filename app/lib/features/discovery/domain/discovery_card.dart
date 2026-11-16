import '../../principles/domain/principles.dart' show FeeBand;
import 'discovery_target.dart';
import '../../store_browse/domain/store_summary.dart';

/// 카드가 상대와 "잘 맞는 점"으로 보여 주는 이유(상세에 나온다). 서버의 `MatchReason`과 같다.
enum MatchReason {
  field('분야가 맞아요'),
  face('얼굴 출연 조건이 맞아요'),
  script('대본 조건이 맞아요'),
  fee('제작비가 맞아요'),
  trial('제품 사용 기간이 맞아요');

  const MatchReason(this.label);

  /// 화면에 보이는 문구.
  final String label;
}

/// 브랜드가 한 장씩 넘겨 보는 크리에이터 카드(01).
class CreatorCard {
  const CreatorCard({
    required this.creatorId,
    required this.displayName,
    required this.feeBand,
    this.headline,
    this.photoUrl,
    this.tags = const [],
    this.reasons = const [],
    this.theyLikedMe = false,
  });

  final String creatorId;
  final String displayName;

  /// 대표 콘텐츠 한 줄. 없으면 null.
  final String? headline;
  final String? photoUrl;

  /// 희망 제작비 구간.
  final FeeBand feeBand;

  /// 꼬리표(`#` 없이).
  final List<String> tags;
  final List<MatchReason> reasons;

  /// 상대가 먼저 관심을 보냈는지(추천 순서에만 쓰이고 화면에 보이지 않는다).
  final bool theyLikedMe;

  // 같은 크리에이터는 같은 카드다. 덱이 `==`로 카드를 알아보고, 되돌리기가 카드를 다시 넣는다.
  @override
  bool operator ==(Object other) =>
      other is CreatorCard && other.creatorId == creatorId;

  @override
  int get hashCode => creatorId.hashCode;
}

/// 크리에이터가 넘겨 보는 카드(08). 캠페인 카드와 가게 카드가 있다.
sealed class DiscoveryCard {
  const DiscoveryCard();

  String get headline;
  String? get photoUrl;
  List<String> get tags;
  List<MatchReason> get reasons;

  /// 이 카드에 결정을 보낼 때의 대상.
  DiscoveryTarget get target;
}

/// 브랜드의 캠페인 카드.
class CampaignCard extends DiscoveryCard {
  const CampaignCard({
    required this.campaignId,
    required this.brandName,
    required this.headline,
    required this.fee,
    required this.productProvided,
    this.brandTagline,
    this.photoUrl,
    this.tags = const [],
    this.reasons = const [],
  });

  final String campaignId;
  final String brandName;
  final String? brandTagline;
  @override
  final String headline;

  @override
  DiscoveryTarget get target => DiscoveryTarget.campaign(campaignId);

  /// 제작비(원).
  final int fee;
  final bool productProvided;
  @override
  final String? photoUrl;
  @override
  final List<String> tags;
  @override
  final List<MatchReason> reasons;

  @override
  bool operator ==(Object other) =>
      other is CampaignCard && other.campaignId == campaignId;

  @override
  int get hashCode => campaignId.hashCode;
}

/// 가게의 모집 카드.
class StoreCard extends DiscoveryCard {
  const StoreCard({
    required this.store,
    required this.headline,
    this.rewardLine,
    this.otherSido,
    this.photoUrl,
    this.tags = const [],
    this.reasons = const [],
  });

  final StoreSummary store;
  @override
  final String headline;

  @override
  DiscoveryTarget get target => DiscoveryTarget.store(store.id);

  /// 보상 줄(`식사권 + 조회수 수당`). 없으면 null.
  final String? rewardLine;

  /// 내 지역이 아닌 가게일 때 그 시·도.
  final String? otherSido;
  @override
  final String? photoUrl;
  @override
  final List<String> tags;
  @override
  final List<MatchReason> reasons;

  @override
  bool operator ==(Object other) =>
      other is StoreCard && other.store.id == store.id;

  @override
  int get hashCode => store.id.hashCode;
}

/// 역할 없는 사용자가 읽기만 하는 둘러보기 카드(9A). 인스타그램 아이디와 잘 맞는 이유가 없다.
class PreviewCard {
  const PreviewCard({
    required this.creatorId,
    required this.displayName,
    required this.feeBand,
    this.headline,
    this.photoUrl,
    this.tags = const [],
  });

  final String creatorId;
  final String displayName;
  final String? headline;
  final String? photoUrl;
  final FeeBand feeBand;
  final List<String> tags;

  @override
  bool operator ==(Object other) =>
      other is PreviewCard && other.creatorId == creatorId;

  @override
  int get hashCode => creatorId.hashCode;
}
