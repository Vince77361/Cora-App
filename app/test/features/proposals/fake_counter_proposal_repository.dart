import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/proposals/domain/counter_proposal_repository.dart';
import 'package:cora/features/proposals/domain/creator_series.dart';

/// 보낸 제안 한 건: 가게 페이지에서 새로 냈으면 [storeId], 열린 오퍼의 다음 판본이면 [offerId]가 있다.
class SentProposal {
  const SentProposal({this.storeId, this.offerId, required this.proposal});

  final String? storeId;
  final String? offerId;
  final CounterProposal proposal;
}

/// 손으로 쓴 가짜 역제안 저장소. 내 시리즈와 보낸 제안을 모은다.
class FakeCounterProposalRepository implements CounterProposalRepository {
  FakeCounterProposalRepository({List<CreatorSeries>? series})
    : series = series ?? [];

  List<CreatorSeries> series;

  bool failFetchSeries = false;

  /// 설정하면 시리즈 만들기가 이 실패로 끝난다(서버 문구가 있으면 시트가 그대로 보인다).
  CounterProposalFailure? failAddSeries;

  /// 설정하면 보내기가 이 실패로 끝난다.
  CounterProposalFailure? failSend;

  final sent = <SentProposal>[];

  /// 보낸 직후 부른다(서버가 열린 제안을 만든 것을 가짜 가게 저장소에 반영하려고).
  void Function()? afterSend;

  @override
  Future<List<CreatorSeries>> fetchSeries() async {
    if (failFetchSeries) throw const CounterProposalFailure();
    return List.of(series);
  }

  @override
  Future<CreatorSeries> addSeries({
    required String name,
    required ContentFormat format,
    String? note,
  }) async {
    final failure = failAddSeries;
    if (failure != null) throw failure;
    final created = CreatorSeries(
      id: 'series-${series.length + 1}',
      name: name,
      format: format,
      note: note,
    );
    series = [...series, created];
    return created;
  }

  @override
  Future<({String offerId, int version})> sendToStore(
    String storeId,
    CounterProposal proposal,
  ) async {
    final failure = failSend;
    if (failure != null) throw failure;
    sent.add(SentProposal(storeId: storeId, proposal: proposal));
    afterSend?.call();
    return (offerId: 'offer-new', version: 2);
  }

  @override
  Future<void> sendVersion(String offerId, CounterProposal proposal) async {
    final failure = failSend;
    if (failure != null) throw failure;
    sent.add(SentProposal(offerId: offerId, proposal: proposal));
    afterSend?.call();
  }
}

const sampleSeries = [
  CreatorSeries(
    id: 's1',
    name: '한 그릇 일기',
    format: ContentFormat.reels,
    note: '30초 릴스 · 손 중심',
  ),
  CreatorSeries(
    id: 's2',
    name: '동네 점심 지도',
    format: ContentFormat.cardNews,
    note: '카드뉴스 5장',
  ),
  CreatorSeries(
    id: 's3',
    name: '소리로 먹는 집',
    format: ContentFormat.reels,
    note: 'ASMR 릴스',
  ),
];
