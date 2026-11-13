import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/features/collaboration/domain/collaboration.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/view_report/domain/view_report.dart';
import 'package:cora/features/view_report/domain/view_report_repository.dart';
import 'package:cora/features/view_report/presentation/pages/view_report_page.dart';
import 'package:flutter/material.dart' hide StepState;
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../collaboration/collaboration_harness.dart';
import '../collaboration/fake_collaboration_repository.dart';
import '../collaboration/store_collaboration_harness.dart';
import '../store_result/store_result_harness.dart';
import 'fake_view_report_repository.dart';
import 'view_report_harness.dart';

const _fixedAndViewPay = OfferTerms(
  format: ContentFormat.reels,
  reward: Reward(
    voucher: Voucher(name: '식사권', value: 40000, people: 2),
    fixedCash: 30000,
    viewPay: ViewPay(ratePerThousand: 2000, cap: 60000),
  ),
);

Collaboration _awaitingConfirmation({
  CollaborationRole role = CollaborationRole.creator,
  ViewReportStatus status = ViewReportStatus.unconfirmed,
}) => collaboration(
  id: reportCollaborationId,
  role: role,
  stage: CollaborationStage.counting,
  now: StepKey.settle,
  terms: _fixedAndViewPay,
  submittedUrl: 'https://www.instagram.com/reel/abc',
  earnedSoFar: 25000,
  currentViews: 12500,
  countingEndsAt: DateTime.utc(2026, 11, 11, 3),
  viewReportStatus: status,
);

/// 위에 쌓인 화면의 경로(밀려 들어온 화면은 `uri`가 아니라 마지막 일치 경로에 있다).
String _topLocation(WidgetTester tester) =>
    routerOf(tester).routerDelegate.currentConfiguration.last.matchedLocation;

