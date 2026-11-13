import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/trial_compare/domain/trial_compare_repository.dart';
import 'package:cora/features/trial_compare/domain/trial_comparison.dart';
import 'package:cora/features/trial_compare/domain/trial_info.dart';

import '../store_onboarding/fake_store_repository.dart';

/// 캔버스 G3의 견본: 체험단 월 300,000원 × 3과 블로그 글 9개, Cora는 오퍼 4건 · 152,000원과 릴스 4편, 평균 2.6배.
TrialComparison sampleComparison({
  List<ContentCount> contentByFormat = const [
    ContentCount(format: ContentFormat.reels, count: 4),
  ],
  int? averageMultiplierTenths = 26,
  int offerCount = 4,
}) => TrialComparison(
  trial: TrialSide(
    monthlyFee: 300000,
    endsOn: DateTime(2026, 12, 10),
    postCount: 9,
    spent: 900000,
  ),
  cora: CoraSide(
    offerCount: offerCount,
    spent: 152000,
    averageMultiplierTenths: averageMultiplierTenths,
    contentByFormat: contentByFormat,
  ),
);

/// 손으로 쓴 가짜 체험단 저장소. 가짜 가게 저장소를 함께 주면 저장·지우기·숨기기·본 표시가 서버처럼 가게의
/// 체험단 정보와 줄을 바꾼다.
class FakeTrialCompareRepository implements TrialCompareRepository {
  FakeTrialCompareRepository({TrialComparison? comparison, this.stores})
    : comparison = comparison ?? sampleComparison();

  TrialComparison comparison;
  final FakeStoreRepository? stores;

  bool failFetch = false;
  bool notFound = false;
  bool failSave = false;
  bool failSnooze = false;

  final saved = <TrialInfo>[];
  int deleted = 0;
  int snoozed = 0;
  int hintsSeen = 0;

  @override
  Future<TrialComparison> fetchComparison() async {
    if (notFound) throw const TrialCompareFailure(notFound: true);
    if (failFetch) throw const TrialCompareFailure();
    return comparison;
  }

  @override
  Future<void> saveInfo(TrialInfo info) async {
    if (failSave) throw const TrialCompareFailure();
    saved.add(info);
    // 이제 계약 정보가 있어서 서버가 비교를 준다.
    notFound = false;
    final s = stores?.store;
    if (s != null) stores!.store = withTrial(s, info: info);
  }

  @override
  Future<void> deleteInfo() async {
    deleted++;
    final s = stores?.store;
    if (s != null) stores!.store = withTrial(s);
  }

  @override
  Future<void> snooze() async {
    if (failSnooze) throw const TrialCompareFailure();
    snoozed++;
    final s = stores?.store;
    if (s != null) stores!.store = withTrial(s, info: s.trialInfo);
  }

  @override
  Future<void> markHintSeen() async {
    hintsSeen++;
    // 서버가 다음에 가게를 읽을 때부터 안내 줄이 없다. 지금 화면의 줄은 그대로 둔다.
  }
}
