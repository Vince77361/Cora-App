import 'package:cora_api/api.dart' as api;

import '../../../core/network/api_error.dart';
import '../../offer_terms/data/offer_terms_from_wire.dart';
import '../domain/trial_compare_repository.dart';
import '../domain/trial_comparison.dart';
import '../domain/trial_info.dart';

/// 생성된 API 클라이언트(`cora_api`)로 체험단 비교와 계약 정보를 주고받는다. 생성된 타입은 이 파일 밖으로
/// 내보내지 않는다.
class ApiTrialCompareRepository implements TrialCompareRepository {
  ApiTrialCompareRepository(api.ApiClient client)
    : _insights = api.StoreInsightsApi(client),
      _stores = api.StoresApi(client);

  final api.StoreInsightsApi _insights;
  final api.StoresApi _stores;

  @override
  Future<TrialComparison> fetchComparison() => _guard(() async {
    final m = await _insights.getMyStoreTrialComparison();
    if (m == null) throw const TrialCompareFailure();
    // 종료일을 읽지 못하면 오늘 날짜로 때우지 않고 실패로 둔다.
    final endsOn = parseTrialDate(m.trial.endsOn);
    if (endsOn == null) throw const TrialCompareFailure();
    return TrialComparison(
      trial: TrialSide(
        monthlyFee: m.trial.monthlyFee,
        endsOn: endsOn,
        postCount: m.trial.postCount,
        spent: m.trial.spent,
      ),
      cora: CoraSide(
        offerCount: m.cora.offerCount,
        spent: m.cora.spent,
        averageMultiplierTenths: m.cora.averageMultiplierTenths,
        contentByFormat: [
          for (final c in m.cora.contentByFormat)
            ContentCount(format: formatFromWire(c.format), count: c.count),
        ],
      ),
    );
  });

  @override
  Future<void> saveInfo(TrialInfo info) => _guard(
    () => _stores.putMyStoreTrialInfo(
      api.TrialInfoDto(
        monthlyFee: info.monthlyFee,
        endsOn: formatTrialDate(info.endsOn),
        postCount: info.postCount,
      ),
    ),
  );

  @override
  Future<void> deleteInfo() => _guard(_stores.deleteMyStoreTrialInfo);

  @override
  Future<void> snooze() => _guard(_stores.snoozeMyStoreTrialCompare);

  @override
  Future<void> markHintSeen() => _guard(_stores.markMyStoreTrialHintSeen);

  /// 어떤 실패든 [TrialCompareFailure] 하나로 모은다. 서버 오류 본문과 예외 메시지는 버린다.
  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on TrialCompareFailure {
      rethrow;
    } catch (error) {
      throw TrialCompareFailure(notFound: ApiError.from(error).isNotFound);
    }
  }
}
