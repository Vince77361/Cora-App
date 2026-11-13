import '../../collaboration/domain/collaboration.dart';
import '../../collaboration/presentation/collaboration_text.dart';
import '../../offer_terms/presentation/offer_terms_text.dart';
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

/// 결제가 끝나 협업이 진행 중이거나 끝난 오퍼인가. 협업을 모르거나 아직 결제 전이면 false라
/// 줄이 `수락함, 결제를 기다려요`로 남는다.
bool sentOfferPaid(SentOffer offer, Collaboration? collaboration) =>
    offer.view == OfferView.accepted &&
    collaboration != null &&
    collaboration.stage != CollaborationStage.awaitingPayment;

/// 보낸 오퍼 줄 설명. 결제가 끝난 오퍼는 [collaboration]의 단계로 말하고, 남은 날짜를 세려고 앱의
/// 시계([now], `clockProvider`)가 필요하다. 협업을 넘기면서 [now]를 빼면 안 된다(테스트가 시각을
/// 못 정하게 되므로 `DateTime.now()`로 대신하지 않는다).
String sentOfferMeta(
  SentOffer offer, {
  Collaboration? collaboration,
  DateTime? now,
}) {
  assert(
    collaboration == null || now != null,
    'sentOfferMeta needs now when a collaboration is passed',
  );
  if (sentOfferPaid(offer, collaboration)) {
    return _collaborationMeta(collaboration!, now!);
  }
  return switch (offer.view) {
    OfferView.waiting => offer.myTurn ? '역제안이 왔어요' : '답을 기다려요',
    OfferView.accepted =>
      offer.paymentDaysLeft == null
          ? '수락함, 결제를 기다려요'
          : '수락함, 결제를 기다려요 · ${offer.paymentDaysLeft}일 남음',
    OfferView.declined => '거절함',
    OfferView.expired => '기한이 지났어요',
    OfferView.cancelled => '취소했어요',
  };
}

/// 결제한 협업의 줄 설명: `결제했어요, 방문을 기다려요` / `집계 중 · 7일 남음` /
/// `끝났어요 · 56,800원 환급`. 캔버스에 없는 단계는 가장 가까운 말로 둔다.
String _collaborationMeta(Collaboration c, DateTime now) {
  switch (c.stage) {
    case CollaborationStage.counting:
      // 집계가 끝나고 자료 확인을 기다리는 중이다(단계는 그대로 집계 중). "N일 남음"이 아니다.
      if (c.awaitsReportConfirmation) return '집계를 확인하고 있어요';
      final end = c.countingEndsAt;
      return end == null ? '집계 중' : '집계 중 · ${daysLeft(end, now)}일 남음';
    case CollaborationStage.halted:
      return '집계를 확인하고 있어요';
    case CollaborationStage.settled:
      final refund = c.settlement?.refundAmount;
      return refund == null ? '끝났어요' : '끝났어요 · ${wonExact(refund)} 환급';
    case CollaborationStage.refunded:
    case CollaborationStage.cancelled:
    case CollaborationStage.other:
      return '끝났어요';
    case CollaborationStage.awaitingPayment:
    case CollaborationStage.funded:
      return '결제했어요, 방문을 기다려요';
  }
}

/// 보낸 오퍼 줄의 버튼. 결제를 기다리는 오퍼는 `결제하기`, 역제안이 와서 내가 답할 차례인 오퍼는 `응답하기`,
/// 거절한 오퍼는 `다시 찾기`, 그 외(결제가 끝난 오퍼 포함)는 버튼이 없다.
String? sentOfferAction(SentOffer offer, {Collaboration? collaboration}) {
  if (sentOfferPaid(offer, collaboration)) return null;
  return switch (offer.view) {
    OfferView.waiting => offer.myTurn ? '응답하기' : null,
    OfferView.accepted => '결제하기',
    OfferView.declined => '다시 찾기',
    _ => null,
  };
}
