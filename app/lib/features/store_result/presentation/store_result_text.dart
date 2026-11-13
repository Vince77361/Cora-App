import '../../../core/time/kst.dart';
import '../../offer_terms/presentation/offer_terms_text.dart';
import '../domain/store_result.dart';

// G1(7일 결과)의 문구를 만드는 순수 함수들. 문구는 캔버스 NResult 그대로다.

/// 평소 대비 배수. 서버는 10배 한 정수(31)로 주고 소수 첫째 자리까지 보인다: `3.1배`.
String multiplierLabel(int tenths) => '${tenths ~/ 10}.${tenths % 10}배';

/// 우리 가게 평소 조회수: `평소 약 4,000회`.
String usualLabel(int views) => '평소 약 ${_commas(views)}회';

/// 큰 숫자: `12,500회`.
String viewsLabel(int views) => '${_commas(views)}회';

/// 사진 위 줄: `하루 한 컵 · 릴스 · 11월 4일 게시`. 날짜는 한국 시간으로 센다.
String resultSubtitle(StoreResult result) =>
    '${result.creator.name} · ${formatLabel(result.format)} · '
    '${kstMonthDay(result.postedAt)} 게시';

/// 조회수 수당이 없던 협업의 한 줄: `고정 현금 25,000원 지급`.
String fixedCashLine(int fixedCash) => '고정 현금 ${wonExact(fixedCash)} 지급';

String _commas(int n) => wonExact(n).replaceAll('원', '');
