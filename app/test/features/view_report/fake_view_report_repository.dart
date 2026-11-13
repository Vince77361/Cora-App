import 'package:cora/features/view_report/domain/view_report.dart';
import 'package:cora/features/view_report/domain/view_report_repository.dart';

/// 캔버스 F4의 견본: 12,500회, 조회수 수당 25,000원(1,000회당 2,000원, 상한 60,000원 안), 사장님께 환불
/// 35,000원, 크리에이터 지급 예정 25,000원. 맡기는 쪽이 보는 미확인 상태가 기본이다.
ViewReport sampleReport({
  ViewReportStatus status = ViewReportStatus.unconfirmed,
  int? views = 12500,
  ViewReportSource source = ViewReportSource.connectedAccount,
  ViewReportCalc? calc,
  bool withCalc = true,
  bool canConfirm = true,
  bool canDispute = true,
  bool canUploadEvidence = false,
  ViewReportEvidence? evidence,
  String postUrl = 'https://www.instagram.com/p/DAbC123/',
}) => ViewReport(
  status: status,
  views: views,
  postUrl: postUrl,
  // 한국 시간으로 11월 4일 정오 ~ 7일 뒤.
  periodStart: DateTime.utc(2026, 11, 4, 3),
  periodEnd: DateTime.utc(2026, 11, 11, 3),
  source: source,
  calc: !withCalc
      ? null
      : (calc ??
            const ViewReportCalc(
              ratePerThousand: 2000,
              cap: 60000,
              capApplied: false,
              fixedCash: 0,
              viewPay: 25000,
              refund: 35000,
              payout: 25000,
            )),
  confirmDueAt: status == ViewReportStatus.unconfirmed
      ? DateTime.utc(2026, 11, 13, 3)
      : null,
  evidence: evidence,
  canConfirm: canConfirm,
  canDispute: canDispute,
  canUploadEvidence: canUploadEvidence,
);

/// 손으로 쓴 가짜 조회 자료 저장소. 확인·이의·캡처를 받으면 서버처럼 상태를 바꾼다.
class FakeViewReportRepository implements ViewReportRepository {
  FakeViewReportRepository({ViewReport? report})
    : report = report ?? sampleReport();

  ViewReport report;
  bool failFetch = false;
  bool notFound = false;

  /// 설정하면 확인·이의·캡처가 이 오류로 실패한다.
  ViewReportFailure? failAction;

  final fetched = <String>[];
  final confirmed = <String>[];
  final disputed = <({String id, String reason})>[];
  final evidence = <({String id, String path, int views})>[];

  @override
  Future<ViewReport> fetch(String collaborationId) async {
    fetched.add(collaborationId);
    if (notFound) throw const ViewReportFailure(notFound: true);
    if (failFetch) throw const ViewReportFailure();
    return report;
  }

  @override
  Future<ViewReport> confirm(String collaborationId) async {
    final error = failAction;
    if (error != null) throw error;
    confirmed.add(collaborationId);
    return report = sampleReport(
      status: ViewReportStatus.confirmed,
      views: report.views,
      source: report.source,
      calc: report.calc,
      withCalc: report.calc != null,
      canConfirm: false,
      canDispute: false,
    );
  }

  @override
  Future<ViewReport> dispute(String collaborationId, String reason) async {
    final error = failAction;
    if (error != null) throw error;
    disputed.add((id: collaborationId, reason: reason));
    return report = sampleReport(
      status: ViewReportStatus.disputed,
      views: report.views,
      source: report.source,
      calc: report.calc,
      withCalc: report.calc != null,
      canConfirm: false,
      canDispute: false,
    );
  }

  @override
  Future<ViewReport> submitEvidence(
    String collaborationId,
    String path,
    int views,
  ) async {
    final error = failAction;
    if (error != null) throw error;
    evidence.add((id: collaborationId, path: path, views: views));
    return report = sampleReport(
      status: ViewReportStatus.counting,
      views: views,
      source: ViewReportSource.capturePending,
      withCalc: false,
      canConfirm: false,
      canDispute: true,
      canUploadEvidence: false,
      evidence: ViewReportEvidence(
        imageUrl: 'https://example.test/evidence.jpg',
        statedViews: views,
      ),
    );
  }
}
