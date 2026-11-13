/// 조회 자료 확인(F4)의 단계. 서버의 `ViewReportStatus`와 같다.
enum ViewReportStatus {
  /// 집계 중. 계산이 아직 없다.
  counting,

  /// 계산이 나왔고 맡기는 쪽의 확인을 기다린다. 돈은 아직 보관 중이다.
  unconfirmed,

  /// 확인되어 정산됐다.
  confirmed,

  /// 이의가 걸려 운영팀이 확인할 때까지 돈이 그대로 보관된다.
  disputed,
}

/// 조회수를 어디서 읽었는가.
enum ViewReportSource { connectedAccount, capturePending, captureConfirmed }

/// 서버가 계산한 보상. 앱은 다시 계산하지 않고 그대로 보인다.
class ViewReportCalc {
  const ViewReportCalc({
    required this.ratePerThousand,
    required this.cap,
    required this.capApplied,
    required this.fixedCash,
    required this.viewPay,
    required this.refund,
    required this.payout,
  });

  /// 1,000회당 단가(원).
  final int ratePerThousand;

  /// 조회수 수당 상한(원).
  final int cap;
  final bool capApplied;
  final int fixedCash;
  final int viewPay;

  /// 사장님께 돌아가는 돈.
  final int refund;

  /// 크리에이터 지급 예정액(고정 현금 + 조회수 수당).
  final int payout;
}

/// 크리에이터가 올린 인사이트 캡처. 사진 주소는 비공개 저장소의 서명 주소라 기한이 짧고, 서명 주소를
/// 만들지 못하면 null이다(그때 화면은 사진 자리만 비운다).
class ViewReportEvidence {
  const ViewReportEvidence({required this.imageUrl, required this.statedViews});

  final String? imageUrl;
  final int statedViews;
}

/// 서버의 `ViewReportModel`과 같은 항목(F4).
class ViewReport {
  const ViewReport({
    required this.status,
    required this.postUrl,
    required this.periodStart,
    required this.periodEnd,
    required this.source,
    this.views,
    this.calc,
    this.confirmDueAt,
    this.evidence,
    this.canConfirm = false,
    this.canDispute = false,
    this.canUploadEvidence = false,
  });

  final ViewReportStatus status;

  /// 집계 중에는 그날까지 읽은 값(없으면 null), 계산이 나온 뒤에는 정산에 쓰는 값.
  final int? views;
  final String postUrl;
  final DateTime periodStart;
  final DateTime periodEnd;
  final ViewReportSource source;

  /// 집계 중에는 null이다.
  final ViewReportCalc? calc;

  /// 확인 전일 때 자동으로 확인되는 시각.
  final DateTime? confirmDueAt;
  final ViewReportEvidence? evidence;
  final bool canConfirm;
  final bool canDispute;
  final bool canUploadEvidence;

  /// 화면에 보일 자료 출처. 캡처를 올렸지만 서버가 아직 계산(과 출처 값)을 만들지 않았어도 올린 뒤에는
  /// `캡처 제출 · 확인 중`으로 보인다(서버는 계산이 생긴 뒤에야 출처를 바꾼다).
  ViewReportSource get shownSource =>
      evidence != null && source == ViewReportSource.connectedAccount
      ? ViewReportSource.capturePending
      : source;

  /// 화면에 보일 조회수. 아직 읽은 값이 없으면 크리에이터가 캡처에 적어 낸 값을 보인다.
  int? get shownViews => views ?? evidence?.statedViews;
}
