import 'package:cora_api/api.dart' as api;

import '../../../core/network/api_error.dart';
import '../../offer_terms/data/offer_terms_from_wire.dart';
import '../../view_report/domain/view_report.dart';
import '../domain/collaboration.dart';
import '../domain/collaboration_repository.dart';

/// 생성된 API 클라이언트(`cora_api`)로 협업을 읽고 제출·취소한다. 생성된 타입은 이 파일 밖으로
/// 내보내지 않는다.
class ApiCollaborationRepository implements CollaborationRepository {
  ApiCollaborationRepository(api.ApiClient client)
    : _collaborations = api.CollaborationsApi(client),
      _submissions = api.SubmissionsApi(client);

  final api.CollaborationsApi _collaborations;
  final api.SubmissionsApi _submissions;

  @override
  Future<List<Collaboration>> fetchActive() =>
      _list(api.CollaborationScope.active);

  @override
  Future<List<Collaboration>> fetchDone() => _list(api.CollaborationScope.done);

  Future<List<Collaboration>> _list(api.CollaborationScope scope) =>
      _guard(() async {
        final rows = await _collaborations.listCollaborations(scope);
        if (rows == null) throw const CollaborationFailure();
        return [for (final m in rows) _fromModel(m)];
      });

  @override
  Future<Collaboration> fetch(String id) => _guard(() async {
    final m = await _collaborations.getCollaboration(id);
    if (m == null) throw const CollaborationFailure();
    return _fromModel(m);
  });

  @override
  Future<Collaboration> submitLink(String id, String url) => _guard(() async {
    final m = await _submissions.submitContentLink(
      id,
      api.SubmitContentDto(url: url),
    );
    if (m == null) throw const CollaborationFailure();
    return _fromModel(m);
  });

  @override
  Future<void> cancel(String id) => _guard(() async {
    await _collaborations.cancelCollaboration(id);
  });

  @override
  Future<void> requestCancel(String id) => _guard(() async {
    await _collaborations.requestCollaborationCancel(id);
  });

  @override
  Future<void> acceptCancel(String id, String requestId) => _guard(() async {
    await _collaborations.acceptCollaborationCancel(id, requestId);
  });

  /// 어떤 실패든 [CollaborationFailure] 하나로 모은다. 서버 문구는 4xx일 때만 담는다: 5xx 본문에는
  /// 내부 사정이 섞일 수 있어 화면에 보이지 않는다.
  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on CollaborationFailure {
      rethrow;
    } catch (error) {
      final e = ApiError.from(error);
      final status = e.status;
      throw CollaborationFailure(
        conflict: e.isConflict,
        message: status != null && status >= 400 && status < 500
            ? e.message
            : null,
      );
    }
  }

  static Collaboration _fromModel(api.CollaborationModel m) => Collaboration(
    id: m.id,
    role: m.role == api.CollaborationRole.COMMISSIONER
        ? CollaborationRole.commissioner
        : CollaborationRole.creator,
    stage: switch (m.stage) {
      api.CollaborationStage.AWAITING_PAYMENT =>
        CollaborationStage.awaitingPayment,
      api.CollaborationStage.FUNDED => CollaborationStage.funded,
      api.CollaborationStage.COUNTING => CollaborationStage.counting,
      api.CollaborationStage.SETTLED => CollaborationStage.settled,
      api.CollaborationStage.REFUNDED => CollaborationStage.refunded,
      api.CollaborationStage.CANCELLED => CollaborationStage.cancelled,
      api.CollaborationStage.HALTED => CollaborationStage.halted,
      _ => CollaborationStage.other,
    },
    counterpartName: m.counterpart.name,
    counterpartPhotoUrl: m.counterpart.photoUrl,
    terms: offerTermsFromWire(m.terms),
    escrowAmount: m.escrowAmount,
    steps: [
      for (final s in m.steps)
        CollaborationStep(
          key: switch (s.key) {
            api.CollaborationStepKey.ACCEPTED => StepKey.accepted,
            api.CollaborationStepKey.PAID => StepKey.paid,
            api.CollaborationStepKey.VISIT => StepKey.visit,
            api.CollaborationStepKey.SUBMIT => StepKey.submit,
            _ => StepKey.settle,
          },
          state: switch (s.state) {
            api.CollaborationStepState.DONE => StepState.done,
            api.CollaborationStepState.NOW => StepState.now,
            _ => StepState.todo,
          },
          at: s.at,
        ),
    ],
    earnedSoFar: m.earnedSoFar,
    currentViews: m.currentViews,
    countingEndsAt: m.countingEndsAt,
    submitDueAt: m.submitDueAt,
    submittedUrl: m.submittedUrl,
    canCancel: m.canCancel,
    canRequestCancel: m.canRequestCancel,
    cancelRequest: m.cancelRequest == null
        ? null
        : CancelRequest(
            id: m.cancelRequest!.id,
            expiresAt: m.cancelRequest!.expiresAt,
            requestedByMe: m.cancelRequest!.requestedByMe,
          ),
    payoutStatus: switch (m.payoutStatus) {
      api.PayoutStatus.NEEDS_ACCOUNT => PayoutStatus.needsAccount,
      api.PayoutStatus.PENDING => PayoutStatus.pending,
      api.PayoutStatus.DONE => PayoutStatus.done,
      api.PayoutStatus.FAILED => PayoutStatus.failed,
      _ => PayoutStatus.none,
    },
    payoutScheduledFor: m.payoutScheduledFor,
    settlement: m.settlement == null
        ? null
        : CollaborationSettlement(
            finalViews: m.settlement!.finalViews,
            payoutAmount: m.settlement!.payoutAmount,
            refundAmount: m.settlement!.refundAmount,
          ),
    expectedRefund: m.expectedRefund,
    viewReportStatus: switch (m.viewReportStatus) {
      api.CollaborationViewReportStatus.COUNTING => ViewReportStatus.counting,
      api.CollaborationViewReportStatus.UNCONFIRMED =>
        ViewReportStatus.unconfirmed,
      api.CollaborationViewReportStatus.CONFIRMED => ViewReportStatus.confirmed,
      api.CollaborationViewReportStatus.DISPUTED => ViewReportStatus.disputed,
      _ => null,
    },
  );
}
