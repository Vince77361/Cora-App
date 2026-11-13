import 'package:cora_api/api.dart' as api;

import '../../../core/network/api_error.dart';
import '../../offer_terms/data/offer_terms_from_wire.dart';
import '../../offer_terms/domain/offer_terms.dart';
import '../domain/counter_proposal_repository.dart';
import '../domain/creator_series.dart';

/// 생성된 API 클라이언트(`cora_api`)로 내 시리즈를 읽고 만들고, 가게에 제안을 낸다. 생성된 타입은 이 파일 밖으로
/// 내보내지 않는다.
class ApiCounterProposalRepository implements CounterProposalRepository {
  ApiCounterProposalRepository(api.ApiClient client)
    : _creators = api.CreatorsApi(client),
      _offers = api.OffersApi(client);

  final api.CreatorsApi _creators;
  final api.OffersApi _offers;

  @override
  Future<List<CreatorSeries>> fetchSeries() => _guard(() async {
    final rows = await _creators.listMyCreatorSeries();
    if (rows == null) throw const CounterProposalFailure();
    return [for (final m in rows) _seriesFromWire(m)];
  });

  @override
  Future<CreatorSeries> addSeries({
    required String name,
    required ContentFormat format,
    String? note,
  }) => _guard(() async {
    final m = await _creators.createMyCreatorSeries(
      api.CreateCreatorSeriesDto(
        name: name,
        format: formatToWire(format),
        note: note,
      ),
    );
    if (m == null) throw const CounterProposalFailure();
    return _seriesFromWire(m);
  });

  @override
  Future<({String offerId, int version})> sendToStore(
    String storeId,
    CounterProposal proposal,
  ) => _guard(() async {
    final m = await _offers.proposeToStore(
      storeId,
      api.StoreProposalDto(
        format: formatToWire(proposal.terms.format),
        reward: rewardToWire(proposal.terms.reward),
        usageRights: usageRightsToWire(proposal.terms.usageRights),
        idea: _idea(proposal),
        principles: proposal.principles,
        seriesId: proposal.seriesId,
      ),
    );
    if (m == null) throw const CounterProposalFailure();
    return (offerId: m.offerId, version: m.version);
  });

  @override
  Future<void> sendVersion(String offerId, CounterProposal proposal) =>
      _guard(() async {
        final m = await _offers.proposeOfferVersion(
          offerId,
          api.ProposeVersionDto(
            format: formatToWire(proposal.terms.format),
            reward: rewardToWire(proposal.terms.reward),
            usageRights: usageRightsToWire(proposal.terms.usageRights),
            idea: _idea(proposal),
            principles: proposal.principles,
            seriesId: proposal.seriesId,
          ),
        );
        if (m == null) throw const CounterProposalFailure();
      });

  /// 비운 아이디어는 보내지 않는다.
  static String? _idea(CounterProposal proposal) {
    final idea = proposal.idea.trim();
    return idea.isEmpty ? null : idea;
  }

  static CreatorSeries _seriesFromWire(api.CreatorSeriesModel m) =>
      CreatorSeries(
        id: m.id,
        name: m.name,
        format: formatFromWire(m.format),
        note: m.note,
      );

  /// 서버 문구는 4xx일 때만 담는다. 5xx 본문은 화면에 보이지 않는다.
  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on CounterProposalFailure {
      rethrow;
    } catch (error) {
      final e = ApiError.from(error);
      final status = e.status;
      throw CounterProposalFailure(
        message: status != null && status >= 400 && status < 500
            ? e.message
            : null,
      );
    }
  }
}
