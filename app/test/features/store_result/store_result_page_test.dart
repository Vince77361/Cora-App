import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/core/ui/cora_state_view.dart';
import 'package:cora/features/collaboration/domain/collaboration.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/offer_terms/domain/proposal_draft.dart';
import 'package:cora/features/offer_terms/presentation/pages/reward_budget_page.dart';
import 'package:cora/features/offer_terms/presentation/viewmodels/proposal_draft_view_model.dart';
import 'package:cora/features/store_result/presentation/pages/store_result_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../collaboration/fake_collaboration_repository.dart';
import '../collaboration/store_collaboration_harness.dart'
    show FakeLinkLauncher;
import '../store_home/store_home_harness.dart';
import 'fake_store_result_repository.dart';
import 'store_result_harness.dart';

const _pastTerms = OfferTerms(
  format: ContentFormat.reels,
  reward: Reward(
    voucher: Voucher(name: '식사권', value: 40000, people: 2),
    fixedCash: 30000,
    viewPay: ViewPay(ratePerThousand: 2000, cap: 60000),
  ),
);

FakeCollaborationRepository _pastCollaboration() => FakeCollaborationRepository(
  done: [
    collaboration(
      id: storeResultCollaborationId,
      storeName: '하루 한 컵',
      role: CollaborationRole.commissioner,
      stage: CollaborationStage.settled,
      terms: _pastTerms,
    ),
  ],
);

