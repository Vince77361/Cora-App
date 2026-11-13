import 'package:cora_api/api.dart' as api;

import '../../offer_terms/data/offer_terms_from_wire.dart';
import '../domain/server_config.dart';
import '../domain/server_config_repository.dart';

/// 생성된 API 클라이언트(`cora_api`)로 서버 설정을 읽는다. 생성된 타입은 여기서 도메인 타입으로 바꾼다.
class ApiServerConfigRepository implements ServerConfigRepository {
  ApiServerConfigRepository(api.ApiClient client)
    : _config = api.AppConfigApi(client);

  final api.AppConfigApi _config;

  @override
  Future<ServerConfig> fetch() async {
    try {
      final model = await _config.getAppConfig();
      if (model == null) throw const ServerConfigFailure();
      return serverConfigFromWire(model);
    } on ServerConfigFailure {
      rethrow;
    } catch (_) {
      throw const ServerConfigFailure();
    }
  }
}

ServerConfig serverConfigFromWire(api.AppConfigModel m) {
  // 눈금이 0 이하이면 고를 수 있는 값을 세는 반복이 끝나지 않는다. 그런 설정은 믿지 않는다.
  int positiveStep(int step) =>
      step > 0 ? step : throw const ServerConfigFailure();
  StepRange range(api.RewardRangeModel r) => StepRange(
    min: r.min,
    max: r.max,
    step: positiveStep(r.step),
    defaultValue: r.default_,
  );
  final r = m.reward;
  return ServerConfig(
    reward: RewardLimits(
      viewRate: range(r.viewRate),
      perViewCap: range(r.perViewCap),
      fixedCash: FixedCashLimits(
        storeMax: r.fixedCash.maxByCommissioner.store,
        brandMax: r.fixedCash.maxByCommissioner.brand,
        step: positiveStep(r.fixedCash.step),
        presets: r.fixedCash.presets,
      ),
      voucher: VoucherDefaults(
        name: r.voucher.defaultName,
        value: r.voucher.defaultValue,
        people: r.voucher.defaultPeople,
        maxPeople: r.voucher.maxPeople,
        minValue: r.voucher.minValue,
        maxValue: r.voucher.maxValue,
      ),
      usageRightsDefault: usageRightsFromWire(r.usageRightsDefault),
      countingDays: r.countingDays,
    ),
    feeRates: FeeRates(
      storeOffer: m.feeRates.storeOffer,
      brandContract: m.feeRates.brandContract,
      bid: m.feeRates.bid,
    ),
  );
}
