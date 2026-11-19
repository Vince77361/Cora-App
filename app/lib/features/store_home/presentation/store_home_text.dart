import '../../../core/text/count_and_date_labels.dart';
import '../../offer_terms/domain/offer_terms.dart';
import '../../offer_terms/presentation/offer_terms_text.dart';
import '../domain/applicant.dart';

// 사장님 홈의 줄 설명을 화면 문구로 바꾸는 순수 함수들.

/// 지원한 때. `오늘 지원`, `어제 지원`, `3일 전 지원`. 날짜는 휴대폰의 달력 날짜로 센다.
String appliedAgo(DateTime appliedAt, DateTime now) {
  final applied = appliedAt.toLocal();
  final today = now.toLocal();
  final days = DateTime(
    today.year,
    today.month,
    today.day,
  ).difference(DateTime(applied.year, applied.month, applied.day)).inDays;
  if (days <= 0) return '오늘 지원';
  if (days == 1) return '어제 지원';
  return '$days일 전 지원';
}

/// 지원자 줄 설명. `맛집 릴스, 오늘 지원`. 콘텐츠를 적지 않았으면 `오늘 지원`만 보인다.
String applicantMeta(Applicant applicant, DateTime now) {
  final applied = appliedAgo(applicant.appliedAt, now);
  final focus = (applicant.creator.contentFocus ?? '').trim();
  return focus.isEmpty ? applied : '$focus, $applied';
}

/// 팔로워 수를 짧게. `640`, `3,100`, `1.8만`(1만 이상은 만 단위, 소수 첫째 자리까지, `.0`은 뗀다).
String followersShort(int followers) {
  if (followers < 10000) return withCommas(followers);
  final tenths = followers * 10 ~/ 10000;
  final whole = tenths ~/ 10;
  final frac = tenths % 10;
  return frac == 0 ? '$whole만' : '$whole.$frac만';
}

/// 추천 칸의 설명 두 줄. 첫 줄은 분야, 둘째 줄은 지원한 때(`오늘 지원`) 또는 지원이 없으면 `팔로워 640`이다.
/// 없는 것은 빼고, 둘 다 없으면 빈 글자다.
String pickDescription({
  String? contentFocus,
  DateTime? appliedAt,
  int? followers,
  required DateTime now,
}) {
  final focus = (contentFocus ?? '').trim();
  final second = appliedAt != null
      ? appliedAgo(appliedAt, now)
      : (followers != null ? '팔로워 ${followersShort(followers)}' : null);
  return [if (focus.isNotEmpty) focus, ?second].join('\n');
}

/// 모집 상자의 큰 글자. 보상 요소를 ` + `로 잇는다(`식사권 2인 + 조회수 수당`). 요소가 하나도 없으면 null이다.
String? recruitHeadline(Reward reward) {
  final parts = [
    if (reward.voucher != null) benefitShort(reward.voucher!),
    if (reward.fixedCash > 0) '고정 현금 ${wonExact(reward.fixedCash)}',
    if (reward.viewPay != null) '조회수 수당',
  ];
  return parts.isEmpty ? null : parts.join(' + ');
}

/// 모집 상자의 작은 글자. 조회수 수당이 있을 때만 단가와 상한이다(`1,000회당 2,000원, 최대 60,000원`).
String? recruitDetail(Reward reward) {
  final viewPay = reward.viewPay;
  return viewPay == null ? null : viewPayLineComma(viewPay);
}
