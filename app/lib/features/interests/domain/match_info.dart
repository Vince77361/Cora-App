/// 05 서로 관심 확인에 필요한 것. 협업 [collaborationId]에서 읽는다.
class MatchInfo {
  const MatchInfo({
    required this.collaborationId,
    required this.brandName,
    required this.creatorName,
    required this.isBrand,
    required this.pendingProposals,
    required this.baseVersion,
    this.brandTagline,
    this.brandPhotoUrl,
    this.creatorPhotoUrl,
  });

  final String collaborationId;
  final String brandName;

  /// 브랜드의 한 줄 소개. 없으면 표지에 브랜드 이름을 쓴다.
  final String? brandTagline;
  final String? brandPhotoUrl;
  final String creatorName;
  final String? creatorPhotoUrl;

  /// 내가 브랜드 쪽이다(07로 가는 길이 역할마다 다르다).
  final bool isBrand;

  /// 내가 응답할 차례인 판본 수. 서로 관심이 막 닿았을 때는 1이다.
  final int pendingProposals;

  /// 내가 먼저 제안할 때 기준이 되는 최신 판본 번호(`STALE_VERSION` 검사에 쓴다).
  final int baseVersion;
}