void main() {
  setUpAll(loadAppFonts);

  testWidgets(
    'A7 shows the report row with its badge only for view pay after submission',
    (tester) async {
      final repo = FakeCollaborationRepository(
        active: [_awaitingConfirmation()],
      );
      await pumpCollaboration(
        tester,
        repo: repo,
        id: reportCollaborationId,
        overrides: [
          viewReportRepositoryProvider.overrideWithValue(
            FakeViewReportRepository(),
          ),
        ],
      );

      expect(find.text('조회 자료와 보상 계산 확인'), findsOneWidget);
      expect(find.text('미확인'), findsOneWidget);
      // 집계가 끝나고 확인을 기다리는 동안은 "N일 남음"이 아니다.
      expect(find.textContaining('일 남음'), findsNothing);
      expect(find.text('집계를 확인하고 있어요'), findsOneWidget);

      await tester.tap(find.text('조회 자료와 보상 계산 확인'));
      await tester.pumpAndSettle();
      expect(find.byType(ViewReportPage), findsOneWidget);
      expect(
        _topLocation(tester),
        AppRoutes.creatorViewReport(reportCollaborationId),
      );
    },
  );

  testWidgets(
    'A7 is refreshed when it comes back from a report that moved on',
    (tester) async {
      final repo = FakeCollaborationRepository(
        active: [_awaitingConfirmation(status: ViewReportStatus.counting)],
      );
      await pumpCollaboration(
        tester,
        repo: repo,
        id: reportCollaborationId,
        overrides: [
          viewReportRepositoryProvider.overrideWithValue(
            FakeViewReportRepository(),
          ),
        ],
      );
      expect(find.text('집계 중'), findsOneWidget);

      // 집계가 끝나 계산이 나왔다(서버 쪽 변화).
      repo.active = [_awaitingConfirmation()];
      await tester.tap(find.text('조회 자료와 보상 계산 확인'));
      await tester.pumpAndSettle();
      routerOf(tester).pop();
      await tester.pumpAndSettle();

      expect(find.text('미확인'), findsOneWidget);
      expect(find.text('집계 중'), findsNothing);
    },
  );

  testWidgets('A7 has no report row without a report status', (tester) async {
    final repo = FakeCollaborationRepository(
      active: [collaboration(id: reportCollaborationId)],
    );
    await pumpCollaboration(tester, repo: repo, id: reportCollaborationId);

    expect(find.text('조회 자료와 보상 계산 확인'), findsNothing);
  });

  testWidgets('A7 badges a report that is still being counted', (tester) async {
    final repo = FakeCollaborationRepository(
      active: [_awaitingConfirmation(status: ViewReportStatus.counting)],
    );
    await pumpCollaboration(tester, repo: repo, id: reportCollaborationId);

    expect(find.text('집계 중'), findsOneWidget);
  });

  testWidgets('the store progress screen opens the same report', (
    tester,
  ) async {
    final repo = FakeCollaborationRepository(
      active: [_awaitingConfirmation(role: CollaborationRole.commissioner)],
    );
    await pumpStoreCollaboration(
      tester,
      repo: repo,
      id: reportCollaborationId,
      overrides: [
        viewReportRepositoryProvider.overrideWithValue(
          FakeViewReportRepository(),
        ),
      ],
    );

    expect(find.text('조회 자료와 보상 계산 확인'), findsOneWidget);
    await tester.tap(find.text('조회 자료와 보상 계산 확인'));
    await tester.pumpAndSettle();

    expect(find.byType(ViewReportPage), findsOneWidget);
    expect(
      _topLocation(tester),
      AppRoutes.storeViewReport(reportCollaborationId),
    );
  });

  testWidgets('G1 opens the report from the source and calculation row', (
    tester,
  ) async {
    final reports = FakeViewReportRepository();
    await pumpStoreResult(
      tester,
      overrides: [viewReportRepositoryProvider.overrideWithValue(reports)],
    );

    await tester.tap(find.text('집계 출처와 계산 보기'));
    await tester.pumpAndSettle();

    expect(find.byType(ViewReportPage), findsOneWidget);
    expect(reports.fetched, [storeResultCollaborationId]);
  });

  testWidgets('F4 shows the canvas numbers for an unconfirmed report', (
    tester,
  ) async {
    await pumpOwnerReport(tester);

    expect(find.text('성과 확인'), findsOneWidget);
    // 캔버스 머리의 "안" 표시는 앱에 없다.
    expect(find.text('안'), findsNothing);
    expect(find.text('조회 자료'), findsOneWidget);
    expect(find.text('미확인'), findsOneWidget);
    expect(find.text('12,500회'), findsOneWidget);
    expect(find.text('게시물'), findsOneWidget);
    expect(find.text('instagram.com/p/DAbC123'), findsOneWidget);
    expect(find.text('측정 기간'), findsOneWidget);
    expect(find.text('11월 4일 – 11월 10일 (7일)'), findsOneWidget);
    expect(find.text('자료 출처'), findsOneWidget);
    expect(find.text('연결 계정'), findsOneWidget);
    expect(find.text('보상 계산'), findsOneWidget);
    expect(find.text('조회수 수당'), findsOneWidget);
    expect(find.text('12,500회 × 1,000회당 2,000원 = 25,000원'), findsOneWidget);
    expect(find.text('1인 상한'), findsOneWidget);
    expect(find.text('60,000원 · 상한 안'), findsOneWidget);
    // 고정 현금이 없으면 그 줄이 없다.
    expect(find.text('고정 현금'), findsNothing);
    expect(find.text('사장님께 환불'), findsOneWidget);
    expect(find.text('35,000원'), findsOneWidget);
    expect(find.text('크리에이터 지급 예정'), findsOneWidget);
    expect(find.text('25,000원'), findsOneWidget);
    expect(
      find.text(
        '자료가 확인되기 전에는 0원이나 지급 완료로 처리하지 않아요. 지급 방식(직접 지급 기록 또는 Cora 보관)은 아직 정하는 중이에요.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('F4 puts the values at the right edge and the terms at the left '
      'like the canvas', (tester) async {
    await pumpOwnerReport(tester);

    final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;
    // 상자 안쪽: 바깥 16 + 안쪽 18.
    expect(tester.getTopRight(find.text('연결 계정')).dx, closeTo(width - 34, 0.5));
    expect(tester.getTopLeft(find.text('자료 출처')).dx, closeTo(34, 0.5));
    expect(
      tester.getTopRight(find.text('60,000원 · 상한 안')).dx,
      closeTo(width - 34, 0.5),
    );
  });

  testWidgets('F4 shows the fixed cash line when the terms have fixed cash', (
    tester,
  ) async {
    await pumpOwnerReport(
      tester,
      reports: FakeViewReportRepository(
        report: sampleReport(
          calc: const ViewReportCalc(
            ratePerThousand: 2000,
            cap: 60000,
            capApplied: true,
            fixedCash: 30000,
            viewPay: 60000,
            refund: 0,
            payout: 90000,
          ),
          views: 40000,
        ),
      ),
    );

    expect(find.text('고정 현금'), findsOneWidget);
    expect(find.text('30,000원'), findsOneWidget);
    expect(find.text('60,000원 · 상한 적용'), findsOneWidget);
    expect(find.text('90,000원'), findsOneWidget);
  });

  testWidgets(
    'F4 shows the placeholder instead of the calculation while counting',
    (tester) async {
      await pumpOwnerReport(
        tester,
        reports: FakeViewReportRepository(
          report: sampleReport(
            status: ViewReportStatus.counting,
            views: 4320,
            withCalc: false,
            canConfirm: false,
            canDispute: false,
          ),
        ),
      );

      expect(find.text('집계 중'), findsOneWidget);
      expect(find.text('4,320회'), findsOneWidget);
      expect(find.text('집계가 끝나면 계산해요.'), findsOneWidget);
      expect(find.text('보상 계산'), findsNothing);
      expect(find.text('크리에이터 지급 예정'), findsNothing);
      expect(find.text('자료 확인했어요'), findsNothing);
    },
  );

  testWidgets('F4 lets the owner confirm and then hides both buttons', (
    tester,
  ) async {
    final reports = FakeViewReportRepository();
    await pumpOwnerReport(tester, reports: reports);

    expect(find.text('이의 제기'), findsOneWidget);
    expect(find.text('자료 확인했어요'), findsOneWidget);

    await tester.tap(find.text('자료 확인했어요'));
    await tester.pumpAndSettle();

    expect(reports.confirmed, [reportCollaborationId]);
    expect(find.text('확인 완료'), findsOneWidget);
    expect(find.text('이의 제기'), findsNothing);
    expect(find.text('자료 확인했어요'), findsNothing);
  });

  testWidgets('F4 shows the server message and refreshes when confirming '
      'is no longer possible', (tester) async {
    final reports = FakeViewReportRepository()
      ..failAction = const ViewReportFailure(
        conflict: true,
        message: '이미 자동으로 확인됐어요.',
      );
    await pumpOwnerReport(tester, reports: reports);

    await tester.tap(find.text('자료 확인했어요'));
    await tester.pumpAndSettle();

    expect(find.text('이미 자동으로 확인됐어요.'), findsOneWidget);
    // 최신 상태를 다시 읽는다.
    expect(reports.fetched.length, 2);
  });

  testWidgets('F4 gives the creator only the dispute button', (tester) async {
    await pumpCreatorReport(
      tester,
      reports: FakeViewReportRepository(
        report: sampleReport(canConfirm: false),
      ),
    );

    expect(find.text('이의 제기'), findsOneWidget);
    expect(find.text('자료 확인했어요'), findsNothing);
    expect(find.text('캡처 올리기'), findsNothing);
  });

  testWidgets('F4 hides the buttons after a dispute', (tester) async {
    await pumpCreatorReport(
      tester,
      reports: FakeViewReportRepository(
        report: sampleReport(
          status: ViewReportStatus.disputed,
          canConfirm: false,
          canDispute: false,
        ),
      ),
    );

    expect(find.text('이의 제기됨'), findsOneWidget);
    expect(find.text('이의 제기'), findsNothing);
  });

  testWidgets('F4 sends a dispute with a reason of at most 200 characters', (
    tester,
  ) async {
    final reports = FakeViewReportRepository();
    await pumpCreatorReport(tester, reports: reports);

    await tester.tap(find.text('이의 제기'));
    await tester.pumpAndSettle();

    expect(find.text('이의를 제기하면 운영팀이 확인할 때까지 지급이 멈춰요.'), findsOneWidget);
    final submit = find.text('제기하기');
    // 사유를 쓰기 전에는 누를 수 없다.
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(reports.disputed, isEmpty);

    await tester.enterText(find.byType(TextField), '가' * 250);
    await tester.pump();
    expect(find.text('200/200'), findsOneWidget);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(reports.disputed.length, 1);
    expect(reports.disputed.single.reason, '가' * 200);
    // 시트가 닫히고 표지가 바뀐다.
    expect(find.text('제기하기'), findsNothing);
    expect(find.text('이의 제기됨'), findsOneWidget);
  });

  testWidgets('F4 keeps the dispute sheet open with the server message on '
      'failure', (tester) async {
    final reports = FakeViewReportRepository()
      ..failAction = const ViewReportFailure(message: '이미 이의를 제기했어요.');
    await pumpCreatorReport(tester, reports: reports);

    await tester.tap(find.text('이의 제기'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '조회수가 달라요');
    await tester.pump();
    await tester.tap(find.text('제기하기'));
    await tester.pumpAndSettle();

    expect(find.text('이미 이의를 제기했어요.'), findsOneWidget);
    expect(find.text('제기하기'), findsOneWidget);
  });

  testWidgets('F4 shows a retry when loading fails and an empty state when '
      'the report is not available', (tester) async {
    final reports = FakeViewReportRepository()..failFetch = true;
    await pumpOwnerReport(tester, reports: reports);

    expect(find.text('성과 확인을 불러오지 못했어요.'), findsOneWidget);
    reports.failFetch = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('12,500회'), findsOneWidget);
  });

  testWidgets('F4 says so when the report is not available', (tester) async {
    await pumpOwnerReport(
      tester,
      reports: FakeViewReportRepository()..notFound = true,
    );

    expect(find.text('성과 확인을 볼 수 없는 협업이에요.'), findsOneWidget);
  });

  testWidgets('F4 opens the post in the outside browser', (tester) async {
    final links = FakeLinkLauncher();
    await pumpOwnerReport(tester, links: links);

    await tester.tap(find.text('instagram.com/p/DAbC123'));
    await tester.pumpAndSettle();

    expect(links.opened, [Uri.parse('https://www.instagram.com/p/DAbC123/')]);
  });

  testWidgets(
    'F4 does not let an old link failure hide a later server message',
    (tester) async {
      final links = FakeLinkLauncher()..opens = false;
      final reports = FakeViewReportRepository()
        ..failAction = const ViewReportFailure(
          conflict: true,
          message: '이미 자동으로 확인됐어요.',
        );
      await pumpOwnerReport(tester, reports: reports, links: links);

      await tester.tap(find.text('instagram.com/p/DAbC123'));
      await tester.pumpAndSettle();
      expect(find.text('링크를 열지 못했어요.'), findsOneWidget);

      await tester.tap(find.text('자료 확인했어요'));
      await tester.pumpAndSettle();

      expect(find.text('이미 자동으로 확인됐어요.'), findsOneWidget);
      expect(find.text('링크를 열지 못했어요.'), findsNothing);
    },
  );

  testWidgets('F4 shows the capture and its source when the creator sent one', (
    tester,
  ) async {
    await pumpOwnerReport(
      tester,
      reports: FakeViewReportRepository(
        report: sampleReport(
          source: ViewReportSource.capturePending,
          canConfirm: false,
          evidence: const ViewReportEvidence(
            imageUrl: 'https://example.test/evidence.jpg',
            statedViews: 12500,
          ),
        ),
      ),
    );

    expect(find.text('캡처 제출 · 확인 중'), findsOneWidget);
    expect(find.bySemanticsLabel('제출한 인사이트 캡처'), findsOneWidget);
    expect(find.text('자료 확인했어요'), findsNothing);
  });

  testWidgets(
    'F4 shows a capture as pending before the server made a calculation',
    (tester) async {
      // 서버는 계산 전에 캡처가 있으면 출처를 CAPTURE_PENDING으로 준다. 올린 직후에도 올린 값을 보인다.
      await pumpCreatorReport(
        tester,
        reports: FakeViewReportRepository(
          report: sampleReport(
            status: ViewReportStatus.counting,
            source: ViewReportSource.capturePending,
            views: null,
            withCalc: false,
            canConfirm: false,
            canDispute: false,
            evidence: const ViewReportEvidence(
              imageUrl: 'https://example.test/evidence.jpg',
              statedViews: 9000,
            ),
          ),
        ),
      );

      expect(find.text('캡처 제출 · 확인 중'), findsOneWidget);
      expect(find.text('연결 계정'), findsNothing);
      expect(find.text('9,000회'), findsOneWidget);
    },
  );

  testWidgets(
    'F4 keeps the connected account source when it was calculated after a '
    'capture was sent',
    (tester) async {
      // 캡처를 올린 뒤 연결 계정이 다시 읽혀 그 값으로 계산이 만들어진 협업: 서버 출처가 연결 계정이다.
      await pumpOwnerReport(
        tester,
        reports: FakeViewReportRepository(
          report: sampleReport(
            evidence: const ViewReportEvidence(
              imageUrl: 'https://example.test/evidence.jpg',
              statedViews: 9000,
            ),
          ),
        ),
      );

      expect(find.text('연결 계정'), findsOneWidget);
      expect(find.text('캡처 제출 · 확인 중'), findsNothing);
      expect(find.text('자료 확인했어요'), findsOneWidget);
      expect(find.text('12,500회'), findsOneWidget);
    },
  );

  testWidgets('F4 keeps the connected account source after the owner confirmed '
      'a calculation made with a capture on file', (tester) async {
    await pumpOwnerReport(
      tester,
      reports: FakeViewReportRepository(
        report: sampleReport(
          status: ViewReportStatus.confirmed,
          canConfirm: false,
          canDispute: false,
          evidence: const ViewReportEvidence(
            imageUrl: 'https://example.test/evidence.jpg',
            statedViews: 9000,
          ),
        ),
      ),
    );

    expect(find.text('확인 완료'), findsOneWidget);
    expect(find.text('연결 계정'), findsOneWidget);
    expect(find.text('캡처 제출 · 확인 중'), findsNothing);
  });

  testWidgets('F4 leaves the capture out when the server could not sign it', (
    tester,
  ) async {
    await pumpOwnerReport(
      tester,
      reports: FakeViewReportRepository(
        report: sampleReport(
          source: ViewReportSource.capturePending,
          canConfirm: false,
          evidence: const ViewReportEvidence(
            imageUrl: null,
            statedViews: 12500,
          ),
        ),
      ),
    );

    expect(find.text('캡처 제출 · 확인 중'), findsOneWidget);
    expect(find.bySemanticsLabel('제출한 인사이트 캡처'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('F4 uses the canvas tokens for the badge in dark mode', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await pumpOwnerReport(tester);

    final badge = tester.widget<DecoratedBox>(
      find
          .ancestor(of: find.text('미확인'), matching: find.byType(DecoratedBox))
          .first,
    );
    expect(
      (badge.decoration as BoxDecoration).color,
      CoraColors.dark.reportBadge,
    );
    expect(
      tester.widget<Text>(find.text('미확인')).style!.color,
      CoraColors.dark.textSecondary,
    );
  });

  testWidgets('does not overflow at 1.3x text scale', (tester) async {
    await pumpOwnerReport(tester, smallPhoneLargeText: true);

    expect(tester.takeException(), isNull);
    expect(find.text('자료 확인했어요'), findsOneWidget);
    expect(find.text('성과 확인'), findsOneWidget);
  });

  testWidgets('does not overflow at 1.3x text scale while counting', (
    tester,
  ) async {
    await pumpCreatorReport(
      tester,
      smallPhoneLargeText: true,
      reports: FakeViewReportRepository(
        report: sampleReport(
          status: ViewReportStatus.counting,
          withCalc: false,
          canConfirm: false,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
