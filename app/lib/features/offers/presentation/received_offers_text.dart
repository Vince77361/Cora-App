import '../../offer_terms/domain/offer_terms.dart';
import '../../offer_terms/presentation/offer_terms_text.dart';
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

/// 카드 제목 아래 보상 한 줄. 있는 요소를 ` + `로 잇는다: `식사권 2인 + 조회수 수당`,
/// `식사권 2인 + 고정 현금 30,000원 + 조회수 수당`. 요소가 하나도 없으면 `없음`.
String offerRewardHeadline(Reward reward) {
  final parts = [
    if (reward.voucher != null) benefitShort(reward.voucher!),
    if (reward.fixedCash > 0) '고정 현금 ${wonExact(reward.fixedCash)}',
    if (reward.viewPay != null) '조회수 수당',
  ];
  return parts.isEmpty ? '없음' : parts.join(' + ');
}

/// 카드의 `{보상 요약}. {가게 소개}`. 조회수 수당이 있으면 그 줄(`1,000회당 2,000원, 최대 60,000원`)을,
/// 없으면 식사권 한 줄을 쓴다(제목에는 식사권 이름과 인원만 있다). 요약할 것이 없으면(고정 현금만이면
/// 제목이 이미 금액을 말한다) 소개만 쓴다.
String offerDescription(OfferTerms terms, String? storeIntro) {
  final reward = terms.reward;
  final summary = reward.viewPay != null
      ? viewPayLineComma(reward.viewPay!)
      : (reward.voucher == null ? null : benefitLine(reward.voucher!));
  final intro = (storeIntro ?? '').trim();
  if (summary == null) return intro;
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
