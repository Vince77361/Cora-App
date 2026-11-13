import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/offer_terms/domain/proposal_draft.dart';
import 'package:cora/features/offer_terms/presentation/pages/reward_budget_page.dart';
import 'package:cora/features/offer_terms/presentation/pages/review_send_page.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';
import 'proposal_harness.dart';

const _newOffer = NewOfferTarget(creatorId: 'c1', creatorName: '하루 한 컵');

const _bothTerms = OfferTerms(
  format: ContentFormat.reels,
  reward: Reward(
    voucher: Voucher(name: '식사권', value: 40000, people: 2),
    viewPay: ViewPay(ratePerThousand: 2000, cap: 60000),
  ),
);

void main() {
  setUpAll(loadAppFonts);

  testWidgets('F2 lists the eight rows and the version number in the notice', (
    tester,
  ) async {
    await pumpProposal(tester, start: ProposalStart.review, target: _newOffer);

    expect(find.text('3 / 3'), findsOneWidget);
    expect(find.bySemanticsLabel('제안 만들기'), findsOneWidget);
    expect(find.text('받는 사람과 조건을\n한 번 더 확인해요.'), findsOneWidget);
    for (final text in [
      '받는 사람',
      '하루 한 컵',
      '모집',
      '한그릇 라멘',
      '결과물',
      '릴스 1편 · 30초 안팎',
      '제공 혜택',
      '식사권 40,000원 · 2인',
      '고정 현금',
      '없음',
      '조회수 수당',
      '1,000회당 2,000원 · 1인 최대 60,000원',
      '사용권',
      '가게 계정 재게시 3개월',
      '최대 현금 부담',
      '60,000원',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(
      find.text(
        '보낸다고 합의가 되는 건 아니에요. 상대가 수락하면 그때 결제해요. '
        '보낸 조건은 판본 1로 고정되고, 이용료 6,000원은 별도예요.',
      ),
      findsOneWidget,
    );
    expect(find.text('고치기'), findsOneWidget);
    expect(find.text('이 조건으로 보내기'), findsOneWidget);
  });

  testWidgets('F2 writes the next version number with the right particle', (
    tester,
  ) async {
    await pumpProposal(
      tester,
      start: ProposalStart.review,
      target: const ReplyTarget(
        offerId: 'o1',
        counterpartName: '하루 한 컵',
        nextVersion: 3,
      ),
    );

    expect(
      find.textContaining('보낸 조건은 판본 3으로 고정되고, 이용료 6,000원은 별도예요.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'F2 ends the notice at the version when there is no cash burden',
    (tester) async {
      await pumpProposal(
        tester,
        start: ProposalStart.review,
        target: _newOffer,
        stores: storeWith(
          defaultTerms: const OfferTerms(
            format: ContentFormat.reels,
            reward: Reward(
              voucher: Voucher(name: '식사권', value: 40000, people: 2),
            ),
          ),
        ),
      );

      expect(
        find.text('보낸다고 합의가 되는 건 아니에요. 상대가 수락하면 그때 결제해요. 보낸 조건은 판본 1로 고정돼요.'),
        findsOneWidget,
      );
      expect(find.text('0원'), findsOneWidget);
      expect(find.text('없음'), findsNWidgets(2)); // 고정 현금, 조회수 수당
    },
  );

  testWidgets('F2 leaves the fee sentence out for a creator proposal', (
    tester,
  ) async {
    await pumpProposal(
      tester,
      start: ProposalStart.review,
      target: const CounterTarget(
        storeId: 's1',
        storeName: '한그릇 라멘',
        nextVersion: 1,
      ),
    );

    expect(find.textContaining('이용료'), findsNothing);
    expect(find.textContaining('판본 1로 고정돼요.'), findsOneWidget);
    // 받는 사람은 가게다.
    expect(find.text('한그릇 라멘'), findsNWidgets(2));
  });

  testWidgets('recruit review shows the open call wording and button', (
    tester,
  ) async {
    await pumpProposal(tester, start: ProposalStart.review);

    expect(find.text('공개 모집'), findsOneWidget);
    expect(
      find.text('크리에이터가 가게 페이지에서 이 조건을 봐요. 오퍼를 보낼 때 바꿀 수 있어요.'),
      findsOneWidget,
    );
    expect(find.textContaining('판본'), findsNothing);
    expect(find.text('이 조건으로 공개하기'), findsOneWidget);
    expect(find.text('이 조건으로 보내기'), findsNothing);
  });

  testWidgets('F2 picks the usage rights from three choices', (tester) async {
    final recorder = SendRecorder();
    await pumpProposal(
      tester,
      start: ProposalStart.review,
      target: _newOffer,
      recorder: recorder,
    );

    await tester.tap(find.text('가게 계정 재게시 3개월'));
    await tester.pumpAndSettle();
    expect(find.text('가게 계정 재게시 6개월'), findsOneWidget);
    expect(find.text('사용 안 함'), findsOneWidget);
    await tester.tap(find.text('가게 계정 재게시 6개월'));
    await tester.pumpAndSettle();
    expect(find.text('가게 계정 재게시 6개월'), findsOneWidget);

    await tester.tap(find.text('이 조건으로 보내기'));
    await tester.pumpAndSettle();
    expect(recorder.sent.single.usageRights, UsageRights.storeRepost6m);
  });

  testWidgets('F2 goes back to F1 from the edit button with the values kept', (
    tester,
  ) async {
    await pumpProposal(tester, target: _newOffer);
    await tester.tap(find.text('3만 원'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('검토하고 보내기'));
    await tester.pumpAndSettle();
    expect(find.text('90,000원'), findsOneWidget);
    expect(find.text('고정 현금'), findsOneWidget);
    expect(find.text('30,000원'), findsOneWidget);

    await tester.tap(find.text('고치기'));
    await tester.pumpAndSettle();

    expect(find.byType(ReviewSendPage), findsNothing);
    expect(find.byType(RewardBudgetPage), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.text('90,000원'), findsOneWidget);
  });

  testWidgets('F2 sends the chosen terms from the last button only', (
    tester,
  ) async {
    final recorder = SendRecorder();
    await pumpProposal(tester, target: _newOffer, recorder: recorder);
    await tester.tap(find.text('5만 원'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('검토하고 보내기'));
    await tester.pumpAndSettle();
    expect(recorder.sent, isEmpty);

    await tester.tap(find.text('이 조건으로 보내기'));
    await tester.pumpAndSettle();

    expect(recorder.sent, [
      _bothTerms.copyWith(reward: _bothTerms.reward.withFixedCash(50000)),
    ]);
  });

  testWidgets('F2 stays and shows the failure message when sending fails', (
    tester,
  ) async {
    final recorder = SendRecorder()..fail = true;
    await pumpProposal(
      tester,
      start: ProposalStart.review,
      target: _newOffer,
      recorder: recorder,
    );

    await tester.tap(find.text('이 조건으로 보내기'));
    await tester.pumpAndSettle();

    expect(find.byType(ReviewSendPage), findsOneWidget);
    expect(find.text('잠시 문제가 생겼어요. 다시 시도해 주세요.'), findsOneWidget);

    recorder.fail = false;
    await tester.tap(find.text('이 조건으로 보내기'));
    await tester.pumpAndSettle();
    expect(recorder.sent, hasLength(2));
    expect(find.text('잠시 문제가 생겼어요. 다시 시도해 주세요.'), findsNothing);
  });

  for (final dark in [false, true]) {
    testWidgets('does not overflow at 1.3x text scale (dark: $dark)', (
      tester,
    ) async {
      await pumpProposal(
        tester,
        start: ProposalStart.review,
        target: _newOffer,
        dark: dark,
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
