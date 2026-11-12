import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/features/collaboration/domain/collaboration.dart';
import 'package:cora/features/collaboration/domain/collaboration_repository.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:flutter/material.dart' hide StepState;
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_clock.dart';
import '../../support/load_app_fonts.dart';
import '../store_browse/creator_app_harness.dart';
import 'collaboration_harness.dart';
import 'fake_collaboration_repository.dart';

const _id = 'c0ffee11-aaaa-bbbb-cccc-000000000001';

FakeCollaborationRepository _repo(Collaboration c) =>
    FakeCollaborationRepository(active: [c]);

Collaboration _counting() => collaboration(
  stage: CollaborationStage.counting,
  now: StepKey.settle,
  submittedUrl: 'https://www.instagram.com/reel/abc',
  earnedSoFar: 43200,
  currentViews: 4320,
  countingEndsAt: DateTime.utc(2026, 11, 18, 12),
);

void main() {
  setUpAll(loadAppFonts);

  testWidgets('shows the held amount and the visit step as current', (
    tester,
  ) async {
    await pumpCollaboration(tester, repo: _repo(collaboration()));

    expect(topPath(tester), AppRoutes.creatorCollaboration(_id));
    expect(find.text('한그릇 라멘 협업'), findsOneWidget);
    expect(find.text('Cora가 안전하게 보관 중'), findsOneWidget);
    expect(find.text('100,000원'), findsOneWidget);
    expect(find.text('+ 2인 식사권 (방문 때 사용)'), findsOneWidget);
    expect(find.text('링크를 제출하면 집계가 시작돼요.'), findsOneWidget);
    for (final text in [
      '오퍼 수락',
      '11월 10일',
      '가게 결제 완료',
      'Cora가 금액을 보관해요',
      '방문하고 촬영하기',
      '식사권은 방문 때 보여주세요',
      '콘텐츠 올리고 링크 제출',
      '11월 23일까지',
      '7일간 조회수 집계 후 지급',
      '최대 10만 원',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    // 끝난 단계는 ✓, 지금과 남은 단계는 번호.
    expect(find.text('✓'), findsNWidgets(2));
    expect(find.text('3'), findsOneWidget);
    expect(find.text('문의하기'), findsOneWidget);
    expect(find.text('콘텐츠 링크 제출'), findsOneWidget);
    // 보관 중이 아닌 협업 그만두기 메뉴는 canCancel일 때만.
    expect(find.bySemanticsLabel('더보기'), findsNothing);
  });

  testWidgets('shows earned amount and views while counting', (tester) async {
    await pumpCollaboration(
      tester,
      repo: _repo(_counting()),
      clock: FakeClock(), // 2026-11-11 12:00 UTC, 집계 끝까지 7일
    );

    expect(find.text('지금 받을 금액'), findsOneWidget);
    expect(find.text('43,200원'), findsOneWidget);
    expect(find.text('조회수'), findsOneWidget);
    expect(find.text('4,320회'), findsOneWidget);
    expect(find.text('집계 중이에요 · 7일 남음'), findsOneWidget);
    expect(find.text('콘텐츠 링크 제출'), findsNothing);
    expect(find.text('링크를 제출하면 집계가 시작돼요.'), findsNothing);
  });

  testWidgets('asks for a payout account when settled without one', (
    tester,
  ) async {
    final c = collaboration(
      stage: CollaborationStage.settled,
      steps: [
        for (final key in StepKey.values)
          CollaborationStep(key: key, state: StepState.done),
      ],
      payoutStatus: PayoutStatus.needsAccount,
      settlement: const CollaborationSettlement(
        finalViews: 4320,
        payoutAmount: 43200,
        refundAmount: 56800,
      ),
    );
    await pumpCollaboration(tester, repo: _repo(c));

    expect(find.text('지급받을 계좌 등록하기'), findsOneWidget);

    await tester.tap(find.text('지급받을 계좌 등록하기'));
    await tester.pumpAndSettle();
    expect(topPath(tester), AppRoutes.creatorPayoutAccount);
    expect(find.text('지급받을 계좌를\n알려 주세요'), findsOneWidget);
  });

  testWidgets('shows the payout date or the paid amount when settled', (
    tester,
  ) async {
    CollaborationSettlement settlement() => const CollaborationSettlement(
      finalViews: 4320,
      payoutAmount: 43200,
      refundAmount: 56800,
    );
    List<CollaborationStep> done() => [
      for (final key in StepKey.values)
        CollaborationStep(key: key, state: StepState.done),
    ];

    await pumpCollaboration(
      tester,
      repo: _repo(
        collaboration(
          stage: CollaborationStage.settled,
          steps: done(),
          payoutStatus: PayoutStatus.pending,
          payoutScheduledFor: DateTime.utc(2026, 11, 18, 1),
          settlement: settlement(),
        ),
      ),
    );
    expect(find.text('지급 예정 · 11월 18일'), findsOneWidget);

    await pumpCollaboration(
      tester,
      repo: _repo(
        collaboration(
          stage: CollaborationStage.settled,
          steps: done(),
          payoutStatus: PayoutStatus.done,
          settlement: settlement(),
        ),
      ),
    );
    expect(find.text('43,200원이 지급됐어요'), findsOneWidget);
  });

  testWidgets('shows the voucher in large type', (tester) async {
    await pumpCollaboration(tester, repo: _repo(collaboration()));

    await tester.tap(find.text('식사권 보여주기'));
    await tester.pumpAndSettle();

    expect(topPath(tester), AppRoutes.creatorVoucher(_id));
    expect(find.text('한그릇 라멘'), findsOneWidget);
    expect(find.text('2인 식사권'), findsOneWidget);
    expect(find.text('협업 번호 c0ffee11'), findsOneWidget);
    final voucherName = tester.widget<Text>(find.text('2인 식사권'));
    expect(voucherName.style!.fontSize, greaterThanOrEqualTo(32));
  });

  testWidgets('does not show the voucher button without a voucher', (
    tester,
  ) async {
    final c = collaboration(
      terms: const OfferTerms(
        format: ContentFormat.reels,
        rewardType: RewardType.perView,
        perViewAmount: 10,
        perViewCap: 100000,
      ),
    );
    await pumpCollaboration(tester, repo: _repo(c));

    expect(find.text('식사권 보여주기'), findsNothing);
    expect(find.textContaining('식사권'), findsNothing);
  });

  testWidgets('shows the voucher name large for a voucher-only collaboration', (
    tester,
  ) async {
    final c = collaboration(
      escrowAmount: 0,
      terms: const OfferTerms(
        format: ContentFormat.shorts,
        rewardType: RewardType.voucher,
        voucherName: '빵 세트',
        voucherValue: 30000,
      ),
    );
    await pumpCollaboration(tester, repo: _repo(c));

    expect(find.text('빵 세트'), findsOneWidget);
    expect(find.text('0원'), findsNothing);
    expect(find.text('링크를 제출하면 집계가 시작돼요.'), findsNothing);
  });

  testWidgets('cancels after confirmation', (tester) async {
    final repo = _repo(collaboration(canCancel: true));
    await pumpCollaboration(tester, repo: repo);

    await tester.tap(find.bySemanticsLabel('더보기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('협업 그만두기'));
    await tester.pumpAndSettle();

    expect(find.text('협업을 그만둘까요? 가게에 결제 금액을 모두 돌려드려요.'), findsOneWidget);
    expect(repo.cancelled, isEmpty);

    await tester.tap(find.text('계속하기'));
    await tester.pumpAndSettle();
    expect(repo.cancelled, isEmpty);
    expect(topPath(tester), AppRoutes.creatorCollaboration(_id));

    await tester.tap(find.bySemanticsLabel('더보기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('협업 그만두기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('그만두기'));
    await tester.pumpAndSettle();

    expect(repo.cancelled, [_id]);
    expect(topPath(tester), isNot(AppRoutes.creatorCollaboration(_id)));
  });

  testWidgets('shows the server message when cancelling fails', (tester) async {
    final repo = _repo(collaboration(canCancel: true))
      ..failAction = const CollaborationFailure(
        conflict: true,
        message: '지금은 협업을 그만둘 수 없어요.',
      );
    await pumpCollaboration(tester, repo: repo);

    await tester.tap(find.bySemanticsLabel('더보기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('협업 그만두기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('그만두기'));
    await tester.pumpAndSettle();

    expect(find.text('지금은 협업을 그만둘 수 없어요.'), findsOneWidget);
    expect(topPath(tester), AppRoutes.creatorCollaboration(_id));
  });

  testWidgets('accepts an owner cancel request from the banner', (
    tester,
  ) async {
    final repo = _repo(
      collaboration(
        cancelRequest: CancelRequest(
          id: 'req-1',
          expiresAt: DateTime.utc(2026, 11, 14),
          requestedByMe: false,
        ),
      ),
    );
    await pumpCollaboration(tester, repo: repo);

    expect(find.text('한그릇 라멘이 협업 취소를 요청했어요.'), findsOneWidget);
    await tester.tap(find.text('동의하기'));
    await tester.pumpAndSettle();

    expect(repo.acceptedCancels, [(id: _id, requestId: 'req-1')]);
  });

  testWidgets('opens the mail composer with the operator address', (
    tester,
  ) async {
    final mail = FakeMailLauncher();
    await pumpCollaboration(tester, repo: _repo(collaboration()), mail: mail);

    await tester.tap(find.text('문의하기'));
    await tester.pumpAndSettle();

    expect(mail.composed.single.subject, '[Cora] 협업 c0ffee11 문의');
    // 테스트 설정에는 운영자 주소가 없어 받는 사람이 비어 있다.
    expect(mail.composed.single.to, isNull);
  });

  testWidgets('says so when no mail app can be opened', (tester) async {
    final mail = FakeMailLauncher()..opens = false;
    await pumpCollaboration(tester, repo: _repo(collaboration()), mail: mail);

    await tester.tap(find.text('문의하기'));
    await tester.pumpAndSettle();

    expect(find.text('메일 앱을 열지 못했어요.'), findsOneWidget);
  });

  testWidgets('shows an error with retry when loading fails', (tester) async {
    final repo = _repo(collaboration())..failFetch = true;
    await pumpCollaboration(tester, repo: repo);

    expect(find.text('협업을 불러오지 못했어요.'), findsOneWidget);
    repo.failFetch = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('한그릇 라멘 협업'), findsOneWidget);
  });

  testWidgets('uses the dark tokens for the step dots and the box', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await pumpCollaboration(tester, repo: _repo(collaboration()));

    Finder box(Color color) => find.byWidgetPredicate(
      (w) =>
          w is DecoratedBox &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).color == color,
    );
    // 다크 캔버스: 끝난 단계와 지금 단계의 점은 밝은 회색, 남은 단계는 surface.
    expect(box(CoraColors.dark.stepDotDone), findsNWidgets(3));
    expect(box(CoraColors.dark.surface), findsAtLeastNWidgets(3));
    final check = tester.widget<Text>(find.text('✓').first);
    expect(check.style!.color, CoraColors.dark.onStepDotDone);
  });

  testWidgets('does not overflow at 1.3x text scale', (tester) async {
    await pumpCollaboration(
      tester,
      repo: _repo(collaboration(canCancel: true)),
      smallPhoneLargeText: true,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('콘텐츠 링크 제출'), findsOneWidget);
  });
}
