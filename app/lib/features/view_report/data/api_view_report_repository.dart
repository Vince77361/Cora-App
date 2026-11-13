import 'package:cora_api/api.dart' as api;

import '../../../core/network/api_error.dart';
import '../domain/view_report.dart';
import '../domain/view_report_repository.dart';

/// 생성된 API 클라이언트(`cora_api`)로 조회 자료를 읽고 확인·이의 제기·캡처 제출을 한다. 생성된 타입은
/// 이 파일 밖으로 내보내지 않는다.
class ApiViewReportRepository implements ViewReportRepository {
  ApiViewReportRepository(api.ApiClient client)
    : _api = api.ViewReportApi(client);

  final api.ViewReportApi _api;

  @override
  Future<ViewReport> fetch(String collaborationId) =>
      _guard(() => _api.getViewReport(collaborationId));

  @override
  Future<ViewReport> confirm(String collaborationId) =>
      _guard(() => _api.confirmViewReport(collaborationId));

  @override
  Future<ViewReport> dispute(String collaborationId, String reason) => _guard(
    () => _api.disputeViewReport(
      collaborationId,
      api.DisputeViewReportDto(reason: reason),
    ),
  );

  @override
  Future<ViewReport> submitEvidence(
    String collaborationId,
    String path,
    int views,
  ) => _guard(
    () => _api.submitViewEvidence(
      collaborationId,
      api.SubmitViewEvidenceDto(path: path, views: views),
    ),
  );

  /// 어떤 실패든 [ViewReportFailure] 하나로 모은다. 서버 문구는 4xx일 때만 담는다: 5xx 본문에는
  /// 내부 사정이 섞일 수 있어 화면에 보이지 않는다.
  static Future<ViewReport> _guard(
    Future<api.ViewReportModel?> Function() call,
  ) async {
    try {
      final m = await call();
      if (m == null) throw const ViewReportFailure();
      return _fromModel(m);
    } on ViewReportFailure {
      rethrow;
    } catch (error) {
      final e = ApiError.from(error);
      final status = e.status;
      throw ViewReportFailure(
        notFound: e.isNotFound,
        conflict: e.isConflict,
        message: status != null && status >= 400 && status < 500
            ? e.message
            : null,
      );
    }
  }

  static ViewReport _fromModel(api.ViewReportModel m) => ViewReport(
    status: switch (m.status) {
      api.ViewReportStatus.COUNTING => ViewReportStatus.counting,
      api.ViewReportStatus.UNCONFIRMED => ViewReportStatus.unconfirmed,
      api.ViewReportStatus.CONFIRMED => ViewReportStatus.confirmed,
      _ => ViewReportStatus.disputed,
    },
    views: m.views,
    postUrl: m.postUrl,
    periodStart: m.periodStart,
    periodEnd: m.periodEnd,
    source: switch (m.source_) {
      api.ViewReportSource.CAPTURE_PENDING => ViewReportSource.capturePending,
      api.ViewReportSource.CAPTURE_CONFIRMED =>
        ViewReportSource.captureConfirmed,
      _ => ViewReportSource.connectedAccount,
    },
    calc: m.calc == null
        ? null
        : ViewReportCalc(
            ratePerThousand: m.calc!.ratePerThousand,
            cap: m.calc!.cap,
            capApplied: m.calc!.capApplied,
            fixedCash: m.calc!.fixedCash,
            viewPay: m.calc!.viewPay,
            refund: m.calc!.refund,
            payout: m.calc!.payout,
          ),
    confirmDueAt: m.confirmDueAt,
    evidence: m.evidence == null
        ? null
        : ViewReportEvidence(
            imageUrl: m.evidence!.imageUrl,
            statedViews: m.evidence!.statedViews,
          ),
    canConfirm: m.canConfirm,
    canDispute: m.canDispute,
    canUploadEvidence: m.canUploadEvidence,
  );
}
