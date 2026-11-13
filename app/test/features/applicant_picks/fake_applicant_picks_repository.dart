import 'package:cora/features/applicant_picks/domain/applicant_pick.dart';
import 'package:cora/features/applicant_picks/domain/applicant_picks_repository.dart';

/// 캔버스 G2의 견본 추천 세 명.
List<ApplicantPick> samplePicks() => const [
  ApplicantPick(
    applicationId: 'a1',
    creator: PickCreator(
      userId: 'c1',
      displayName: '하루 한 컵',
      regionSido: '서울특별시',
      regionSigungu: '성동구',
      contentFocus: '리빙 릴스',
      followers: 640,
    ),
    pitch: '김 오르는 첫 숟가락을 슬로모션으로 찍을게요',
    reasons: ['같은 구·군', '카페·식당 릴스 9개'],
  ),
  ApplicantPick(
    applicationId: 'a2',
    creator: PickCreator(
      userId: 'c2',
      displayName: '민의 옷장 기록',
      regionSido: '서울특별시',
      regionSigungu: '마포구',
      followers: 2100,
    ),
    pitch: '출근 전 라멘 한 그릇, 손만 나오게 찍을게요',
    reasons: ['데일리 릴스', '지난 협업 평소 대비 2.4배'],
  ),
  ApplicantPick(
    applicationId: 'a3',
    creator: PickCreator(
      userId: 'c3',
      displayName: '서윤의 작은 취향',
      regionSido: '서울특별시',
      regionSigungu: '강남구',
    ),
    pitch: '바 좌석 18석의 조용한 오후를 담을게요',
    reasons: ['소품·분위기 릴스'],
  ),
];

/// 손으로 쓴 가짜 지원자 추천 저장소. 넘긴 지원을 기록한다.
class FakeApplicantPicksRepository implements ApplicantPicksRepository {
  FakeApplicantPicksRepository({List<ApplicantPick>? picks, int? totalNew})
    : picks = picks ?? samplePicks(),
      totalNew = totalNew ?? (picks ?? samplePicks()).length;

  List<ApplicantPick> picks;
  int totalNew;
  bool failFetch = false;
  bool failSkip = false;
  final skipped = <String>[];

  @override
  Future<ApplicantPicks> fetchPicks() async {
    if (failFetch) throw const ApplicantPicksFailure();
    return ApplicantPicks(items: List.of(picks), totalNew: totalNew);
  }

  @override
  Future<void> skip(String applicationId) async {
    if (failSkip) throw const ApplicantPicksFailure();
    skipped.add(applicationId);
  }
}
