import 'package:cora/features/negotiation/domain/brand_usage_rights.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/offer_terms/domain/proposal_draft.dart';
import 'package:cora/features/offer_terms/presentation/pages/reward_budget_page.dart';
import 'package:cora/features/server_config/domain/server_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';
import '../server_config/fake_server_config_repository.dart';
import '../store_onboarding/fake_store_repository.dart';
import 'proposal_harness.dart';

BrandProposalTarget _brand({
  ContentFormat format = ContentFormat.reels,
  bool productProvided = true,
  int fee = 300000,
  ViewPay? performance,
  BrandUsageRights usage = BrandUsageRights.repostOnly,
  int nextVersion = 1,
  bool proposedByBrand = true,
}) => BrandProposalTarget(
  recipientName: '서윤의 작은 취향',
  recruitLine: '모아 스튜디오 · 나만의 아침 루틴 속 작은 포인트',
  format: format,
  usageRights: usage,
  startFee: fee,
  startProductProvided: productProvided,
  startPerformance: performance,
  nextVersion: nextVersion,
  proposedByBrand: proposedByBrand,
);

/// 이용료율만 다른 서버 설정(브랜드 계약 수수료율이 쓰이는지 본다).
FakeServerConfigRepository configWithBrandRate(int rate) =>
    FakeServerConfigRepository(
      config: ServerConfig(
        reward: sampleServerConfig.reward,
        feeRates: FeeRates(storeOffer: 10, brandContract: rate, bid: 10),
      ),
    );

/// 브랜드에는 가게가 없다. 가게를 읽으면 실패하는 저장소를 끼워 읽지 않음을 본다.
FakeStoreRepository _noStore() => FakeStoreRepository()..failFetch = true;

