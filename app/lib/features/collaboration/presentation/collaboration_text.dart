import '../../../core/time/kst.dart';
import '../../offer_terms/domain/offer_terms.dart';
import '../../offer_terms/presentation/offer_terms_text.dart';
import '../domain/collaboration.dart';
import '../domain/collaboration_repository.dart';

// A7과 진행 중 탭이 같은 문구를 쓰도록 모은 순수 함수들. 날짜는 한국 시간(KST)으로 센다.

String stepTitle(StepKey key) => switch (key) {
  StepKey.accepted => '오퍼 수락',
  StepKey.paid => '가게 결제 완료',
  StepKey.visit => '방문하고 촬영하기',
  StepKey.submit => '콘텐츠 올리고 링크 제출',
  StepKey.settle => '7일간 조회수 집계 후 지급',
};

/// 단계 아래 작은 글씨. 없으면 null이라 줄을 그리지 않는다.
String? stepSubtitle(Collaboration c, StepKey key) => switch (key) {
  StepKey.accepted => _monthDay(c.step(StepKey.accepted)?.at),
  StepKey.paid => 'Cora가 금액을 보관해요',
  // 캔버스 문구는 식사권이 있는 협업의 것이다. 식사권이 없으면 보여 줄 말이 없다.
  StepKey.visit => c.hasVoucher ? '식사권은 방문 때 보여주세요' : null,
  StepKey.submit => c.submitDueAt == null ? null : dueLabel(c.submitDueAt!),
  // 상한은 조건에서 읽는다: 결제 전에는 보관액이 0이다.
  StepKey.settle =>
    c.hasPerView ? '최대 ${won(c.terms.reward.viewPay!.cap)}' : null,
};

/// 보관 상자의 큰 글씨. 돈이 보관 중이면 그 보관액 그대로, 결제 전이면 최대 현금 부담(고정 현금 + 조회수
/// 수당 상한), 현금이 없는 식사권만이면 식사권 이름이다.
String heldLabel(Collaboration c) {
  if (c.hasEscrow) return wonExact(c.escrowAmount);
  final burden = c.terms.reward.maxCashBurden;
  if (burden > 0) return wonExact(burden);
  return c.terms.reward.voucher?.name ?? '';
}

/// 보관 상자 아래 한 줄. `+ 식사권 40,000원 · 2인 (방문 때 사용)`.
String heldVoucherNote(Voucher voucher) =>
    '+ ${benefitLine(voucher)} (방문 때 사용)';

/// `11월 23일까지`.
String dueLabel(DateTime due) => '${_md(due)}까지';

/// `11월 18일`. 없으면 null.
String? _monthDay(DateTime? at) => at == null ? null : _md(at);

String _md(DateTime at) => kstMonthDay(at);

String monthDay(DateTime at) => _md(at);

/// 집계가 끝날 때까지 남은 날. 올림해서 세고, 끝났거나 곧 끝나도 1 밑으로 내려가지 않는다.
int daysLeft(DateTime end, DateTime now) {
  final left = end.difference(now);
  if (left <= Duration.zero) return 1;
  return (left.inMicroseconds / Duration.microsecondsPerDay).ceil();
}

/// `문의하기` 메일 제목.
String inquirySubject(String collaborationId) {
  final short = collaborationId.length <= 8
      ? collaborationId
      : collaborationId.substring(0, 8);
  return '[Cora] 협업 $short 문의';
}

/// 진행 중 탭 줄의 설명: `결제를 기다리고 있어요` / `방문하고 촬영해 주세요 · 11월 23일까지` /
/// `집계 중 · 7일 남음`. 그 밖의 단계는 지금 하는 단계 이름을 보인다.
String activeRowSubtitle(Collaboration c, DateTime now) {
  switch (c.stage) {
    case CollaborationStage.awaitingPayment:
      return '결제를 기다리고 있어요';
    case CollaborationStage.funded:
      final due = c.submitDueAt;
      return due == null ? '방문하고 촬영해 주세요' : '방문하고 촬영해 주세요 · ${dueLabel(due)}';
    case CollaborationStage.counting:
      // 집계가 끝나고 자료 확인을 기다리는 중이다(단계는 그대로 집계 중). "N일 남음"이 아니다.
      if (c.awaitsReportConfirmation) return '집계를 확인하고 있어요';
      final end = c.countingEndsAt;
      return end == null ? '집계 중' : '집계 중 · ${daysLeft(end, now)}일 남음';
    case CollaborationStage.halted:
      return '집계를 확인하고 있어요';
    case CollaborationStage.settled:
      return '정산이 끝났어요';
    case CollaborationStage.refunded:
    case CollaborationStage.cancelled:
    case CollaborationStage.other:
      return '끝난 협업이에요';
  }
}

/// 캔버스에 없는 오류 문구. 서버가 문구를 보내면 그것을 쓰고, 없으면 이것을 쓴다.
const loadFailedMessage = '협업을 불러오지 못했어요.';
const actionFailedMessage = '처리하지 못했어요. 다시 시도해 주세요.';
const submitFailedMessage = '제출하지 못했어요. 다시 시도해 주세요.';
const mailFailedMessage = '메일 앱을 열지 못했어요.';

/// 서버가 보낸 문구가 있으면 그것을, 없으면 [fallback]을 쓴다.
String failureText(Object error, String fallback) {
  final message = switch (error) {
    final CollaborationFailure f => f.message,
    _ => null,
  };
  return (message == null || message.trim().isEmpty) ? fallback : message;
}
