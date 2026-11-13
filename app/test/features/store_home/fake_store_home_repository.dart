import 'dart:async';

import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/offers/domain/offer_view.dart';
import 'package:cora/features/store_home/domain/applicant.dart';
import 'package:cora/features/store_home/domain/sent_offer.dart';
import 'package:cora/features/store_home/domain/store_home_repository.dart';
import 'package:cora/features/store_home/domain/store_home_summary.dart';

/// 캔버스 A9의 견본 지원자 세 명(하루 한 컵은 사진, 나머지는 초성).
List<Applicant> sampleApplicants({DateTime? now}) {
  final base = now ?? DateTime.utc(2026, 11, 11, 12);
  return [
    Applicant(
      applicationId: 'a1',
      creator: const CreatorSummary(
        userId: 'c1',
        displayName: '하루 한 컵',
        contentFocus: '리빙 릴스',
      ),
      appliedAt: base,
    ),
    Applicant(
      applicationId: 'a2',
      creator: const CreatorSummary(
        userId: 'c2',
        displayName: '성수 한 끼',
        contentFocus: '맛집 릴스',
      ),
      appliedAt: base.subtract(const Duration(days: 1)),
    ),
    Applicant(
      applicationId: 'a3',
      creator: const CreatorSummary(
        userId: 'c3',
        displayName: '면치기 일기',
        contentFocus: '라멘 리뷰',
      ),
      appliedAt: base.subtract(const Duration(days: 2)),
    ),
  ];
}

SentOffer sentOffer({
  String id = 'o1',
  String creatorId = 'c9',
  String name = '민의 옷장 기록',
  OfferView view = OfferView.waiting,
  int? paymentDaysLeft,
  String? collaborationId,
  OfferTerms? terms,
}) => SentOffer(
  id: id,
  collaborationId: collaborationId,
  creator: CreatorSummary(userId: creatorId, displayName: name),
  terms:
      terms ??
      const OfferTerms(
        format: ContentFormat.reels,
        reward: Reward(
          voucher: Voucher(name: '2인 식사권', value: 40000),
          viewPay: ViewPay(ratePerThousand: 2000, cap: 100000),
        ),
      ),
  view: view,
  paymentDaysLeft: paymentDaysLeft,
);

/// 손으로 쓴 가짜 사장님 홈 저장소. 서버가 가진 지원자와 보낸 오퍼를 흉내 낸다. 숫자는 목록에서
/// 계산한다.
class FakeStoreHomeRepository implements StoreHomeRepository {
  FakeStoreHomeRepository({List<Applicant>? applicants, List<SentOffer>? sent})
    : applicants = applicants ?? [],
      sentOffers = sent ?? [];

  List<Applicant> applicants;
  List<SentOffer> sentOffers;

  bool failFetch = false;
  bool failSend = false;
  bool conflictOnSend = false;
  bool failCancel = false;
  bool conflictOnCancel = false;

  /// 설정하면 [sendOffer]가 이 Completer가 끝날 때까지 기다린다.
  Completer<void>? holdSend;

  /// 설정하면 [fetchSummary]가 이 Completer가 끝날 때까지 기다린다(불러오는 중 화면을 본다).
  Completer<void>? holdFetch;

  int fetchCalls = 0;
  final sent = <({String creatorId, OfferTerms terms})>[];
  final cancelled = <String>[];

  @override
  Future<StoreHomeSummary> fetchSummary() async {
    fetchCalls++;
    await holdFetch?.future;
    if (failFetch) throw const StoreHomeFailure();
    return StoreHomeSummary(
      newApplications: applicants.length,
      sentOffers: sentOffers.length,
      inProgress: sentOffers.where((o) => o.view == OfferView.accepted).length,
    );
  }

  @override
  Future<List<Applicant>> fetchApplicants() async {
    if (failFetch) throw const StoreHomeFailure();
    return List.of(applicants);
  }

  @override
  Future<List<SentOffer>> fetchSentOffers() async {
    if (failFetch) throw const StoreHomeFailure();
    return List.of(sentOffers);
  }

  @override
  Future<void> sendOffer(String creatorId, OfferTerms terms) async {
    await holdSend?.future;
    if (conflictOnSend) throw const StoreHomeFailure(conflict: true);
    if (failSend) throw const StoreHomeFailure();
    sent.add((creatorId: creatorId, terms: terms));
    final applicant = applicants.firstWhere(
      (a) => a.creator.userId == creatorId,
    );
    applicants = applicants.where((a) => a != applicant).toList();
    sentOffers = [
      sentOffer(
        id: 'sent-${sent.length}',
        creatorId: creatorId,
        name: applicant.creator.displayName,
      ),
      ...sentOffers,
    ];
  }

  @override
  Future<void> cancelOffer(String offerId) async {
    if (conflictOnCancel) throw const StoreHomeFailure(conflict: true);
    if (failCancel) throw const StoreHomeFailure();
    cancelled.add(offerId);
    sentOffers = [
      for (final o in sentOffers)
        if (o.id == offerId)
          SentOffer(
            id: o.id,
            creator: o.creator,
            terms: o.terms,
            view: OfferView.cancelled,
          )
        else
          o,
    ];
  }
}
