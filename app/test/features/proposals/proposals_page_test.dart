import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/core/ui/cora_state_view.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/proposals/domain/proposal.dart';
import 'package:cora/features/proposals/domain/proposal_repository.dart';
import 'package:cora/features/collaboration/domain/collaboration_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../collaboration/fake_collaboration_repository.dart';
import '../store_browse/creator_app_harness.dart' show pumpCreatorApp;
import '../store_home/store_home_harness.dart';
import 'fake_proposal_repository.dart';

FakeProposalRepository _box() => FakeProposalRepository(
  active: [
    proposalRow(offerId: 'a1'),
    proposalRow(
      offerId: 'a2',
      name: '민의 옷장 기록',
      group: ProposalGroup.waiting,
      counter: false,
      version: 1,
      format: ContentFormat.reels,
      daysLeft: 2,
    ),
    proposalRow(
      offerId: 'a3',
      name: '서윤의 작은 취향',
      group: ProposalGroup.waiting,
      counter: false,
      version: 1,
      format: ContentFormat.reels,
    ),
  ],
  ended: [
    proposalRow(
      offerId: 'e1',
      name: '서윤의 작은 취향',
      group: ProposalGroup.ended,
      endKind: ProposalEndKind.agreed,
      collaborationId: 'col-1',
    ),
    proposalRow(
      offerId: 'e2',
      group: ProposalGroup.ended,
      endKind: ProposalEndKind.ended,
      endReason: EndReason.schedule,
    ),
  ],
  details: {'a1': proposalDetail(offerId: 'a1')},
);