void main() {
  setUpAll(loadAppFonts);

  group('F1 brand mode', () {
    testWidgets('uses the brand row labels and no voucher fields', (
      tester,
    ) async {
      final stores = _noStore();
      await pumpProposal(tester, target: _brand(), stores: stores);

      for (final text in ['혜택', '제품 제공', '현금 고정비', '성과 추가']) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      // 가게의 줄 이름과 식사권 칸은 보이지 않는다.
      for (final text in ['제공 혜택', '고정 현금 (선택)', '조회수 수당']) {
        expect(find.text(text), findsNothing, reason: text);
      }
      expect(find.textContaining('식사권'), findsNothing);
      expect(find.text('1 / 2'), findsOneWidget);
      expect(stores.fetchCalls, 0);
    });

    testWidgets('starts from the given values with the performance off', (
      tester,
    ) async {
      await pumpProposal(tester, target: _brand());

      expect(find.text('300,000원'), findsOneWidget);
      // 성과 추가가 꺼져 있어 단가·상한 줄이 없다.
      expect(find.text('단가'), findsNothing);
      expect(find.text('최대 현금 부담 · 남으면 환불'), findsOneWidget);
    });

    testWidgets(
      'the burden preview is the fixed cash plus the performance cap',
      (tester) async {
        await pumpProposal(
          tester,
          target: _brand(
            fee: 300000,
            performance: const ViewPay(ratePerThousand: 2000, cap: 60000),
          ),
        );

        expect(find.text('360,000원'), findsOneWidget);
      },
    );

    testWidgets('the product benefit toggles without changing the burden', (
      tester,
    ) async {
      final send = SendRecorder();
      await pumpProposal(tester, target: _brand(), recorder: send);

      await tester.tap(find.text('제품 제공'));
      await tester.pumpAndSettle();
      expect(find.text('제품 제공'), findsNothing);
      expect(find.text('없음'), findsOneWidget);
      expect(find.text('300,000원'), findsWidgets);
    });

    testWidgets('the fixed cash presets fit the brand range and the custom '
        'sheet accepts up to ten million', (tester) async {
      await pumpProposal(tester, target: _brand());

      expect(find.text('10만 원'), findsOneWidget);
      expect(find.text('100만 원'), findsOneWidget);
      // 가게의 `없음`은 없다: 브랜드의 현금 고정비는 1만 원부터다.
      expect(find.text('없음'), findsNothing);

      await tester.tap(find.text('직접 입력'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('fixedCash.value')),
        '10000000',
      );
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();
      expect(find.text('직접 입력 · 1000만 원'), findsOneWidget);
      expect(find.text('10,000,000원'), findsOneWidget);
    });

    testWidgets('over the brand maximum is refused', (tester) async {
      await pumpProposal(tester, target: _brand());

      await tester.tap(find.text('직접 입력'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('fixedCash.value')),
        '10010000',
      );
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();
      expect(find.textContaining('10,000,000원까지'), findsOneWidget);
    });

    testWidgets('a blog campaign hides the performance add-on', (tester) async {
      await pumpProposal(
        tester,
        target: _brand(
          format: ContentFormat.blog,
          performance: const ViewPay(ratePerThousand: 2000, cap: 60000),
        ),
      );

      // 블로그 글은 성과 추가를 켤 수 없고 시작값에 있어도 꺼진다.
      expect(find.text(RewardBudgetPage.blogNote), findsOneWidget);
      expect(find.text('단가'), findsNothing);
    });

    testWidgets('the performance add-on turns on with the policy defaults', (
      tester,
    ) async {
      await pumpProposal(tester, target: _brand());

      await tester.tap(find.text('성과 추가'));
      await tester.pumpAndSettle();
      expect(find.text('1,000회당 2,000원'), findsOneWidget);
      expect(find.text('최대 60,000원'), findsOneWidget);
      expect(find.text('360,000원'), findsOneWidget);
    });
  });

  group('F2 brand mode', () {
    testWidgets('lists the brand rows with the fixed usage rights', (
      tester,
    ) async {
      final stores = _noStore();
      await pumpProposal(
        tester,
        start: ProposalStart.review,
        target: _brand(
          performance: const ViewPay(ratePerThousand: 2000, cap: 60000),
        ),
        stores: stores,
      );

      expect(find.text('2 / 2'), findsOneWidget);
      for (final text in [
        '받는 사람',
        '서윤의 작은 취향',
        '모집',
        '모아 스튜디오 · 나만의 아침 루틴 속 작은 포인트',
        '결과물',
        '릴스 1편',
        '혜택',
        '제품 제공',
        '현금 고정비',
        '300,000원',
        '성과 추가',
        '1,000회당 2,000원 · 1인 최대 60,000원',
        '사용권',
        '브랜드 계정 재게시',
        '최대 현금 부담',
        '360,000원',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      expect(find.text('제공 혜택'), findsNothing);
      expect(stores.fetchCalls, 0);
    });

    testWidgets('the usage rights row is not editable', (tester) async {
      await pumpProposal(
        tester,
        start: ProposalStart.review,
        target: _brand(usage: BrandUsageRights.adsToo),
      );

      expect(find.text('재게시 + 광고'), findsOneWidget);
      await tester.tap(find.text('재게시 + 광고'));
      await tester.pumpAndSettle();
      // 가게의 사용권 시트가 열리지 않는다.
      expect(find.text('가게 계정 재게시 6개월'), findsNothing);
      expect(find.text('재게시 + 광고'), findsOneWidget);
    });

    testWidgets('the notice uses the brand contract fee rate and the version', (
      tester,
    ) async {
      final config = configWithBrandRate(20);
      await pumpProposal(
        tester,
        start: ProposalStart.review,
        target: _brand(nextVersion: 3),
        config: config,
      );

      // 최대 현금 부담 300,000원의 20% = 60,000원(가게 오퍼 10%였다면 30,000원).
      expect(
        find.text(
          '보낸다고 합의가 되는 건 아니에요. 상대가 수락하면 그때 결제해요. 보낸 조건은 판본 3으로 고정되고, 이용료 60,000원은 별도예요.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('a proposal from the creator has no fee sentence', (
      tester,
    ) async {
      await pumpProposal(
        tester,
        start: ProposalStart.review,
        target: _brand(proposedByBrand: false),
      );

      expect(find.textContaining('이용료'), findsNothing);
    });

    testWidgets('send hands the chosen terms to the sender', (tester) async {
      final send = SendRecorder();
      await pumpProposal(
        tester,
        start: ProposalStart.review,
        target: _brand(),
        recorder: send,
      );

      await tester.tap(find.text('이 조건으로 보내기'));
      await tester.pumpAndSettle();

      expect(send.sent, hasLength(1));
      expect(send.sent.single.reward.fixedCash, 300000);
      expect(
        send.sent.single.reward.voucher,
        BrandProposalTarget.productVoucher,
      );
      expect(send.sent.single.reward.viewPay, isNull);
    });
  });
}
