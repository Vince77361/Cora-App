import '../../discovery/domain/discovery_target.dart';
import '../../principles/domain/principles.dart' show FeeBand;

/// 03 목록에서 후보 하나의 상태. 넘긴 것은 목록에 나오지 않는다.
enum InterestState {
  /// 서로 관심이 닿아 협업이 생겼다.
  mutual,

  /// 내가 관심을 보냈고 상대의 응답을 기다린다.
  waiting,

  /// 보류. 저장만 하고 상대에게는 아무것도 전해지지 않았다.
  held,
}

/// 03 관심·보류의 카드 하나. 브랜드에게는 크리에이터, 크리에이터에게는 캠페인이다.
class InterestCard {
  const InterestCard({
    required this.target,
    required this.name,
    required this.shortName,
    required this.state,
    this.headline,
    this.photoUrl,
    this.fee,
    this.feeBand,
    this.startFrom,
    this.hasProposal = false,
    this.collaborationId,
  });

  /// 브랜드는 `creator`, 크리에이터는 `campaign`.
  final DiscoveryTarget target;

  /// 크리에이터의 활동 이름 또는 브랜드 이름.
  final String name;

  /// `{X}의 …` 꼴이면 X, 아니면 이름 전체(04의 버튼에 쓴다).
  final String shortName;
  final InterestState state;

  /// 크리에이터 카드의 대표 콘텐츠 한 줄 또는 캠페인 한 줄.
  final String? headline;
  final String? photoUrl;

  /// 카드 아래 글의 금액(원). 없으면 [feeBand]를 보여 준다.
  final int? fee;

  /// 크리에이터의 희망 제작비 구간(브랜드가 볼 때만).
  final FeeBand? feeBand;

  /// 서로 관심일 때 최신 판본의 제작 시작일(날짜만). 없으면 `일정 협의`.
  final DateTime? startFrom;

  /// 내가 보낸 관심에 제안이 붙어 있다.
  final bool hasProposal;

  /// 서로 관심이면 그 협업의 id.
  final String? collaborationId;

  String get id => target.id;

  /// 상태와 협업만 바꾼 카드(보류를 결정한 뒤 목록을 다시 읽지 못했을 때 지금 목록에서 바꾼다).
  InterestCard copyWith({InterestState? state, String? collaborationId}) =>
      InterestCard(
        target: target,
        name: name,
        shortName: shortName,
        state: state ?? this.state,
        headline: headline,
        photoUrl: photoUrl,
        fee: fee,
        feeBand: feeBand,
        startFrom: startFrom,
        hasProposal: hasProposal,
        collaborationId: collaborationId ?? this.collaborationId,
      );

  // 같은 대상은 같은 카드다(고른 카드를 목록을 다시 읽은 뒤에도 알아본다).
  @override
  bool operator ==(Object other) =>
      other is InterestCard && other.target == target;

  @override
  int get hashCode => target.hashCode;
}
