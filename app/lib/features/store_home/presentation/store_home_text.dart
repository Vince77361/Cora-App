import '../../offers/domain/offer_view.dart';
import '../domain/applicant.dart';
import '../domain/sent_offer.dart';

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

/// 보낸 오퍼 줄 설명.
String sentOfferMeta(SentOffer offer) => switch (offer.view) {
  OfferView.waiting => '답을 기다려요',
  OfferView.accepted =>
    offer.paymentDaysLeft == null
        ? '수락함, 결제를 기다려요'
        : '수락함, 결제를 기다려요 · ${offer.paymentDaysLeft}일 남음',
  OfferView.declined => '거절함',
  OfferView.expired => '기한이 지났어요',
  OfferView.cancelled => '취소했어요',
};

/// 보낸 오퍼 줄의 버튼. 수락한 오퍼는 `결제하기`, 거절한 오퍼는 `다시 찾기`, 그 외는 버튼이 없다.
String? sentOfferAction(SentOffer offer) => switch (offer.view) {
  OfferView.accepted => '결제하기',
  OfferView.declined => '다시 찾기',
  _ => null,
};
