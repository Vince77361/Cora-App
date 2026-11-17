import '../../../core/time/kst.dart';
import '../../negotiation/domain/terms_version.dart';
import '../../offer_terms/domain/offer_terms.dart' show OfferTerms;
import '../../offer_terms/presentation/offer_terms_text.dart';
import '../domain/conversation.dart';

/// 대화 목록과 메시지 요청(11)의 고정 문구. 캔버스 11과 5번 계획 Task 9의 화면 문구 그대로다.
abstract final class ChatTexts {
  static const listTitle = '대화';
  static String requestGroup(int count) => '메시지 요청 $count';

  /// 내가 보낸 요청이 아직 답을 받지 못했을 때, 거절됐을 때, 방이 닫혔을 때 줄의 마지막 메시지 자리.
  static const waitingForAccept = '수락을 기다리고 있어요';
  static const notOpened = '대화가 열리지 않았어요.';
  static const closed = '대화가 종료됐어요.';
  static const noMessages = '아직 메시지가 없어요.';

  static const emptyTitle = '아직 대화가 없어요.';
  static const emptyDescription = '서로 관심이 닿거나 오퍼가 수락되면 대화가 열려요.';
  static const loadFailedTitle = '대화를 불러오지 못했어요';
  static const loadFailedDescription = '연결이 불안정해요. 잠시 뒤 다시 시도해 주세요.';
  static const mutedLabel = '알림 꺼짐';

  // 11
  static const requestTitle = '메시지 요청';
  static const summaryDeliverable = '제작물';
  static const summaryFee = '제작비';
  static const summaryShooting = '촬영';
  static const requestNotice =
      '대화를 열어도 조건을 수락한 게 아니에요. 위 숫자는 협의 중인 제안이에요. 대화를 열기 전에는 내 연락처가 공개되지 않아요. 수락 후에도 대화 관리에서 차단하거나 신고할 수 있어요.';
  static const decline = '요청 거절';
  static const open = '대화 열기';
  static const declineConfirmTitle = '요청을 거절할까요?';
  static const declineConfirmBody = '상대에게는 대화가 열리지 않았다고만 보여요.';
  static const declineAction = '거절하기';
  static const declineCancel = '취소';

  /// 캔버스 밖: 요청을 읽지 못했을 때와 수락·거절에 실패했을 때.
  static const requestLoadFailed = '메시지 요청을 불러오지 못했어요';
  static const requestActionFailed = '처리하지 못했어요. 다시 시도해 주세요.';
  static const requestAlreadyAnswered = '이미 답한 메시지 요청이에요.';
}

const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

/// `오전 9:05` / `오후 3:20`(한국 시간).
String _clock(DateTime kst) {
  final period = kst.hour < 12 ? '오전' : '오후';
  final hour = kst.hour % 12 == 0 ? 12 : kst.hour % 12;
  return '$period $hour:${kst.minute.toString().padLeft(2, '0')}';
}

DateTime _day(DateTime kst) => DateTime.utc(kst.year, kst.month, kst.day);

/// 목록 줄의 시각. 오늘은 `오후 3:20`, 어제는 `어제`, 그 전은 `11월 23일`(한국 시간 기준).
String listTime(DateTime at, DateTime now) {
  final kst = toKst(at);
  final days = _day(toKst(now)).difference(_day(kst)).inDays;
  if (days <= 0) return _clock(kst);
  if (days == 1) return '어제';
  return '${kst.month}월 ${kst.day}일';
}

/// 대화방의 날짜 구분선. `11월 23일 (월)`(한국 시간 기준).
String dayDivider(DateTime at) {
  final kst = toKst(at);
  return '${kst.month}월 ${kst.day}일 (${_weekdays[kst.weekday - 1]})';
}

/// 메시지 요청(11)의 첫 메시지 시각. `오늘 오후 2:14`, `어제 오후 2:14`, `11월 10일 오후 2:14`.
String requestTime(DateTime at, DateTime now) {
  final kst = toKst(at);
  final days = _day(toKst(now)).difference(_day(kst)).inDays;
  final day = days <= 0
      ? '오늘'
      : days == 1
      ? '어제'
      : '${kst.month}월 ${kst.day}일';
  return '$day ${_clock(kst)}';
}

