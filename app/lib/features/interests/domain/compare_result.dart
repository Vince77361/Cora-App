import '../../offer_terms/domain/offer_terms.dart' show ContentFormat;
import '../../principles/domain/principles.dart' show FeeBand;
import '../../negotiation/domain/brand_usage_rights.dart';
import 'interest_card.dart';

/// 04 표의 줄 일곱 개. 서버의 `CompareField`와 같다.
enum CompareRow { deliverable, benefit, fee, perfCap, usage, start, face }

/// 04에서 견주는 후보 한 명. 값은 "그 후보와 지금 걸려 있는 조건"이다(설계 2장 04 표).
class CompareSide {
  const CompareSide({
    required this.creatorId,
    required this.name,
    required this.shortName,
    required this.state,
    required this.format,
    required this.pieces,
    required this.productProvided,
    required this.feeBand,
    required this.usageRights,
    required this.faceOk,
    this.photoUrl,
    this.fee,
    this.perfRate,
    this.perfCap,
    this.startDate,
    this.collaborationId,
  });

  final String creatorId;
  final String name;
  final String shortName;
  final String? photoUrl;
  final InterestState state;

  /// 서로 관심이면 그 협업의 id(`제안 보기`가 06으로 간다).
  final String? collaborationId;

  final ContentFormat format;
  final int pieces;
  final bool productProvided;

  /// 서로 관심이면 최신 판본의 제작비, 아니면 내 제안의 금액. 없으면 null이고 [feeBand]를 보여 준다.
  final int? fee;
  final FeeBand feeBand;

  /// 성과 추가의 단가(1,000회당 원). 표에는 없지만 이미 만든 제안을 다시 열 때 저장된 값을 지키려고 둔다.
  final int? perfRate;
  final int? perfCap;
  final BrandUsageRights usageRights;

  /// 서로 관심일 때 최신 판본의 제작 시작일(날짜만). 없으면 `일정 협의`.
  final DateTime? startDate;

  /// 크리에이터의 원칙 3번: 얼굴 출연이 괜찮은가.
  final bool faceOk;
}

/// 04 후보 비교. 팔로워 수는 이 값에 없다.
class CompareResult {
  const CompareResult({required this.sides, required this.differs});

  /// 표의 왼쪽, 오른쪽 후보.
  final List<CompareSide> sides;

  /// 두 후보의 보이는 값이 다른 줄(서버가 정한다. 앱은 그리기만 한다).
  final Set<CompareRow> differs;
}
