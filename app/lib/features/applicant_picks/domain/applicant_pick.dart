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

/// 추천 3명이 어디서 뽑혔는지. 서버가 정한다(`APPLICANTS`·`ALL`).
enum PicksSource {
  /// 이 가게에 지원 중인 사람 가운데서.
  applicants,

  /// 지원자가 없어 Cora 크리에이터 전체에서.
  all,
}

/// 가게와 잘 맞는 추천 한 명. 점수에 팔로워 수는 들지 않는다(서버가 정한다). 전체 크리에이터에서
/// 뽑았으면 지원이 없어서 [applicationId]·[appliedAt]·[pitch]가 null이다.
class ApplicantPick {
  const ApplicantPick({
    this.applicationId,
    required this.creator,
    this.appliedAt,
    this.pitch,
    this.reasons = const [],
  });

  final String? applicationId;
  final PickCreator creator;

  /// 지원한 때. 지원자 중에서 뽑았을 때만 있다.
  final DateTime? appliedAt;

  /// 크리에이터가 지원하며 쓴 한 줄. 없을 수 있다.
  final String? pitch;

  /// 추천한 이유. 화면은 ` · `로 이어 보인다.
  final List<String> reasons;
}

/// 추천 3명과 새 지원 수(넘긴 사람도 센다. 사장님 홈의 `새 지원`과 같다).
class ApplicantPicks {
  const ApplicantPicks({
    required this.items,
    required this.totalNew,
    this.source = PicksSource.applicants,
  });

  final List<ApplicantPick> items;
  final int totalNew;

  /// 지원자 쪽인지 전체 크리에이터 쪽인지. 홈의 `지원 있음`·`지원 없음`은 [totalNew]가 아니라 이것으로 가른다
  /// (지원 줄은 있어도 프로필이 모두 지워졌으면 [totalNew]가 0보다 커도 전체 쪽이다).
  final PicksSource source;
}
