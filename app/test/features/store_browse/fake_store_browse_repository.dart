import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/store_browse/domain/store_browse_repository.dart';
import 'package:cora/features/store_browse/domain/store_detail.dart';
import 'package:cora/features/store_browse/domain/store_summary.dart';

/// 서버의 기본 시드와 같은 조건(식사권 + 조회수당)의 가게.
StoreSummary ramenStore({
  String id = '1',
  String name = '한그릇 라멘',
  String? category = '라멘집',
  String? neighborhood = '성수동',
  String? regionSido = '서울특별시',
  OfferTerms? terms,
}) => StoreSummary(
  id: id,
  name: name,
  category: category,
  neighborhood: neighborhood,
  regionSido: regionSido,
  regionSigungu: '성동구',
  coverPhotoUrl: null,
  defaultTerms:
      terms ??
      const OfferTerms(
        format: ContentFormat.reels,
        rewardType: RewardType.both,
        voucherName: '2인 식사권',
        voucherValue: 40000,
        perViewAmount: 10,
        perViewCap: 100000,
      ),
);

/// 손으로 쓴 가짜 공개 가게 저장소. 서버가 가진 가게와 내 지원 상태를 흉내 낸다.
class FakeStoreBrowseRepository implements StoreBrowseRepository {
  FakeStoreBrowseRepository({List<StoreSummary>? stores})
    : stores = stores ?? [ramenStore()];

  List<StoreSummary> stores;

  /// 가게 id별 내 지원 상태. 없으면 [MyApplicationStatus.none].
  final Map<String, MyApplicationStatus> statuses = {};

  String? intro = '진한 국물을 12시간 끓이는 작은 라멘집이에요. 김이 오르는 첫 숟가락 장면을 담아주세요.';
  String? bestShootingTime = '오후 3시 – 5시';

  bool failFetch = false;
  bool failApply = false;

  /// true이면 [apply]·[cancelApplication]이 서버에서 409를 받는다. 그사이 상태는 [conflictStatus]가 된다.
  bool conflictOnChange = false;
  MyApplicationStatus conflictStatus = MyApplicationStatus.offered;

  int fetchDetailCalls = 0;
  final List<String> applied = [];
  final List<String> cancelled = [];

  @override
  Future<List<StoreSummary>> fetchPublished() async {
    if (failFetch) throw const StoreBrowseFailure();
    return List.of(stores);
  }

  @override
  Future<StoreDetail> fetchDetail(String storeId) async {
    fetchDetailCalls++;
    if (failFetch) throw const StoreBrowseFailure();
    return StoreDetail(
      summary: stores.firstWhere((s) => s.id == storeId),
      myApplicationStatus: statuses[storeId] ?? MyApplicationStatus.none,
      intro: intro,
      bestShootingTime: bestShootingTime,
    );
  }

  @override
  Future<void> apply(String storeId) async {
    if (conflictOnChange) {
      statuses[storeId] = conflictStatus;
      throw const StoreBrowseFailure(conflict: true);
    }
    if (failApply) throw const StoreBrowseFailure();
    applied.add(storeId);
    statuses[storeId] = MyApplicationStatus.applied;
  }

  @override
  Future<void> cancelApplication(String storeId) async {
    if (conflictOnChange) {
      statuses[storeId] = conflictStatus;
      throw const StoreBrowseFailure(conflict: true);
    }
    if (failApply) throw const StoreBrowseFailure();
    cancelled.add(storeId);
    statuses[storeId] = MyApplicationStatus.none;
  }
}