void main() {
  setUpAll(loadAppFonts);

  testWidgets('G1 shows the canvas numbers and the comparison bars', (
    tester,
  ) async {
    await pumpStoreResult(tester);

    expect(find.byType(StoreResultPage), findsOneWidget);
    expect(find.text('7일 결과'), findsOneWidget);
    expect(find.text('하루 한 컵 · 릴스 · 11월 4일 게시'), findsOneWidget);
    expect(find.text('12,500회'), findsOneWidget);
    expect(find.text('우리 가게 평소 게시물 대비'), findsOneWidget);
    expect(find.text('3.1배'), findsOneWidget);
    expect(find.text('평소 약 4,000회'), findsOneWidget);
    expect(find.text('평소'), findsOneWidget);
    expect(find.text('이번'), findsOneWidget);
    expect(find.text('크리에이터 지급'), findsOneWidget);
    expect(find.text('25,000원'), findsOneWidget);
    expect(find.text('사장님께 환불'), findsOneWidget);
    expect(find.text('35,000원'), findsOneWidget);
    expect(find.text('집계 출처와 계산 보기'), findsOneWidget);
    for (final label in ['새 오퍼', '영상 받기', '하루 한 컵과 다시 만나기']) {
      expect(find.text(label), findsOneWidget);
    }

    // 막대 너비: 캔버스는 줄 너비의 32%(평소)와 100%(이번, 글자 칸을 뺀 나머지로 줄어든다).
    final usual = tester.getSize(find.byKey(StoreResultPage.usualBarKey));
    final now = tester.getSize(find.byKey(StoreResultPage.nowBarKey));
    expect(usual.height, 10);
    // 줄 너비는 화면 너비에서 좌우 여백 16과 상자 안쪽 20을 뺀 값이다.
    final row =
        tester.view.physicalSize.width / tester.view.devicePixelRatio - 72;
    expect(usual.width, closeTo(row * 0.32, 0.5));
    expect(now.width, closeTo(row - 44 - 8, 0.5));
    final box = tester.widget<DecoratedBox>(
      find
          .ancestor(
            of: find.byKey(StoreResultPage.nowBarKey),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect(
      (box.decoration as BoxDecoration).color,
      CoraColors.light.compareBarNow,
    );
  });

  testWidgets('G1 hides the comparison without usual views', (tester) async {
    await pumpStoreResult(
      tester,
      results: FakeStoreResultRepository(
        result: sampleResult(usualViews: null, multiplierTenths: null),
      ),
    );

    expect(find.text('12,500회'), findsOneWidget);
    expect(find.text('우리 가게 평소 게시물 대비'), findsNothing);
    expect(find.byKey(StoreResultPage.usualBarKey), findsNothing);
    // 지급·환불 줄은 그대로 보인다.
    expect(find.text('크리에이터 지급'), findsOneWidget);
    expect(find.text('사장님께 환불'), findsOneWidget);
  });

  testWidgets(
    'G1 shows only the fixed cash line for a collaboration without view pay',
    (tester) async {
      await pumpStoreResult(
        tester,
        results: FakeStoreResultRepository(
          result: sampleResult(
            views: null,
            usualViews: null,
            multiplierTenths: null,
            payout: 30000,
            refund: 0,
            fixedCash: 30000,
            fixedCashOnly: true,
          ),
        ),
      );

      expect(find.text('고정 현금 30,000원 지급'), findsOneWidget);
      expect(find.text('하루 한 컵 · 릴스 · 11월 4일 게시'), findsOneWidget);
      expect(find.text('우리 가게 평소 게시물 대비'), findsNothing);
      expect(find.text('크리에이터 지급'), findsNothing);
      expect(find.text('사장님께 환불'), findsNothing);
      expect(find.textContaining('회'), findsNothing);
    },
  );

  testWidgets(
    'G1 opens the submitted post, a new offer and a re-offer with the past terms',
    (tester) async {
      final links = FakeLinkLauncher();
      await pumpStoreResult(
        tester,
        links: links,
        collaborations: _pastCollaboration(),
      );

      await tester.tap(find.text('영상 받기'));
      await tester.pumpAndSettle();
      expect(links.opened, [Uri.parse('https://www.instagram.com/reel/abc')]);

      // 새 오퍼: 지원자가 아닌 크리에이터도 받는 사람으로 열린다.
      await tester.tap(find.text('새 오퍼'));
      await tester.pumpAndSettle();
      expect(topPath(tester), AppRoutes.storeOfferNew('creator-1'));
      expect(find.text('보상을 정해요.'), findsNothing);
      routerOf(tester).pop();
      await tester.pumpAndSettle();

      // 다시 만나기: 지난 조건이 채워진 F1이 바로 열린다.
      await tester.tap(find.text('하루 한 컵과 다시 만나기'));
      await tester.pumpAndSettle();
      expect(topPath(tester), AppRoutes.storeOfferNew('creator-1'));
      expect(find.text(RewardBudgetPage.title), findsOneWidget);
      final draft = containerOf(tester).read(
        proposalDraftViewModelProvider(
          const NewOfferTarget(
            creatorId: 'creator-1',
            creatorName: '하루 한 컵',
            start: _pastTerms,
          ),
        ),
      );
      expect(draft.value, _pastTerms);
    },
  );

  testWidgets('G1 photo label uses the right josa for the creator name', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpStoreResult(
      tester,
      results: FakeStoreResultRepository(result: sampleResult(name: '나비')),
    );

    expect(find.bySemanticsLabel('나비가 올린 콘텐츠'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('G1 says so when the post link cannot be opened', (tester) async {
    final links = FakeLinkLauncher()..opens = false;
    await pumpStoreResult(tester, links: links);

    await tester.tap(find.text('영상 받기'));
    await tester.pumpAndSettle();

    expect(find.text('링크를 열지 못했어요.'), findsOneWidget);
  });

  testWidgets('G1 does not open a link that is not http or https', (
    tester,
  ) async {
    final links = FakeLinkLauncher();
    await pumpStoreResult(
      tester,
      links: links,
      results: FakeStoreResultRepository(
        result: sampleResult(postUrl: 'javascript:alert(1)'),
      ),
    );

    await tester.tap(find.text('영상 받기'));
    await tester.pumpAndSettle();

    expect(links.opened, isEmpty);
    expect(find.text('링크를 열지 못했어요.'), findsOneWidget);
  });

  testWidgets('G1 says the result is unavailable when the server has none', (
    tester,
  ) async {
    await pumpStoreResult(
      tester,
      results: FakeStoreResultRepository()..notFound = true,
    );

    expect(find.byType(CoraStateView), findsOneWidget);
    expect(find.text('7일 결과를 볼 수 없는 협업이에요.'), findsOneWidget);
  });

  testWidgets('G1 offers a retry when loading fails', (tester) async {
    final results = FakeStoreResultRepository()..fail = true;
    await pumpStoreResult(tester, results: results);

    expect(find.text('7일 결과를 불러오지 못했어요.'), findsOneWidget);
    results.fail = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('12,500회'), findsOneWidget);
  });

  testWidgets('does not overflow at 1.3x text scale', (tester) async {
    await pumpStoreResult(
      tester,
      smallPhoneLargeText: true,
      collaborations: _pastCollaboration(),
    );

    expect(find.text('12,500회'), findsOneWidget);
    expect(tester.takeException(), isNull);
    // 가장 긴 버튼 이름도 그대로 보인다(줄여서 맞춘다).
    expect(find.text('하루 한 컵과 다시 만나기'), findsOneWidget);
  });
}
