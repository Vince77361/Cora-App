import '../../offer_terms/presentation/offer_terms_text.dart';
import '../domain/proposal.dart';

// 제안함(F3)과 제안 상세의 문구를 만드는 순수 함수들.

/// 줄 둘째 줄. 내 차례와 대기는 `판본 2 · 카드뉴스 1편`에 상대가 쓴 판본이면 `역제안 · `을, 대기에는 남은
/// 기한을 붙이고, 끝난 제안은 어떻게 끝났는지를 말한다.
String rowSubtitle(ProposalRow row) {
  if (row.group == ProposalGroup.ended) {
    return endedText(row.endKind, row.endReason);
  }
  final base = '판본 ${row.version} · ${formatLabel(row.format)} ${row.pieces}편';
  final head = row.counter ? '역제안 · $base' : base;
  final days = row.daysLeft;
  if (row.group != ProposalGroup.waiting || days == null) return head;
  return '$head · ${days == 0 ? '오늘' : '$days일'} 안에 답이 와요';
}

/// 끝난 제안이 어떻게 끝났는지. 합의했으면 계약으로 간다는 말, 아니면 고른 사유.
String endedText(ProposalEndKind? kind, EndReason? reason) {
  switch (kind) {
    case ProposalEndKind.agreed:
      return '합의 완료 · 계약으로 이동';
    case ProposalEndKind.expired:
      return '기한이 지나 종료';
    case ProposalEndKind.ended:
    case null:
      return switch (reason) {
        EndReason.schedule => '일정이 맞지 않아 종료',
        EndReason.terms => '조건이 맞지 않아 종료',
        EndReason.otherPartner => '다른 분과 진행해 종료',
        EndReason.noReason || null => '종료',
      };
  }
}

/// 줄 오른쪽 알약. `응답하기` / `대기` / `완료` / `종료`.
String rowBadge(ProposalRow row) => switch (row.group) {
  ProposalGroup.myTurn => '응답하기',
  ProposalGroup.waiting => '대기',
  ProposalGroup.ended => row.endKind == ProposalEndKind.agreed ? '완료' : '종료',
};

/// 사유 시트의 선택지.
String endReasonLabel(EndReason reason) => switch (reason) {
  EndReason.schedule => '일정이 맞지 않아요',
  EndReason.terms => '조건이 맞지 않아요',
  EndReason.otherPartner => '다른 분과 진행해요',
  EndReason.noReason => '이유 없이 종료',
};