/// 대화방 머리의 조건 요약 한 줄. `릴스 1편, 35만 원 + 제품, 11월 23일 시작`.
/// 성과 추가가 있으면 `릴스 1편, 35만 원 + 제품 + 성과 추가, 11월 23일 시작`.
String termsSummary(TermsVersion terms) {
  final cash = [
    won(terms.fee),
    if (terms.productProvided) '제품',
    if (terms.performance != null) '성과 추가',
  ].join(' + ');
  final start = '${terms.startDate.month}월 ${terms.startDate.day}일 시작';
  return '${formatLabel(terms.format)} ${terms.pieces}편, $cash, $start';
}

/// 가게 오퍼 대화방 머리의 보상 줄. 수락된 판본의 보상 요약이다.
String storeHeaderLine(OfferTerms terms) => rewardHeadline(terms.reward);

/// 대화방 머리의 상태 한 줄. 가게 오퍼는 조건 판본이 없어 null이다.
///
/// `조건 버전 2 · 브랜드 확인 대기`처럼 조건을 주고받는 동안은 아직 확인하지 않은 쪽을 보이고,
/// 합의한 뒤에는 계약 진행, 그 뒤에는 협업 단계를 보인다.
String? statusLine(ConversationDetail detail) {
  if (detail.stage == ConversationStage.inquiry) {
    return '서로 관심 전 · 조건 문의 중';
  }
  if (detail.storeTerms != null && detail.terms == null) return null;
  return switch (detail.stage) {
    ConversationStage.halted => '운영팀 확인 중',
    ConversationStage.dropped => '협의가 끝났어요',
    ConversationStage.contracted ||
    ConversationStage.guided ||
    ConversationStage.reviewing ||
    ConversationStage.approved => '계약 체결 · 제작 중',
    ConversationStage.published || ConversationStage.settled => '협업 완료',
    ConversationStage.agreed =>
      detail.contractStatus == ContractProgress.awaitingBrand
          ? '크리에이터 동의함 · 브랜드 결제 대기'
          : _versionLine(detail.terms, '합의됨 · 계약 대기'),
    ConversationStage.matched || ConversationStage.negotiating => _versionLine(
      detail.terms,
      _waitingFor(detail.terms),
    ),
    ConversationStage.inquiry || ConversationStage.other => null,
  };
}

String? _versionLine(TermsVersion? terms, String? tail) =>
    terms == null || tail == null ? null : '조건 버전 ${terms.version} · $tail';

String? _waitingFor(TermsVersion? terms) {
  if (terms == null) return null;
  if (terms.brandConfirmed && !terms.creatorConfirmed) return '크리에이터 확인 대기';
  if (terms.creatorConfirmed && !terms.brandConfirmed) return '브랜드 확인 대기';
  return '양쪽 확인 대기';
}

/// 목록 줄의 마지막 메시지 자리 글. 상태가 먼저고, 열린 방은 마지막 메시지의 미리 보기다.
String rowMessage(ConversationSummary row) {
  switch (row.status) {
    case ConversationStatus.requested:
      // 내가 답해야 하는 요청은 첫 메시지를 보이고, 내가 보낸 요청은 수락을 기다린다고 알린다.
      return row.section == ConversationSection.request
          ? (row.lastMessage?.preview ?? ChatTexts.noMessages)
          : ChatTexts.waitingForAccept;
    case ConversationStatus.declined:
      return ChatTexts.notOpened;
    case ConversationStatus.closed:
      return ChatTexts.closed;
    case ConversationStatus.open:
      return row.lastMessage?.preview ?? ChatTexts.noMessages;
  }
}

/// 11의 `제작물` 칸. `릴스 1편`.
String requestDeliverable(CampaignTerms terms) => contentLine(terms.format);

/// 11의 `제작비` 칸. `30만 원`.
String requestFee(CampaignTerms terms) => won(terms.fee);

/// 11의 `촬영` 칸. 캔버스는 칸이 좁아 `11/16 이후`로 줄여 쓴다.
String requestShooting(CampaignTerms terms) =>
    '${terms.startFrom.month}/${terms.startFrom.day} 이후';
