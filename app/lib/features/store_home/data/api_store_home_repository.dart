import 'package:cora_api/api.dart' as api;

import '../../../core/network/api_error.dart';
import '../../offer_terms/data/offer_terms_from_wire.dart';
import '../../offer_terms/domain/offer_terms.dart';
import '../../offers/domain/offer_view.dart';
import '../domain/applicant.dart';
import '../domain/sent_offer.dart';
import '../domain/store_home_repository.dart';
import '../domain/store_home_summary.dart';

/// 생성된 API 클라이언트(`cora_api`)로 사장님 홈의 데이터를 읽고 오퍼를 보내고 취소한다.
/// 생성된 타입은 이 파일 밖으로 내보내지 않는다.
class ApiStoreHomeRepository implements StoreHomeRepository {
  ApiStoreHomeRepository(api.ApiClient client)
    : _offers = api.OffersApi(client),
      _applications = api.ApplicationsApi(client);

  final api.OffersApi _offers;
  final api.ApplicationsApi _applications;

  @override
  Future<StoreHomeSummary> fetchSummary() => _guard(() async {
    final m = await _offers.getMyStoreSummary();
    if (m == null) throw const StoreHomeFailure();
    return StoreHomeSummary(
      newApplications: m.newApplications,
      sentOffers: m.sentOffers,
      inProgress: m.inProgress,
    );
  });

  @override
  Future<List<Applicant>> fetchApplicants() => _guard(() async {
    final rows = await _applications.listMyStoreApplicants();
    if (rows == null) throw const StoreHomeFailure();
    return [
      for (final m in rows)
        Applicant(
          applicationId: m.applicationId,
          creator: _creator(m.creator),
          appliedAt: m.appliedAt,
        ),
    ];
  });

  @override
  Future<List<SentOffer>> fetchSentOffers() => _guard(() async {
    final rows = await _offers.listSentOffers();
    if (rows == null) throw const StoreHomeFailure();
    return [for (final m in rows) _sentOffer(m)];
  });

  @override
  Future<void> sendOffer(String creatorId, OfferTerms terms) =>
      _guard(() async {
        await _offers.sendOffer(
          api.SendOfferDto(
            creatorId: creatorId,
            format: formatToWire(terms.format),
            reward: rewardToWire(terms.reward),
            usageRights: usageRightsToWire(terms.usageRights),
          ),
        );
      });

  @override
  Future<void> cancelOffer(String offerId) => _guard(() async {
    await _offers.cancelOffer(offerId);
  });

  /// 어떤 실패든 [StoreHomeFailure] 하나로 모은다. 서버 오류 본문과 예외 메시지는 버린다.
  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on StoreHomeFailure {
      rethrow;
    } catch (error) {
      throw StoreHomeFailure(conflict: ApiError.from(error).isConflict);
    }
  }

  static CreatorSummary _creator(api.CreatorSummaryModel m) => CreatorSummary(
    userId: m.userId,
    displayName: m.displayName,
    contentFocus: m.contentFocus,
    photoUrl: m.photoUrl,
  );

  static SentOffer _sentOffer(api.SentOfferModel m) => SentOffer(
    id: m.id,
    creator: _creator(m.creator),
    terms: offerTermsFromWire(m.terms),
    view: switch (m.view) {
      api.OfferView.ACCEPTED => OfferView.accepted,
      api.OfferView.DECLINED => OfferView.declined,
      api.OfferView.EXPIRED => OfferView.expired,
      api.OfferView.CANCELLED => OfferView.cancelled,
      _ => OfferView.waiting,
    },
    paymentDaysLeft: m.paymentDaysLeft,
    collaborationId: m.collaborationId,
  );
}
