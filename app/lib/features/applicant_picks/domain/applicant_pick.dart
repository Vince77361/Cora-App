/// 추천된 지원자. 이름은 활동 이름이다.
class PickCreator {
  const PickCreator({
    required this.userId,
    required this.displayName,
    this.photoUrl,
    this.contentFocus,
    this.regionSido,
    this.regionSigungu,
    this.followers,
  });

  final String userId;
  final String displayName;
  final String? photoUrl;

  /// 주로 만드는 콘텐츠(예: `맛집 릴스`). 한 줄이 없을 때 큰 글자가 된다.
  final String? contentFocus;
  final String? regionSido;

  /// 구·군. 없으면 시·도를 보인다.
  final String? regionSigungu;

  /// 인스타그램을 연동한 사람의 팔로워 수. 연동하지 않았거나 읽지 못했으면 null이다.
  final int? followers;
}

/// 가게와 잘 맞는 지원 한 건. 점수에 팔로워 수는 들지 않는다(서버가 정한다).
class ApplicantPick {
  const ApplicantPick({
    required this.applicationId,
    required this.creator,
    this.pitch,
    this.reasons = const [],
  });

  final String applicationId;
  final PickCreator creator;

  /// 크리에이터가 지원하며 쓴 한 줄. 없을 수 있다.
  final String? pitch;

  /// 추천한 이유. 화면은 ` · `로 이어 보인다.
  final List<String> reasons;
}

/// 추천 3명과 새 지원 수(넘긴 사람도 센다. 사장님 홈의 `새 지원`과 같다).
class ApplicantPicks {
  const ApplicantPicks({required this.items, required this.totalNew});

  final List<ApplicantPick> items;
  final int totalNew;
}
