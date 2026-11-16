import 'package:cora_api/api.dart' as api;

import '../../../core/network/api_error.dart';
import '../../store_onboarding/domain/my_store.dart' show IndustryCategory;
import '../domain/principles.dart';
import '../domain/principles_repository.dart';

/// 생성된 API 클라이언트(`cora_api`)로 내 협업 원칙을 주고받는다. 생성된 타입은 이 파일 밖으로
/// 내보내지 않는다.
class ApiPrinciplesRepository implements PrinciplesRepository {
  ApiPrinciplesRepository(api.ApiClient client)
    : _principles = api.PrinciplesApi(client);

  final api.PrinciplesApi _principles;

  @override
  Future<Principles?> fetchMine() async {
    try {
      final model = await _principles.getMyPrinciples();
      // 서버는 원칙이 없으면 404로 답한다. 본문이 비는 성공은 없으므로 실패로 본다.
      if (model == null) throw const PrinciplesFailure();
      return _fromModel(model);
    } on PrinciplesFailure {
      rethrow;
    } catch (error) {
      if (ApiError.from(error).isNotFound) return null;
      throw const PrinciplesFailure();
    }
  }

  @override
  Future<Principles> save(Principles principles) async {
    try {
      final model = await _principles.upsertMyPrinciples(
        api.UpsertPrinciplesDto(
          fields: [for (final c in principles.fields) _industryToWire(c)],
          blockedIndustries: [
            for (final c in principles.blockedIndustries) _industryToWire(c),
          ],
          faceOk: principles.faceOk,
          scriptOk: principles.scriptOk,
          honestReview: principles.honestReview,
          feeBand: _feeToWire(principles.feeBand),
          trialDays: _trialToWire(principles.trialDays),
        ),
      );
      if (model == null) throw const PrinciplesFailure();
      return _fromModel(model);
    } on PrinciplesFailure {
      rethrow;
    } catch (_) {
      throw const PrinciplesFailure();
    }
  }

  static Principles _fromModel(api.PrinciplesModel m) => Principles(
    fields: [for (final c in m.fields) _industryFromWire(c)],
    blockedIndustries: [
      for (final c in m.blockedIndustries) _industryFromWire(c),
    ],
    faceOk: m.faceOk,
    scriptOk: m.scriptOk,
    honestReview: m.honestReview,
    feeBand: _feeFromWire(m.feeBand),
    trialDays: _trialFromWire(m.trialDays),
  );
}

const _industries = <IndustryCategory, api.IndustryCategory>{
  IndustryCategory.foodCafe: api.IndustryCategory.FOOD_CAFE,
  IndustryCategory.beauty: api.IndustryCategory.BEAUTY,
  IndustryCategory.fashion: api.IndustryCategory.FASHION,
  IndustryCategory.accessory: api.IndustryCategory.ACCESSORY,
  IndustryCategory.living: api.IndustryCategory.LIVING,
  IndustryCategory.grocery: api.IndustryCategory.GROCERY,
  IndustryCategory.digital: api.IndustryCategory.DIGITAL,
  IndustryCategory.health: api.IndustryCategory.HEALTH,
  IndustryCategory.other: api.IndustryCategory.OTHER,
  IndustryCategory.alcohol: api.IndustryCategory.ALCOHOL,
  IndustryCategory.gambling: api.IndustryCategory.GAMBLING,
  IndustryCategory.loan: api.IndustryCategory.LOAN,
  IndustryCategory.dietSupplement: api.IndustryCategory.DIET_SUPPLEMENT,
};

const _fees = <FeeBand, api.FeeBand>{
  FeeBand.w200k: api.FeeBand.W200K,
  FeeBand.w300k: api.FeeBand.W300K,
  FeeBand.w400k: api.FeeBand.W400K,
  FeeBand.w500kPlus: api.FeeBand.W500K_PLUS,
};

const _trials = <ProductTrialDays, api.ProductTrialDays>{
  ProductTrialDays.d3: api.ProductTrialDays.D3,
  ProductTrialDays.d7: api.ProductTrialDays.D7,
  ProductTrialDays.d14: api.ProductTrialDays.D14,
  ProductTrialDays.any: api.ProductTrialDays.ANY,
};

api.IndustryCategory _industryToWire(IndustryCategory c) => _industries[c]!;
IndustryCategory _industryFromWire(api.IndustryCategory c) =>
    _industries.entries.firstWhere((e) => e.value == c).key;

api.FeeBand _feeToWire(FeeBand v) => _fees[v]!;
FeeBand _feeFromWire(api.FeeBand v) =>
    _fees.entries.firstWhere((e) => e.value == v).key;

api.ProductTrialDays _trialToWire(ProductTrialDays v) => _trials[v]!;
ProductTrialDays _trialFromWire(api.ProductTrialDays v) =>
    _trials.entries.firstWhere((e) => e.value == v).key;
