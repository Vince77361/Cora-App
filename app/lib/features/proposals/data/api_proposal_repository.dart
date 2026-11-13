import 'package:cora_api/api.dart' as api;

import '../../../core/network/api_error.dart';
import '../../offer_terms/data/offer_terms_from_wire.dart';
import '../../offer_terms/domain/offer_terms.dart';
import '../../offers/domain/offer_view.dart';
import '../domain/offer_version.dart';
import '../domain/proposal.dart';
import '../domain/proposal_repository.dart';

/// 생성된 API 클라이언트(`cora_api`)로 제안함을 읽고 제안에 답한다. 생성된 타입은 이 파일 밖으로
/// 내보내지 않는다.
class ApiProposalRepository implements ProposalRepository {
  ApiProposalRepository(api.ApiClient client)
    : _proposals = api.ProposalsApi(client),
      _offers = api.OffersApi(client);

  final api.ProposalsApi _proposals;
  final api.OffersApi _offers;

  @override
  Future<List<ProposalRow>> fetch(ProposalTab tab) => _guard(() async {
    final rows = await _proposals.listProposals(switch (tab) {
      ProposalTab.active => api.ProposalTab.active,
      ProposalTab.ended => api.ProposalTab.ended,
    });
    if (rows == null) throw const ProposalFailure();
    return [for (final m in rows) _row(m)];
  });

  @override
  Future<ProposalDetail> fetchDetail(String offerId) => _guard(() async {
    final m = await _proposals.getProposal(offerId);
    if (m == null) throw const ProposalFailure();
    return _detail(m);
  });

  @override
  Future<String?> accept(String offerId, int version) => _guard(() async {
    final m = await _offers.acceptOffer(
      offerId,
      api.AcceptOfferDto(version: version),
    );
    return m?.collaborationId;
  });

  @override
  Future<void> end(String offerId, EndReason reason) => _guard(() async {
    await _offers.endOffer(
      offerId,
      api.EndOfferDto(reason: _reasonToWire(reason)),
    );
  });

  @override
  Future<void> cancel(String offerId) => _guard(() async {
    await _offers.cancelOffer(offerId);
  });

  @override
  Future<void> reply(String offerId, OfferTerms terms) => _guard(() async {
    await _offers.proposeOfferVersion(
      offerId,
      api.ProposeVersionDto(
        format: formatToWire(terms.format),
        reward: rewardToWire(terms.reward),
        usageRights: usageRightsToWire(terms.usageRights),
      ),
    );
  });

  /// 4xx의 서버 문구는 화면에 그대로 보인다. 5xx 본문과 연결 문제는 문구 없이 일반 실패다.
  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on ProposalFailure {
      rethrow;
    } catch (error) {
      final e = ApiError.from(error);
      final status = e.status;
      final latest = e.isStaleVersion ? e.latestVersion : null;
      throw ProposalFailure(
        conflict: e.isConflict || (e.isStaleVersion && latest == null),
        staleVersion: latest,
        notFound: e.isNotFound,
        message: status != null && status >= 400 && status < 500
            ? e.message
            : null,
      );
    }
  }

  static ProposalRow _row(api.ProposalRowModel m) => ProposalRow(
    offerId: m.offerId,
    name: m.counterpart.name,
    photoUrl: m.counterpart.photoUrl,
    group: _group(m.group),
    format: formatFromWire(m.format),
    pieces: m.pieces,
    version: m.version,
    counter: m.counter,
    daysLeft: m.daysLeft,
    endKind: _endKind(m.endKind),
    endReason: _reasonFromWire(m.endReason),
    collaborationId: m.collaborationId,
  );

  static ProposalDetail _detail(api.ProposalDetailModel m) => ProposalDetail(
    offerId: m.offerId,
    myParty: _party(m.myParty),
    group: _group(m.group),
    status: switch (m.status) {
      api.OfferView.ACCEPTED => OfferView.accepted,
      api.OfferView.DECLINED => OfferView.declined,
      api.OfferView.EXPIRED => OfferView.expired,
      api.OfferView.CANCELLED => OfferView.cancelled,
      _ => OfferView.waiting,
    },
    counterpart: ProposalPerson(
      name: m.counterpart.name,
      photoUrl: m.counterpart.photoUrl,
    ),
    storeId: m.store.id,
    storeName: m.store.name,
    recruitLine: m.store.recruitLine,
    latest: _version(m.latest),
    previous: m.previous == null ? null : _version(m.previous!),
    changed: {for (final name in m.changed) ?_field(name)},
    expiresAt: m.expiresAt,
    feeRate: m.feeRate,
    needsInstagram: m.needsInstagram,
    endKind: _endKind(m.endKind),
    endReason: _reasonFromWire(m.endReason),
    collaborationId: m.collaborationId,
  );

  static OfferVersion _version(api.OfferVersionModel m) => OfferVersion(
    number: m.number,
    authorParty: _party(m.authorParty),
    terms: offerTermsFromWire(m.terms),
    idea: m.idea,
    principles: m.principles,
    series: m.series == null
        ? null
        : OfferVersionSeries(
            name: m.series!.name,
            format: m.series!.format == null
                ? null
                : formatFromWire(m.series!.format!),
            note: m.series!.note,
          ),
  );

  static ProposalParty _party(api.OfferParty p) => switch (p) {
    api.OfferParty.STORE => ProposalParty.store,
    _ => ProposalParty.creator,
  };

  static ProposalGroup _group(api.ProposalGroup g) => switch (g) {
    api.ProposalGroup.MY_TURN => ProposalGroup.myTurn,
    api.ProposalGroup.WAITING => ProposalGroup.waiting,
    _ => ProposalGroup.ended,
  };

  static ProposalEndKind? _endKind(api.ProposalEndKind? k) => switch (k) {
    api.ProposalEndKind.AGREED => ProposalEndKind.agreed,
    api.ProposalEndKind.ENDED => ProposalEndKind.ended,
    api.ProposalEndKind.EXPIRED => ProposalEndKind.expired,
    _ => null,
  };

  static EndReason? _reasonFromWire(api.OfferEndReason? r) => switch (r) {
    api.OfferEndReason.SCHEDULE => EndReason.schedule,
    api.OfferEndReason.TERMS => EndReason.terms,
    api.OfferEndReason.OTHER_PARTNER => EndReason.otherPartner,
    api.OfferEndReason.NO_REASON => EndReason.noReason,
    _ => null,
  };

  static api.OfferEndReason _reasonToWire(EndReason r) => switch (r) {
    EndReason.schedule => api.OfferEndReason.SCHEDULE,
    EndReason.terms => api.OfferEndReason.TERMS,
    EndReason.otherPartner => api.OfferEndReason.OTHER_PARTNER,
    EndReason.noReason => api.OfferEndReason.NO_REASON,
  };

  static ProposalField? _field(String name) => switch (name) {
    'FORMAT' => ProposalField.format,
    'VOUCHER' => ProposalField.voucher,
    'FIXED_CASH' => ProposalField.fixedCash,
    'VIEW_PAY' => ProposalField.viewPay,
    'USAGE_RIGHTS' => ProposalField.usageRights,
    'IDEA' => ProposalField.idea,
    'PRINCIPLES' => ProposalField.principles,
    'SERIES' => ProposalField.series,
    _ => null,
  };
}
