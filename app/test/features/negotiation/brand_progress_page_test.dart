import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/core/ui/cora_state_view.dart';
import 'package:cora/features/auth/domain/current_user_provider.dart';
import 'package:cora/features/collaboration/domain/collaboration.dart';
import 'package:cora/features/collaboration/domain/collaboration_repository.dart';
import 'package:cora/features/creator_profile/domain/creator_profile.dart';
import 'package:cora/features/creator_profile/domain/creator_profile_repository.dart';
import 'package:cora/features/negotiation/domain/negotiation_repository.dart';
import 'package:cora/features/negotiation/presentation/pages/brand_progress_page.dart';
import 'package:cora/features/proposals/domain/offer_version.dart';
import 'package:cora/features/proposals/presentation/pages/proposals_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../collaboration/fake_collaboration_repository.dart';
import '../creator_profile/fake_creator_profile_repository.dart';
import 'brand_collaboration_harness.dart';
import 'fake_negotiation_repository.dart';

/// 07을 `/collaborations/:id/progress`에 올린다. 07이 여는 경로는 위치 글자만 보이는 빈 화면이고 위치를 기록한다
/// (`extra`도 함께 적는다). 제안함은 실제 화면이다.
Future<List<String>> _pump(
  WidgetTester tester,
  Collaboration collaboration, {
  ThemeData? theme,
  bool smallPhoneLargeText = false,
  FakeCreatorProfileRepository? profile,
  FakeCollaborationRepository? repo,
}) async {
  if (smallPhoneLargeText) {
    useSmallPhoneWithLargeText(tester);
  } else {
    useCanvasPhone(tester);
  }
  final opened = <String>[];
  Widget stub(GoRouterState state) {
    opened.add('${state.uri}|${state.extra}');
    return Scaffold(body: Text('opened ${state.uri}'));
  }

  final router = GoRouter(
    initialLocation: AppRoutes.collaborationProgress(collaboration.id),
    routes: [
      GoRoute(
        path: AppRoutes.collaborationProgressPattern,
        builder: (context, state) =>
            BrandProgressPage(collaborationId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.collaborationTermsPattern,
        builder: (context, state) => stub(state),
      ),
      GoRoute(
        path: AppRoutes.collaborationContractPattern,
        builder: (context, state) => stub(state),
      ),
      GoRoute(
        path: '/brand/coming-soon/:title',
        builder: (context, state) => stub(state),
      ),
      GoRoute(
        path: '/creator/coming-soon/:title',
        builder: (context, state) => stub(state),
      ),
      GoRoute(
        path: AppRoutes.brandProposals,
        builder: (context, state) =>
            const ProposalsPage(party: ProposalParty.brand),
      ),
      GoRoute(
        path: AppRoutes.brandCollaborations,
        builder: (context, state) => stub(state),
      ),
      GoRoute(
        path: AppRoutes.storeCollaborationPattern,
        builder: (context, state) => stub(state),
      ),
      GoRoute(
        path: AppRoutes.creatorCollaborationPattern,
        builder: (context, state) => stub(state),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        currentUserIdProvider.overrideWithValue('user-1'),
        // 제안함(F3)은 실제 화면이고 브랜드 계약의 줄이 없는 계정이다.
        negotiationRepositoryProvider.overrideWithValue(
          FakeNegotiationRepository(),
        ),
        collaborationRepositoryProvider.overrideWithValue(
          repo ?? FakeCollaborationRepository(active: [collaboration]),
        ),
        creatorProfileRepositoryProvider.overrideWithValue(
          profile ??
              FakeCreatorProfileRepository(
                profile: const CreatorProfile(
                  displayName: '서윤의 작은 취향',
                  regionSido: '서울특별시',
                ),
              ),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: theme ?? coraLightTheme,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return opened;
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('progress shows two of six done after one side confirms', (
    tester,
  ) async {
    await _pump(tester, brandCollab());

    expect(find.text('진행 단계'), findsOneWidget);
    expect(find.text('2 / 6 완료'), findsOneWidget);
    for (final name in [
      '서로 관심 확인',
      '조건 검토 의사 표시',
      '양쪽 조건 확정·계약',
      '기획안 검토·제작',
      '광고 표시·초안 검토',
      '게시·성과 확인',
    ]) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.text('콘텐츠 방향을 함께 잡아요.'), findsOneWidget);
    expect(find.text('서윤의 작은 취향과 모아 스튜디오'), findsOneWidget);
    expect(find.text('상대의 동의를 기다리고 있어요'), findsOneWidget);
    // 끝난 단계 둘은 번호 대신 체크, 지금 단계와 남은 단계는 번호다.
    for (final n in ['3', '4', '5', '6']) {
      expect(find.text(n), findsOneWidget);
    }
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsNothing);
  });

  testWidgets('the progress bar fills done steps over six', (tester) async {
    await _pump(tester, brandCollab(doneCount: 3, current: 4, note: null));

    final bar = tester.widget<FractionallySizedBox>(
      find.byType(FractionallySizedBox),
    );
    expect(bar.widthFactor, closeTo(0.5, 0.0001));
    expect(find.text('3 / 6 완료'), findsOneWidget);
  });

  testWidgets('the current step note follows the progress note and hides when '
      'the next action is to respond to the terms', (tester) async {
    // 상대의 동의를 기다린다: 지금 할 일이 없을 때만 보인다.
    await _pump(tester, brandCollab());
    expect(find.text('상대의 동의를 기다리고 있어요'), findsOneWidget);

    // 내가 응답할 차례면 "상대의 동의를 기다린다"는 글이 틀리므로 숨긴다.
    await _pump(
      tester,
      brandCollab(nextAction: CollaborationNextAction.respondTerms),
    );
    expect(find.text('상대의 동의를 기다리고 있어요'), findsNothing);
    expect(find.text('받은 제안 확인하고 응답하기'), findsOneWidget);

    await _pump(
      tester,
      brandCollab(
        note: BrandProgressNote.waitingContract,
        nextAction: CollaborationNextAction.signContract,
      ),
    );
    expect(find.text('계약을 진행해 주세요'), findsOneWidget);

    await _pump(tester, brandCollab(note: null));
    expect(find.text('상대의 동의를 기다리고 있어요'), findsNothing);
    expect(find.text('계약을 진행해 주세요'), findsNothing);
  });

  testWidgets('progress shows what to do now and opens the terms or the '
      'contract', (tester) async {
    var opened = await _pump(
      tester,
      brandCollab(nextAction: CollaborationNextAction.respondTerms),
    );
    expect(find.text('지금 할 일'), findsOneWidget);

    await tester.tap(find.text('받은 제안 확인하고 응답하기'));
    await tester.pumpAndSettle();
    // 07에서 연 06이라 `extra`로 알린다(수락하면 07로 돌아온다).
    expect(
      opened.last,
      '${AppRoutes.collaborationTerms(brandCollabId)}|fromProgress',
    );

    opened = await _pump(
      tester,
      brandCollab(nextAction: CollaborationNextAction.signContract),
    );
    expect(find.text('계약서 확인하고 동의하기'), findsOneWidget);
    await tester.tap(find.text('계약서 확인하고 동의하기'));
    await tester.pumpAndSettle();
    expect(
      opened.last,
      startsWith(AppRoutes.collaborationContract(brandCollabId)),
    );
  });

  testWidgets('a creator opens the same contract route', (tester) async {
    final opened = await _pump(
      tester,
      brandCollab(
        role: CollaborationRole.creator,
        counterpart: '모아 스튜디오',
        nextAction: CollaborationNextAction.signContract,
      ),
    );

    await tester.tap(find.text('계약서 확인하고 동의하기'));
    await tester.pumpAndSettle();

    expect(
      opened.last,
      startsWith(AppRoutes.collaborationContract(brandCollabId)),
    );
  });

  testWidgets('without a next action the box is hidden', (tester) async {
    await _pump(tester, brandCollab());

    expect(find.text('지금 할 일'), findsNothing);
  });

  testWidgets('progress shows the secured amount and the budget left for a '
      'brand', (tester) async {
    await _pump(tester, brandCollab());

    expect(find.text('이번 협업 확보액'), findsOneWidget);
    expect(find.text('350,000원'), findsOneWidget);
    expect(find.text('남은 캠페인 예산'), findsOneWidget);
    expect(find.text('150,000원'), findsOneWidget);
  });

  testWidgets('progress hides the campaign budget from a creator', (
    tester,
  ) async {
    await _pump(
      tester,
      brandCollab(role: CollaborationRole.creator, counterpart: '모아 스튜디오'),
    );

    expect(find.text('이번 협업 확보액'), findsOneWidget);
    expect(find.text('350,000원'), findsOneWidget);
    expect(find.text('남은 캠페인 예산'), findsNothing);
    expect(find.text('150,000원'), findsNothing);
    // 확보액 한 칸이 가로로 길게 놓인다.
    final cell = tester.getSize(
      find
          .ancestor(
            of: find.text('이번 협업 확보액'),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect(cell.width, closeTo(390 - 40, 0.5));
  });

  testWidgets('progress shows the overrun when the budget is exceeded', (
    tester,
  ) async {
    await _pump(
      tester,
      brandCollab(budget: const CampaignBudgetLeft(left: 0, over: 50000)),
    );

    expect(find.text('0원'), findsOneWidget);
    expect(find.text('예산을 50,000원 넘었어요.'), findsOneWidget);
  });

  testWidgets('without an overrun there is no overrun line', (tester) async {
    await _pump(tester, brandCollab());

    expect(find.textContaining('넘었어요'), findsNothing);
  });

  testWidgets('progress no longer shows the content box or the closing note', (
    tester,
  ) async {
    await _pump(tester, brandCollab());

    expect(find.text('함께 만들 콘텐츠'), findsNothing);
    expect(find.text('상대의 동의와 최종 계약을 확인한 뒤 제작을 시작해요.'), findsNothing);
  });

  testWidgets('tapping the secured amount opens the terms', (tester) async {
    final opened = await _pump(tester, brandCollab());

    await tester.tap(find.text('이번 협업 확보액'));
    await tester.pumpAndSettle();

    expect(
      opened.last,
      '${AppRoutes.collaborationTerms(brandCollabId)}|fromProgress',
    );
  });

  testWidgets('tapping the budget left opens the brand proposals inbox (empty '
      'here)', (tester) async {
    await _pump(tester, brandCollab());

    await tester.tap(find.text('남은 캠페인 예산'));
    await tester.pumpAndSettle();

    expect(find.byType(ProposalsPage), findsOneWidget);
    expect(find.byType(CoraStateView), findsOneWidget);
    expect(find.text('제안함'), findsOneWidget);
    expect(find.text('아직 받은 제안이 없어요'), findsOneWidget);
  });

  testWidgets('a brand sees the brand pill and the brand nav, a creator the '
      'creator ones', (tester) async {
    await _pump(tester, brandCollab());
    expect(find.text('브랜드 관점'), findsOneWidget);
    expect(find.text('협업'), findsOneWidget);

    await _pump(
      tester,
      brandCollab(role: CollaborationRole.creator, counterpart: '모아 스튜디오'),
    );
    expect(find.text('크리에이터 관점'), findsOneWidget);
    expect(find.text('브랜드 관점'), findsNothing);
  });

  testWidgets('the creator name pair reads my own name for a creator', (
    tester,
  ) async {
    await _pump(
      tester,
      brandCollab(role: CollaborationRole.creator, counterpart: '모아 스튜디오'),
    );

    expect(find.text('서윤의 작은 취향과 모아 스튜디오'), findsOneWidget);
  });

  testWidgets('the pair falls back to me when my profile cannot be read', (
    tester,
  ) async {
    await _pump(
      tester,
      brandCollab(role: CollaborationRole.creator, counterpart: '모아 스튜디오'),
      profile: FakeCreatorProfileRepository(profile: null)..failFetch = true,
    );

    expect(find.text('나와 모아 스튜디오'), findsOneWidget);
  });

  testWidgets('a collaboration outside the progress table shows no steps', (
    tester,
  ) async {
    await _pump(tester, brandCollab(withProgress: false));

    expect(find.text('진행 단계'), findsNothing);
    expect(find.text('이번 협업 확보액'), findsOneWidget);
  });

  testWidgets('a store offer id is sent to its own screen instead', (
    tester,
  ) async {
    final storeOffer = collaboration(
      id: 'store-offer-1',
      role: CollaborationRole.creator,
    );
    final opened = await _pump(tester, storeOffer);

    expect(opened.last, startsWith('/creator/collaborations/store-offer-1'));
  });

  testWidgets('a load failure shows the shared failure state and retries', (
    tester,
  ) async {
    final repo = FakeCollaborationRepository(active: [brandCollab()])
      ..failFetch = true;
    await _pump(tester, brandCollab(), repo: repo);

    expect(find.byType(CoraStateView), findsOneWidget);
    expect(find.text('협업을 불러오지 못했어요.'), findsOneWidget);

    repo.failFetch = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(find.text('2 / 6 완료'), findsOneWidget);
  });

  testWidgets('the dark theme uses the dark canvas colors', (tester) async {
    await _pump(tester, brandCollab(), theme: coraDarkTheme);

    final colors = CoraColors.dark;
    expect(colors.progressRing, const Color(0xFFC6FF3D));
    final ring = tester.widgetList<Container>(find.byType(Container)).where((
      c,
    ) {
      final d = c.decoration;
      return d is BoxDecoration &&
          d.shape == BoxShape.circle &&
          d.border != null;
    });
    expect(ring, hasLength(1));
    expect(
      ((ring.single.decoration! as BoxDecoration).border! as Border).top.color,
      colors.progressRing,
    );
    final cell = tester.widget<DecoratedBox>(
      find
          .ancestor(
            of: find.text('이번 협업 확보액'),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect((cell.decoration as BoxDecoration).color, const Color(0xFF1C1E22));
  });

  testWidgets('the photo is 52 inside a 2px ring, 56 across', (tester) async {
    await _pump(tester, brandCollab());

    final ring = tester.widgetList<Container>(find.byType(Container)).where((
      c,
    ) {
      final d = c.decoration;
      return d is BoxDecoration &&
          d.shape == BoxShape.circle &&
          d.border != null;
    });
    final size = tester.getSize(find.byWidget(ring.single));
    expect(size, const Size(56, 56));
  });

  testWidgets('a pushed progress screen has a back button, a standalone one '
      'does not', (tester) async {
    await _pump(tester, brandCollab());
    expect(find.bySemanticsLabel('뒤로'), findsNothing);

    useCanvasPhone(tester);
    final router = GoRouter(
      initialLocation: '/start',
      routes: [
        GoRoute(
          path: '/start',
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () =>
                  context.push(AppRoutes.collaborationProgress(brandCollabId)),
              child: const Text('open progress'),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.collaborationProgressPattern,
          builder: (context, state) =>
              BrandProgressPage(collaborationId: state.pathParameters['id']!),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          collaborationRepositoryProvider.overrideWithValue(
            FakeCollaborationRepository(active: [brandCollab()]),
          ),
          creatorProfileRepositoryProvider.overrideWithValue(
            FakeCreatorProfileRepository(),
          ),
        ],
        child: MaterialApp.router(routerConfig: router, theme: coraLightTheme),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('open progress'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('뒤로'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('뒤로'));
    await tester.pumpAndSettle();
    expect(find.text('open progress'), findsOneWidget);
  });

  testWidgets('tapping the current collaboration tab goes to its root', (
    tester,
  ) async {
    final opened = await _pump(tester, brandCollab());

    await tester.tap(find.text('협업'));
    await tester.pumpAndSettle();

    expect(opened.last, startsWith(AppRoutes.brandCollaborations));
  });

  testWidgets('the light ring is the progress green', (tester) async {
    await _pump(tester, brandCollab());

    final ring = tester.widgetList<Container>(find.byType(Container)).where((
      c,
    ) {
      final d = c.decoration;
      return d is BoxDecoration &&
          d.shape == BoxShape.circle &&
          d.border != null;
    });
    expect(
      ((ring.single.decoration! as BoxDecoration).border! as Border).top.color,
      const Color(0xFF5C7A00),
    );
  });

  testWidgets('does not overflow at 1.3x text scale', (tester) async {
    await _pump(
      tester,
      brandCollab(
        nextAction: CollaborationNextAction.respondTerms,
        budget: const CampaignBudgetLeft(left: 0, over: 1250000),
      ),
      smallPhoneLargeText: true,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('받은 제안 확인하고 응답하기'), findsOneWidget);
  });
}
