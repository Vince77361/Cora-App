import '../../offer_terms/presentation/offer_terms_text.dart';
import '../../store_result/presentation/store_result_text.dart';
import '../domain/trial_comparison.dart';

// G3(지난 3개월 비교)의 문구를 만드는 순수 함수들. 문구는 캔버스 NSwitchReport 그대로다.

/// 체험단 쪽 `들어간 돈`: `월 300,000원 × 3`.
String trialSpentLine(int monthlyFee) => '월 ${wonExact(monthlyFee)} × 3';

/// Cora 쪽 `들어간 돈`: `오퍼 4건 · 152,000원`.
String coraSpentLine(int offerCount, int spent) =>
    '오퍼 $offerCount건 · ${wonExact(spent)}';

/// Cora 쪽 `생긴 콘텐츠`: `릴스 4편`. 형식이 여럿이면 ` + `로 잇는다. 없으면 `아직 없어요`.
String contentLine(List<ContentCount> byFormat) {
  final parts = [
    for (final c in byFormat)
      if (c.count > 0) '${formatLabel(c.format)} ${c.count}편',
  ];
  return parts.isEmpty ? noneYet : parts.join(' + ');
}

/// 체험단 쪽 `생긴 콘텐츠`: `블로그 글 9개`.
String trialPostsLine(int postCount) => '블로그 글 $postCount개';

/// Cora 쪽 `평소 대비 반응`: `평균 2.6배`. 배수가 있는 협업이 없으면 `아직 없어요`.
String reactionLine(int? averageMultiplierTenths) =>
    averageMultiplierTenths == null
    ? noneYet
    : '평균 ${multiplierLabel(averageMultiplierTenths)}';

/// 맨 위 안내: `체험단 계약이 12월 10일에 끝나요. 다시 계약하기 전에 비교해 보세요.`
String trialEndNotice(DateTime endsOn) =>
    '체험단 계약이 ${endsOn.month}월 ${endsOn.day}일에 끝나요. 다시 계약하기 전에 비교해 보세요.';

const noneYet = '아직 없어요';
