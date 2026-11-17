import '../../negotiation/domain/negotiation_repository.dart' show DropReason;
import '../../offer_terms/presentation/offer_terms_text.dart';
import '../domain/proposal.dart';

// 제안함(F3)과 제안 상세의 문구를 만드는 순수 함수들.

/// 줄 둘째 줄. 내 차례와 대기는 `판본 2 · 카드뉴스 1편`에 상대가 쓴 판본이면 `역제안 · `을, 가게 오퍼의 대기에는
/// 남은 기한을 붙이고, 끝난 제안은 어떻게 끝났는지를 말한다. 브랜드 계약의 줄에는 기한 꼬리가 없다.
String rowSubtitle(InboxRow row) => switch (row) {
  ProposalRow() => _offerSubtitle(row),
  BrandContractRow() => _contractSubtitle(row),
};

String _contractSubtitle(BrandContractRow row) {
  if (row.group == ProposalGroup.ended) {
    return row.endKind == ProposalEndKind.agreed
        ? endedText(ProposalEndKind.agreed, null)
        : dropEndedText(row.myDropReason);
  }
  final base = '판본 ${row.version} · ${formatLabel(row.format)} ${row.pieces}편';
  return row.counter ? '역제안 · $base' : base;
}

/// 협의를 그만둔 줄의 설명. 내가 그만뒀으면 고른 이유를, 상대가 그만뒀으면(이유를 모른다) `협의 종료`만 적는다.
String dropEndedText(DropReason? mine) => switch (mine) {
  DropReason.schedule => '일정이 맞지 않아 종료',
  DropReason.budget => '예산이 맞지 않아 종료',
  DropReason.direction => '방향이 달라 종료',
  DropReason.other => '종료',
  null => '협의 종료',
};

String _offerSubtitle(ProposalRow row) {
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
String rowBadge(InboxRow row) => switch (row.group) {
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
