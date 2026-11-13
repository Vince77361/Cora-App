import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/proposals/domain/proposal.dart';
import 'package:cora/features/proposals/presentation/proposal_text.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_proposal_repository.dart';

void main() {
  test('writes each proposal row like the canvas', () {
    expect(rowSubtitle(proposalRow()), '역제안 · 판본 2 · 카드뉴스 1편');
    expect(
      rowSubtitle(
        proposalRow(
          group: ProposalGroup.waiting,
          counter: false,
          version: 1,
          daysLeft: 2,
          format: ContentFormat.reels,
        ),
      ),
      '판본 1 · 릴스 1편 · 2일 안에 답이 와요',
    );
    expect(
      rowSubtitle(
        proposalRow(
          group: ProposalGroup.waiting,
          counter: false,
          version: 1,
          format: ContentFormat.reels,
        ),
      ),
      '판본 1 · 릴스 1편',
    );
    expect(
      rowSubtitle(
        proposalRow(
          group: ProposalGroup.ended,
          endKind: ProposalEndKind.agreed,
        ),
      ),
      '합의 완료 · 계약으로 이동',
    );
    expect(
      rowSubtitle(
        proposalRow(
          group: ProposalGroup.ended,
          endKind: ProposalEndKind.ended,
          endReason: EndReason.schedule,
        ),
      ),
      '일정이 맞지 않아 종료',
    );
  });

  test('writes today for less than a day left', () {
    expect(
      rowSubtitle(
        proposalRow(
          group: ProposalGroup.waiting,
          counter: false,
          version: 1,
          daysLeft: 0,
          format: ContentFormat.reels,
        ),
      ),
      '판본 1 · 릴스 1편 · 오늘 안에 답이 와요',
    );
  });

  test('writes every way a proposal can end', () {
    expect(endedText(ProposalEndKind.ended, EndReason.terms), '조건이 맞지 않아 종료');
    expect(
      endedText(ProposalEndKind.ended, EndReason.otherPartner),
      '다른 분과 진행해 종료',
    );
    expect(endedText(ProposalEndKind.ended, EndReason.noReason), '종료');
    expect(endedText(ProposalEndKind.ended, null), '종료');
    expect(endedText(ProposalEndKind.expired, null), '기한이 지나 종료');
  });

  test('picks the badge by group and how it ended', () {
    expect(rowBadge(proposalRow()), '응답하기');
    expect(rowBadge(proposalRow(group: ProposalGroup.waiting)), '대기');
    expect(
      rowBadge(
        proposalRow(
          group: ProposalGroup.ended,
          endKind: ProposalEndKind.agreed,
        ),
      ),
      '완료',
    );
    expect(
      rowBadge(
        proposalRow(
          group: ProposalGroup.ended,
          endKind: ProposalEndKind.expired,
        ),
      ),
      '종료',
    );
  });

  test('labels the four end reasons', () {
    expect(endReasonLabel(EndReason.schedule), '일정이 맞지 않아요');
    expect(endReasonLabel(EndReason.terms), '조건이 맞지 않아요');
    expect(endReasonLabel(EndReason.otherPartner), '다른 분과 진행해요');
    expect(endReasonLabel(EndReason.noReason), '이유 없이 종료');
  });
}
