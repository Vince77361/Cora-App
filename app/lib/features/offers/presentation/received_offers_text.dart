import '../../offer_terms/domain/offer_terms.dart';
import '../../offer_terms/presentation/offer_terms_text.dart';
import '../../store_browse/presentation/store_browse_text.dart';
import '../domain/received_offer.dart';

/// 오퍼가 도착한 때. `오늘 도착`, `어제 도착`, `3일 전 도착`. 날짜는 휴대폰의 달력 날짜로 센다.
String arrivedAgo(DateTime receivedAt, DateTime now) {
  final received = receivedAt.toLocal();
  final today = now.toLocal();
  final days = DateTime(
    today.year,
    today.month,
    today.day,
  ).difference(DateTime(received.year, received.month, received.day)).inDays;
  if (days <= 0) return '오늘 도착';
  if (days == 1) return '어제 도착';
  return '$days일 전 도착';
}

/// 카드의 `{보상 요약}. {가게 소개}`. 조회수당이 들어간 조건은 조회수당 줄을, 식사권만이면
/// 식사권 요약을 쓴다(식사권 이름은 바로 위 한 줄에 이미 보인다). 소개가 없으면 요약만.
String offerDescription(OfferTerms terms, String? storeIntro) {
  final summary = perViewLine(terms) ?? rewardSummary(terms);
  final intro = (storeIntro ?? '').trim();
  return intro.isEmpty ? summary : '$summary. $intro';
}

/// 카드의 꼬리표: `#팔로워무관`, 그리고 찍기 좋은 시간이 있으면 `#오후3시`처럼 빈칸을 뺀 것.
List<String> offerTags(ReceivedOffer offer) {
  final shooting = (offer.bestShootingTime ?? '').replaceAll(
    RegExp(r'\s+'),
    '',
  );
  return ['#팔로워무관', if (shooting.isNotEmpty) '#$shooting'];
}
