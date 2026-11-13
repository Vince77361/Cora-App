/// 사장님이 직접 넣은 체험단 계약 정보. 돈과 글 수는 사장님이 입력한 값이다.
class TrialInfo {
  const TrialInfo({
    required this.monthlyFee,
    required this.endsOn,
    required this.postCount,
  });

  /// 월 계약 금액(원).
  final int monthlyFee;

  /// 계약 종료일(한국 날짜. 시각은 의미 없다).
  final DateTime endsOn;

  /// 석 달 동안 받은 글 수.
  final int postCount;

  @override
  bool operator ==(Object other) =>
      other is TrialInfo &&
      other.monthlyFee == monthlyFee &&
      other.endsOn == endsOn &&
      other.postCount == postCount;

  @override
  int get hashCode => Object.hash(monthlyFee, endsOn, postCount);
}

/// 사장님 홈에 보일 체험단 줄. 언제 어떤 줄을 보일지는 서버가 정한다(종료 30일 전부터, `나중에`는 7일 숨김).
enum TrialBannerKind {
  /// 종료일이 가까워 비교를 보여 준다.
  compare,

  /// 계약 정보를 넣으면 비교해 준다는 안내(한 번만).
  hint,
}

/// `2026-12-10` 모양의 날짜를 [DateTime]으로 바꾼다. 달력에 없는 날짜(2월 30일)나 모양이 다르면 null.
DateTime? parseTrialDate(String text) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(text.trim());
  if (match == null) return null;
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final date = DateTime(year, month, day);
  // DateTime은 2월 30일을 3월 2일로 넘기므로 되돌려 같은지 본다.
  if (date.year != year || date.month != month || date.day != day) return null;
  return date;
}

/// [date]를 `2026-12-10` 모양으로.
String formatTrialDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
