/// 오퍼를 보낼 크리에이터를 가리키는 요약. 지원자 목록과 보낸 오퍼 목록이 함께 쓴다.
class CreatorSummary {
  const CreatorSummary({
    required this.userId,
    required this.displayName,
    this.contentFocus,
    this.photoUrl,
  });

  final String userId;

  /// 활동 이름. 화면에는 실명이 아니라 이것을 보인다.
  final String displayName;

  /// 주로 만드는 콘텐츠(예: `맛집 릴스`). 비어 있을 수 있다.
  final String? contentFocus;
  final String? photoUrl;
}

/// 내 가게에 지원한 크리에이터 한 명.
class Applicant {
  const Applicant({
    required this.applicationId,
    required this.creator,
    required this.appliedAt,
  });

  final String applicationId;
  final CreatorSummary creator;
  final DateTime appliedAt;
}