Future<void> _openBox(WidgetTester tester) async {
  routerOf(tester).push(AppRoutes.storeProposals);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('F3 groups active proposals by turn and counts both tabs', (
    tester,
  ) async {
    await pumpStoreHome(
      tester,
      overrides: [proposalRepositoryProvider.overrideWithValue(_box())],
    );
    await _openBox(tester);

    expect(find.text('제안함'), findsOneWidget);
    expect(find.text('진행 중 3'), findsOneWidget);
    expect(find.text('종료 2'), findsOneWidget);
    expect(find.text('내가 응답할 차례'), findsOneWidget);
    expect(find.text('상대 대기'), findsOneWidget);
    expect(find.text('역제안 · 판본 2 · 카드뉴스 1편'), findsOneWidget);
    expect(find.text('판본 1 · 릴스 1편 · 2일 안에 답이 와요'), findsOneWidget);
    expect(find.text('판본 1 · 릴스 1편'), findsOneWidget);
    expect(find.text('응답하기'), findsOneWidget);
    expect(find.text('대기'), findsNWidgets(2));
    // 응답할 차례 묶음이 대기 묶음보다 위에 있다.
    expect(
      tester.getTopLeft(find.text('내가 응답할 차례')).dy,
      lessThan(tester.getTopLeft(find.text('상대 대기')).dy),
    );

    await tester.tap(find.text('종료 2'));
    await tester.pumpAndSettle();
    expect(find.text('종료'), findsNWidgets(2)); // 묶음 이름 + 알약 하나
    expect(find.text('합의 완료 · 계약으로 이동'), findsOneWidget);
    expect(find.text('일정이 맞지 않아 종료'), findsOneWidget);
    expect(find.text('완료'), findsOneWidget);
  });

  Finder box(Color color) => find.byWidgetPredicate(
    (w) =>
        w is DecoratedBox &&
        w.decoration is BoxDecoration &&
        (w.decoration as BoxDecoration).color == color,
  );

  testWidgets('F3 uses the canvas colors in light mode', (tester) async {
    await pumpStoreHome(
      tester,
      overrides: [proposalRepositoryProvider.overrideWithValue(_box())],
    );
    await _openBox(tester);
    final c = CoraColors.light;

    // 줄 셋, 탭 알약 하나가 `surface`이고 고른 탭은 흰색, 응답할 차례의 알약은 라임이다.
    expect(box(c.surface), findsNWidgets(4));
    expect(box(c.quietSelected), findsNWidgets(3)); // 고른 탭 + 대기 알약 둘
    expect(box(c.accent), findsNWidgets(2)); // 응답하기 알약 + 묶음 점
    expect(box(c.iconMuted), findsOneWidget); // 상대 대기 점
  });

  testWidgets('F3 uses the canvas colors in dark mode', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await pumpStoreHome(
      tester,
      overrides: [proposalRepositoryProvider.overrideWithValue(_box())],
    );
    await _openBox(tester);
    final c = CoraColors.dark;

    expect(box(CoraColors.light.surface), findsNothing);
    expect(box(c.surface), findsNWidgets(4));
    // 다크의 고른 탭과 대기 알약은 #2A2D33이다(캔버스).
    expect(c.quietSelected, const Color(0xFF2A2D33));
    expect(box(c.quietSelected), findsNWidgets(3));
    expect(box(c.accent), findsNWidgets(2));
  });

  testWidgets('F3 shows the empty states for the store', (tester) async {
    await pumpStoreHome(
      tester,
      overrides: [
        proposalRepositoryProvider.overrideWithValue(FakeProposalRepository()),
      ],
    );
    await _openBox(tester);

    expect(find.text('진행 중 0'), findsOneWidget);
    expect(find.text('아직 받은 제안이 없어요'), findsOneWidget);
    expect(find.text('크리에이터에게 오퍼를 보내면 여기에 모여요.'), findsOneWidget);
    await tester.tap(find.text('종료 0'));
    await tester.pumpAndSettle();
    expect(find.text('아직 끝난 제안이 없어요'), findsOneWidget);
  });

  testWidgets('F3 shows only the title as the creator empty state', (
    tester,
  ) async {
    await pumpCreatorApp(tester);
    routerOf(tester).push(AppRoutes.creatorProposals);
    await tester.pumpAndSettle();

    expect(find.text('아직 받은 제안이 없어요'), findsOneWidget);
    expect(find.text('크리에이터에게 오퍼를 보내면 여기에 모여요.'), findsNothing);
  });

  testWidgets('F3 shows the failed state and retries', (tester) async {
    final repo = _box()..failFetch = true;
    await pumpStoreHome(
      tester,
      overrides: [proposalRepositoryProvider.overrideWithValue(repo)],
    );
    await _openBox(tester);
    expect(find.text('제안함을 불러오지 못했어요.'), findsOneWidget);
    expect(find.byType(CoraStateView), findsOneWidget);

    repo.failFetch = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('진행 중 3'), findsOneWidget);
  });

  testWidgets('a proposal row opens the detail', (tester) async {
    await pumpStoreHome(
      tester,
      overrides: [proposalRepositoryProvider.overrideWithValue(_box())],
    );
    await _openBox(tester);
    await tester.tap(find.text('하루 한 컵'));
    await tester.pumpAndSettle();

    expect(topPath(tester), AppRoutes.storeProposal('a1'));
    expect(find.text('판본 2'), findsWidgets);
  });

  testWidgets('an agreed row opens the payment screen for the store', (
    tester,
  ) async {
    await pumpStoreHome(
      tester,
      overrides: [
        proposalRepositoryProvider.overrideWithValue(_box()),
        collaborationRepositoryProvider.overrideWithValue(
          FakeCollaborationRepository(),
        ),
      ],
    );
    await _openBox(tester);
    await tester.tap(find.text('종료 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('합의 완료 · 계약으로 이동'));
    await tester.pumpAndSettle();

    // 협업을 못 읽으면 결제 화면이 열린다.
    expect(topPath(tester), AppRoutes.storePay('col-1'));
  });

  testWidgets('an agreed row opens the collaboration for the creator', (
    tester,
  ) async {
    await pumpCreatorApp(
      tester,
      overrides: [proposalRepositoryProvider.overrideWithValue(_box())],
    );
    routerOf(tester).push(AppRoutes.creatorProposals);
    await tester.pumpAndSettle();
    await tester.tap(find.text('종료 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('합의 완료 · 계약으로 이동'));
    await tester.pumpAndSettle();

    expect(topPath(tester), AppRoutes.creatorCollaboration('col-1'));
  });

  testWidgets('does not overflow at 1.3x text scale', (tester) async {
    await pumpStoreHome(
      tester,
      smallPhoneLargeText: true,
      overrides: [proposalRepositoryProvider.overrideWithValue(_box())],
    );
    await _openBox(tester);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('종료 2'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
