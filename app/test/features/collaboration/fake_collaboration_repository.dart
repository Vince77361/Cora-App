import 'package:cora/features/collaboration/domain/collaboration.dart';
import 'package:cora/features/collaboration/domain/collaboration_repository.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart';

/// 캔버스 A7의 단계 다섯 개. 기본은 오퍼 수락과 가게 결제가 끝나고 방문·촬영이 지금 단계다.
List<CollaborationStep> stepsAt(StepKey now, {DateTime? acceptedAt}) {
  final order = StepKey.values;
  return [
    for (final key in order)
      CollaborationStep(
        key: key,
        state: key.index < now.index
            ? StepState.done
            : key == now
            ? StepState.now
            : StepState.todo,
        at: key == StepKey.accepted ? acceptedAt : null,
      ),
  ];
}

const _bothTerms = OfferTerms(
  format: ContentFormat.reels,
  rewardType: RewardType.both,
  voucherName: '2인 식사권',
  voucherValue: 40000,
  perViewAmount: 10,
  perViewCap: 100000,
);

/// 캔버스 A7의 견본 협업: 한그릇 라멘, 보관 100,000원 + 2인 식사권, 방문·촬영 단계, 11월 23일까지 제출.
Collaboration collaboration({
  String id = 'c0ffee11-aaaa-bbbb-cccc-000000000001',
  String storeName = '한그릇 라멘',
  CollaborationStage stage = CollaborationStage.funded,
  OfferTerms terms = _bothTerms,
  int escrowAmount = 100000,
  StepKey? now,
  List<CollaborationStep>? steps,
  int? earnedSoFar,
  int? currentViews,
  DateTime? countingEndsAt,
  DateTime? submitDueAt,
  String? submittedUrl,
  bool canCancel = false,
  CancelRequest? cancelRequest,
  PayoutStatus payoutStatus = PayoutStatus.none,
  DateTime? payoutScheduledFor,
  CollaborationSettlement? settlement,
}) => Collaboration(
  id: id,
  role: CollaborationRole.creator,
  stage: stage,
  counterpartName: storeName,
  terms: terms,
  escrowAmount: escrowAmount,
  steps:
      steps ??
      stepsAt(now ?? StepKey.visit, acceptedAt: DateTime.utc(2026, 11, 10, 3)),
  earnedSoFar: earnedSoFar,
  currentViews: currentViews,
  countingEndsAt: countingEndsAt,
  submitDueAt: submitDueAt ?? DateTime.utc(2026, 11, 23, 3),
  submittedUrl: submittedUrl,
  canCancel: canCancel,
  cancelRequest: cancelRequest,
  payoutStatus: payoutStatus,
  payoutScheduledFor: payoutScheduledFor,
  settlement: settlement,
);

/// 손으로 쓴 가짜 협업 저장소. 제출·취소·동의를 받으면 목록과 상세를 서버처럼 바꾼다.
class FakeCollaborationRepository implements CollaborationRepository {
  FakeCollaborationRepository({
    List<Collaboration>? active,
    List<Collaboration>? done,
  }) : active = active ?? [],
       done = done ?? [];

  List<Collaboration> active;
  List<Collaboration> done;

  bool failFetch = false;

  /// 설정하면 제출·취소·동의가 이 오류로 실패한다.
  CollaborationFailure? failAction;

  /// 제출이 성공하면 돌려줄 협업(없으면 집계 중 협업을 만든다).
  Collaboration? afterSubmit;

  int fetchActiveCalls = 0;
  final submitted = <({String id, String url})>[];
  final cancelled = <String>[];
  final cancelRequested = <String>[];
  final acceptedCancels = <({String id, String requestId})>[];

  Collaboration _find(String id) =>
      [...active, ...done].firstWhere((c) => c.id == id);

  @override
  Future<List<Collaboration>> fetchActive() async {
    fetchActiveCalls++;
    if (failFetch) throw const CollaborationFailure();
    return List.of(active);
  }

  @override
  Future<List<Collaboration>> fetchDone() async {
    if (failFetch) throw const CollaborationFailure();
    return List.of(done);
  }

  @override
  Future<Collaboration> fetch(String id) async {
    if (failFetch) throw const CollaborationFailure();
    return _find(id);
  }

  @override
  Future<Collaboration> submitLink(String id, String url) async {
    final error = failAction;
    if (error != null) throw error;
    submitted.add((id: id, url: url));
    final next =
        afterSubmit ??
        collaboration(
          id: id,
          stage: CollaborationStage.counting,
          now: StepKey.settle,
          submittedUrl: url,
          earnedSoFar: 0,
          currentViews: 0,
          countingEndsAt: DateTime.utc(2026, 11, 18, 12),
        );
    active = [for (final c in active) c.id == id ? next : c];
    return next;
  }

  @override
  Future<void> cancel(String id) async {
    final error = failAction;
    if (error != null) throw error;
    cancelled.add(id);
    active = active.where((c) => c.id != id).toList();
  }

  @override
  Future<void> requestCancel(String id) async {
    final error = failAction;
    if (error != null) throw error;
    cancelRequested.add(id);
  }

  @override
  Future<void> acceptCancel(String id, String requestId) async {
    final error = failAction;
    if (error != null) throw error;
    acceptedCancels.add((id: id, requestId: requestId));
    active = active.where((c) => c.id != id).toList();
  }
}
