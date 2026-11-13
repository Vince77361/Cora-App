import '../../../core/time/kst.dart';
import '../../offer_terms/presentation/offer_terms_text.dart';
import '../domain/view_report.dart';
import '../domain/view_report_repository.dart';

// F4 `성과 확인`과 A7·사장님 진행 화면의 입구 줄이 같은 문구를 쓰도록 모은 순수 함수들.

/// 표지. 협업 조회 모델에 `NONE`이 없는 쪽(F4)은 항상 넷 중 하나다.
String statusLabel(ViewReportStatus status) => switch (status) {
  ViewReportStatus.counting => '집계 중',
  ViewReportStatus.unconfirmed => '미확인',
  ViewReportStatus.confirmed => '확인 완료',
  ViewReportStatus.disputed => '이의 제기됨',
};

/// `11월 4일 – 11월 10일 (7일)`. 서버의 끝 시각은 마지막 날이 끝나는 때(제출일 + 기간)라, 보이는 마지막
/// 날은 그 전날이다. 날은 한국 시간으로 센다.
String periodLabel(DateTime start, DateTime end) {
  final first = _kstDate(start);
  final days = _kstDate(end).difference(first).inDays.clamp(1, 366);
  final last = first.add(Duration(days: days - 1));
  return '${first.month}월 ${first.day}일 – ${last.month}월 ${last.day}일 ($days일)';
}

DateTime _kstDate(DateTime at) {
  final kst = toKst(at);
  return DateTime.utc(kst.year, kst.month, kst.day);
}

String sourceLabel(ViewReportSource source) => switch (source) {
  ViewReportSource.connectedAccount => '연결 계정',
  ViewReportSource.capturePending => '캡처 제출 · 확인 중',
  ViewReportSource.captureConfirmed => '캡처 제출 · 확인됨',
};

/// `12,500회 × 1,000회당 2,000원 = 25,000원`. 조회수를 모르면 0회로 적는다(계산이 있으면 조회수도 있다).
String viewPayFormula(ViewReportCalc calc, int? views) =>
    '${_commas(views ?? 0)}회 × ${rateLabel(calc.ratePerThousand)} = ${wonExact(calc.viewPay)}';

/// `60,000원 · 상한 안` / `60,000원 · 상한 적용`.
String capLine(ViewReportCalc calc) =>
    '${wonExact(calc.cap)} · ${calc.capApplied ? '상한 적용' : '상한 안'}';

/// `12,500회`.
String viewsLabel(int views) => '${_commas(views)}회';

/// 쉼표로 끊은 숫자(`12,500`).
String _commas(int n) => wonExact(n).replaceAll('원', '');

/// 게시 링크를 줄에 맞게 줄여 보인다: 앞의 `https://`와 `www.`, 끝의 `/`를 뗀다.
String postLinkLabel(String url) {
  var text = url.trim();
  text = text.replaceFirst(RegExp(r'^https?://', caseSensitive: false), '');
  text = text.replaceFirst(RegExp(r'^www\.', caseSensitive: false), '');
  while (text.endsWith('/')) {
    text = text.substring(0, text.length - 1);
  }
  return text;
}

/// 캔버스에 없는 오류 문구. 서버가 문구를 보내면 그것을 쓰고, 없으면 이것을 쓴다.
const reportLoadFailedMessage = '성과 확인을 불러오지 못했어요.';
const reportNotAvailableMessage = '성과 확인을 볼 수 없는 협업이에요.';
const reportActionFailedMessage = '처리하지 못했어요. 다시 시도해 주세요.';
const reportLinkFailedMessage = '링크를 열지 못했어요.';

/// 서버가 보낸 문구가 있으면 그것을, 없으면 [fallback]을 쓴다.
String reportFailureText(Object error, String fallback) {
  final message = switch (error) {
    final ViewReportFailure f => f.message,
    _ => null,
  };
  return (message == null || message.trim().isEmpty) ? fallback : message;
}
