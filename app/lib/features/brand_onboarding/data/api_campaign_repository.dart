import 'package:cora_api/api.dart' as api;

import '../../../core/network/api_error.dart';
import '../../offer_terms/data/offer_terms_from_wire.dart'
    show formatFromWire, formatToWire;
import '../../principles/domain/principles.dart' show ProductTrialDays;
import '../domain/campaign.dart';
import '../domain/campaign_repository.dart';

/// 생성된 API 클라이언트(`cora_api`)로 내 캠페인을 주고받는다. 생성된 타입은 이 파일 밖으로
/// 내보내지 않는다.
class ApiCampaignRepository implements CampaignRepository {
  ApiCampaignRepository(api.ApiClient client)
    : _campaigns = api.CampaignsApi(client);

  final api.CampaignsApi _campaigns;

  @override
  Future<Campaign?> fetchMyActive() async {
    try {
      final model = await _campaigns.getMyActiveCampaign();
      // 서버는 진행 중인 캠페인이 없으면 404로 답한다. 본문이 비는 성공은 없으므로 실패로 본다.
      if (model == null) throw const CampaignFailure();
      return _fromModel(model);
    } on CampaignFailure {
      rethrow;
    } catch (error) {
      if (ApiError.from(error).isNotFound) return null;
      throw const CampaignFailure();
    }
  }

  @override
  Future<Campaign> create(CampaignInput input) => _call(() async {
    final model = await _campaigns.createCampaign(
      api.CreateCampaignDto(
        headline: input.headline,
        fee: input.fee,
        budget: input.budget,
        productProvided: input.productProvided,
        format: formatToWire(input.format),
        startFrom: input.startFrom,
        trialDays: _trialToWire(input.trialDays),
        mustInclude: input.mustInclude,
        notRequired: [for (final n in input.notRequired) _notRequiredToWire(n)],
      ),
    );
    if (model == null) throw const CampaignFailure();
    return _fromModel(model);
  });

  @override
  Future<Campaign> update(String id, CampaignInput input) => _call(() async {
    final model = await _campaigns.updateCampaign(
      id,
      api.UpdateCampaignDto(
        headline: input.headline,
        fee: input.fee,
        budget: input.budget,
        productProvided: input.productProvided,
        format: formatToWire(input.format),
        startFrom: input.startFrom,
        trialDays: _trialToWire(input.trialDays),
        mustInclude: input.mustInclude,
        notRequired: [for (final n in input.notRequired) _notRequiredToWire(n)],
      ),
    );
    if (model == null) throw const CampaignFailure();
    return _fromModel(model);
  });

  @override
  Future<void> close(String id) => _call(() async {
    await _campaigns.closeCampaign(id);
  });

  /// 서버가 입력을 거절하면(400) 또는 이미 진행 중인 캠페인이 있으면(409) 서버의 사용자 문구를
  /// 담아 던진다. 그 밖의 실패는 문구 없이 던진다.
  Future<T> _call<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on CampaignFailure {
      rethrow;
    } catch (error) {
      final e = ApiError.from(error);
      final showable = e.status == 400 || e.status == 409;
      throw CampaignFailure(message: showable ? e.message : null);
    }
  }

  static Campaign _fromModel(api.CampaignModel m) => Campaign(
    id: m.id,
    headline: m.headline,
    fee: m.fee,
    budget: m.budget,
    productProvided: m.productProvided,
    format: formatFromWire(m.format),
    // 날짜만 오는 값이라 지역 시각의 자정으로 읽힌다. 시·분은 버리고 날짜만 둔다.
    startFrom: DateTime(m.startFrom.year, m.startFrom.month, m.startFrom.day),
    trialDays: _trialFromWire(m.trialDays),
    mustInclude: List.unmodifiable(m.mustInclude),
    notRequired: [for (final n in m.notRequired) _notRequiredFromWire(n)],
    status: m.status == api.CampaignStatus.ACTIVE
        ? CampaignStatus.active
        : CampaignStatus.closed,
  );
}

api.ProductTrialDays _trialToWire(ProductTrialDays v) => switch (v) {
  ProductTrialDays.d3 => api.ProductTrialDays.D3,
  ProductTrialDays.d7 => api.ProductTrialDays.D7,
  ProductTrialDays.d14 => api.ProductTrialDays.D14,
  ProductTrialDays.any => api.ProductTrialDays.ANY,
};

ProductTrialDays _trialFromWire(api.ProductTrialDays v) => switch (v) {
  api.ProductTrialDays.D3 => ProductTrialDays.d3,
  api.ProductTrialDays.D7 => ProductTrialDays.d7,
  api.ProductTrialDays.D14 => ProductTrialDays.d14,
  _ => ProductTrialDays.any,
};

api.NotRequired _notRequiredToWire(NotRequired v) => switch (v) {
  NotRequired.face => api.NotRequired.FACE,
  NotRequired.fixedLines => api.NotRequired.FIXED_LINES,
  NotRequired.scriptReading => api.NotRequired.SCRIPT_READING,
};

NotRequired _notRequiredFromWire(api.NotRequired v) => switch (v) {
  api.NotRequired.FACE => NotRequired.face,
  api.NotRequired.FIXED_LINES => NotRequired.fixedLines,
  _ => NotRequired.scriptReading,
};
