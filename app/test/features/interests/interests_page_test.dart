import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/core/ui/cora_bottom_nav.dart';
import 'package:cora/core/ui/cora_state_view.dart';
import 'package:cora/core/ui/swipe_deck/swipe_physics.dart' show SwipeOutcome;
import 'package:cora/features/discovery/domain/discovery_card.dart'
    show CreatorCard;
import 'package:cora/features/discovery/domain/discovery_repository.dart';
import 'package:cora/features/interests/domain/interest_card.dart';
import 'package:cora/features/interests/domain/interests_repository.dart';
import 'package:cora/features/interests/presentation/pages/interests_page.dart';
import 'package:cora/features/interests/presentation/viewmodels/interests_view_model.dart'
    show InterestTab;
import 'package:cora/features/principles/domain/principles.dart' show FeeBand;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../discovery/fake_discovery_repository.dart';
import 'fake_interests_repository.dart';

/// 03을 `/brand/interests`(또는 크리에이터의 `/creator/interests`)에 올린다. 03이 여는 경로는 위치 글자만
/// 보이는 빈 화면이고 위치를 기록한다. 발견 `/brand`와 `/creator`는 시트를 닫고 돌아가는 곳이다.
Future<({List<String> opened, FakeInterestsRepository repo})> _pump(
  WidgetTester tester,
  FakeInterestsRepository repo, {
  FakeDiscoveryRepository? discovery,
  bool isBrand = true,
  String? query,
  ThemeData? theme,
  bool underHome = true,
}) async {
  // 카드 세 장과 아래 상자가 한 화면에 다 들어오게 세로로 긴 화면을 쓴다(스크롤은 따로 시험하지 않는다).
  tester.view.physicalSize = const Size(1170, 3600);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final opened = <String>[];
  Widget stub(GoRouterState state) {
    opened.add(state.uri.toString());
    return Scaffold(body: Text('opened ${state.uri}'));
  }

  final path = isBrand ? AppRoutes.brandInterests : AppRoutes.creatorInterests;
  final router = GoRouter(
    initialLocation: underHome
        ? (isBrand ? AppRoutes.brand : AppRoutes.creator)
        : '$path${query == null ? '' : '?$query'}',
    routes: [
      GoRoute(
        path: isBrand ? AppRoutes.brand : AppRoutes.creator,
        builder: (context, state) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () =>
                  context.push('$path${query == null ? '' : '?$query'}'),
              child: const Text('go interests'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: path,
        builder: (context, state) => InterestsPage(
          isBrand: isBrand,
          initialTab: InterestTab.fromQuery(state.uri.queryParameters['tab']),
          matchId: state.uri.queryParameters['match'],
        ),
      ),
      GoRoute(
        path: AppRoutes.brandCreatorPattern,
        builder: (context, state) => stub(state),
      ),
      GoRoute(
        path: AppRoutes.brandComparePattern,
        builder: (context, state) => stub(state),
      ),
      GoRoute(
        path: '/collaborations/:id/terms',
        builder: (context, state) => stub(state),
      ),
      GoRoute(
        path: '/creator/campaigns/:id',
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
        path: AppRoutes.brandProfile,
        builder: (context, state) => stub(state),
      ),
      GoRoute(
        path: AppRoutes.creatorOffers,
        builder: (context, state) => stub(state),
      ),
      GoRoute(
        path: AppRoutes.brandCollaborations,
        builder: (context, state) => stub(state),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        interestsRepositoryProvider.overrideWithValue(repo),
        discoveryRepositoryProvider.overrideWithValue(
          discovery ?? FakeDiscoveryRepository(),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: theme ?? coraLightTheme,
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (underHome) {
    await tester.tap(find.text('go interests'));
    await tester.pumpAndSettle();
  }
  return (opened: opened, repo: repo);
}

/// 캔버스 Likes의 견본: 서로 관심 하나, 응답 대기 하나, 보류 하나.
FakeInterestsRepository _three() => FakeInterestsRepository(
  cards: [
    brandCard(
      'c1',
      name: '서윤의 작은 취향',
      state: InterestState.mutual,
      fee: 300000,
      startFrom: DateTime(2026, 11, 16),
    ),
    brandCard(
      'c2',
      name: '민의 옷장 기록',
      headline: '같은 니트, 세 가지 액세서리',
      fee: 350000,
    ),
    brandCard(
      'c3',
      name: '하루 한 컵',
      state: InterestState.held,
      headline: '아침 한 컵의 기록',
      feeBand: FeeBand.w400k,
    ),
  ],
);

Finder _picked() => find.bySemanticsLabel('비교에 선택됨');
Finder _notPicked() => find.bySemanticsLabel('비교에 고르기');

void main() {
  setUpAll(loadAppFonts);

  testWidgets('shows counts on each tab and filters the grid', (tester) async {
    await _pump(tester, _three());

    expect(find.text('저장 3'), findsOneWidget);
    expect(find.text('서로 관심 1'), findsOneWidget);
    expect(find.text('보낸 관심 1'), findsOneWidget);
    expect(find.text('보류 1'), findsOneWidget);
    expect(find.text('서윤의 작은 취향'), findsOneWidget);
    expect(find.text('민의 옷장 기록'), findsOneWidget);
    expect(find.text('하루 한 컵'), findsOneWidget);

    await tester.tap(find.text('서로 관심 1'));
    await tester.pumpAndSettle();
    expect(find.text('서윤의 작은 취향'), findsOneWidget);
    expect(find.text('민의 옷장 기록'), findsNothing);
    expect(find.text('하루 한 컵'), findsNothing);

    await tester.tap(find.text('보낸 관심 1'));
    await tester.pumpAndSettle();
    expect(find.text('민의 옷장 기록'), findsOneWidget);
    expect(find.text('서윤의 작은 취향'), findsNothing);

    await tester.tap(find.text('보류 1'));
    await tester.pumpAndSettle();
    expect(find.text('하루 한 컵'), findsOneWidget);
    expect(find.text('민의 옷장 기록'), findsNothing);
  });

  testWidgets('the tab query opens that tab', (tester) async {
    await _pump(tester, _three(), query: 'tab=held');

    expect(find.text('하루 한 컵'), findsOneWidget);
    expect(find.text('서윤의 작은 취향'), findsNothing);
  });

  testWidgets('the card shows the badge, the headline and the cash line', (
    tester,
  ) async {
    await _pump(tester, _three());

    // 표지(서로 관심은 탭 이름과 겹치므로 카드 안에서만 센다).
    expect(find.text('서로 관심'), findsOneWidget);
    expect(find.text('응답 대기'), findsOneWidget);
    expect(find.text('보류'), findsOneWidget);
    expect(find.text('출근 전 30초, 오늘의 손목 루틴'), findsOneWidget);
    expect(find.text('같은 니트, 세 가지 액세서리'), findsOneWidget);
    expect(find.text('아침 한 컵의 기록'), findsOneWidget);
    // 서로 관심: 최신 판본의 제작비와 시작일. 응답 대기: 내 제안 금액, 일정 협의. 보류: 희망 제작비 구간.
    expect(find.text('30만 원, 11월 16일 이후'), findsOneWidget);
    expect(find.text('35만 원, 일정 협의'), findsOneWidget);
    expect(find.text('40만 원대, 일정 협의'), findsOneWidget);
  });

  testWidgets('never shows passed candidates', (tester) async {
    final discovery = FakeDiscoveryRepository();
    final repo = _three();
    await _pump(tester, repo, discovery: discovery);

    // 목록에는 저장한(관심 + 보류) 것만 오고, 넘김이라는 표시가 어디에도 없다.
    expect(find.textContaining('넘김'), findsNothing);
    expect(find.text('넘기기'), findsNothing);

    // 보류한 카드를 넘기면 목록에서 사라진다.
    await tester.tap(find.text('하루 한 컵'));
    await tester.pumpAndSettle();
    // 서버에서도 그 카드는 목록에서 빠진다.
    repo.cards = [
      for (final c in repo.cards)
        if (c.id != 'c3') c,
    ];
    await tester.tap(find.text('넘기기'));
    await tester.pumpAndSettle();

    expect(discovery.decisions.single.outcome, SwipeOutcome.pass);
    expect(find.text('하루 한 컵'), findsNothing);
    expect(find.text('저장 2'), findsOneWidget);
  });

  testWidgets('the first tab is labelled saved and counts likes and holds', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeInterestsRepository(
        cards: [
          brandCard('c2', name: '민의 옷장 기록'),
          brandCard('c3', name: '하루 한 컵', state: InterestState.held),
        ],
      ),
    );

    expect(find.text('저장 2'), findsOneWidget);
    expect(find.text('보낸 관심 1'), findsOneWidget);
    expect(find.text('보류 1'), findsOneWidget);
    expect(find.text('서로 관심 0'), findsOneWidget);
  });

  testWidgets('the top two saved cards start selected for comparison', (
    tester,
  ) async {
    await _pump(tester, _three());

    expect(_picked(), findsNWidgets(2));
    expect(_notPicked(), findsOneWidget);
    expect(find.text('선택한 2명 비교하기'), findsOneWidget);
  });

  testWidgets('tapping the circle toggles the comparison check', (
    tester,
  ) async {
    await _pump(tester, _three());

    // 고른 첫 카드를 풀면 하나 남고 버튼은 꺼진다.
    await tester.tap(_picked().first);
    await tester.pumpAndSettle();
    expect(_picked(), findsOneWidget);
    expect(_notPicked(), findsNWidgets(2));
    expect(find.text('선택한 1명 비교하기'), findsOneWidget);

    // 다른 카드를 고르면 다시 두 장이다.
    await tester.tap(_notPicked().last);
    await tester.pumpAndSettle();
    expect(_picked(), findsNWidgets(2));
    expect(find.text('선택한 2명 비교하기'), findsOneWidget);
  });

  testWidgets('a third selection is refused with a message', (tester) async {
    await _pump(tester, _three());

    await tester.tap(_notPicked());
    await tester.pump();

    expect(find.text('비교는 2명까지예요.'), findsOneWidget);
    expect(_picked(), findsNWidgets(2));
    expect(_notPicked(), findsOneWidget);

    // 알림은 3초 뒤에 사라진다.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('비교는 2명까지예요.'), findsNothing);
  });

  testWidgets('compare is enabled only with two selected cards and shows the '
      'count', (tester) async {
    final env = await _pump(tester, _three());

    expect(find.text('비교할 후보 2명을 골라 주세요.'), findsNothing);
    await tester.tap(find.text('선택한 2명 비교하기'));
    await tester.pumpAndSettle();
    // 표의 왼쪽·오른쪽은 고른 순서가 아니라 목록 순서다.
    expect(env.opened, ['/brand/interests/compare?a=c1&b=c2']);
  });

  testWidgets('compare is off and explains itself unless two are selected', (
    tester,
  ) async {
    final env = await _pump(tester, _three());
    await tester.tap(_picked().first);
    await tester.pumpAndSettle();

    expect(find.text('비교할 후보 2명을 골라 주세요.'), findsOneWidget);
    await tester.tap(find.text('선택한 1명 비교하기'));
    await tester.pumpAndSettle();
    expect(env.opened, isEmpty);
  });

  testWidgets('selection follows the list order, not the tapping order', (
    tester,
  ) async {
    final env = await _pump(tester, _three());
    await tester.tap(_picked().first);
    await tester.pumpAndSettle();
    // 두 번째로 풀린 c1을 다시 고르면 c2, c1 순으로 고른 셈이지만 표는 c1, c2다.
    await tester.tap(_notPicked().first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('선택한 2명 비교하기'));
    await tester.pumpAndSettle();

    expect(env.opened.single, startsWith('/brand/interests/compare?a=c1&b='));
  });

  testWidgets('the creator side has no comparison controls', (tester) async {
    await _pump(
      tester,
      FakeInterestsRepository(
        cards: [
          campaignCard('k1', name: '모아 스튜디오', state: InterestState.mutual),
          campaignCard('k2', name: '느린 시계', state: InterestState.held),
        ],
      ),
      isBrand: false,
    );

    expect(_picked(), findsNothing);
    expect(_notPicked(), findsNothing);
    expect(find.textContaining('비교'), findsNothing);
    expect(find.text('저장은 나만 보고, 관심은 상대에게 전해져요.'), findsOneWidget);
  });

  testWidgets('the brand description tells to pick candidates to compare', (
    tester,
  ) async {
    await _pump(tester, _three());

    expect(find.text('저장은 나만 보고, 관심은 상대에게 전해져요. 비교할 후보를 골라요.'), findsOneWidget);
  });

  testWidgets('a mutual candidate shows the box and opens the terms screen', (
    tester,
  ) async {
    final env = await _pump(tester, _three());

    expect(find.text('서윤의 작은 취향과 서로 관심'), findsOneWidget);
    expect(find.text('민의 옷장 기록은 상대의 응답을 기다리고 있어요.'), findsOneWidget);

    await tester.tap(find.text('협업 조건 확인'));
    await tester.pumpAndSettle();
    expect(env.opened, ['/collaborations/collab-c1/terms']);
  });

  testWidgets('without a mutual or waiting candidate there is no box', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeInterestsRepository(
        cards: [brandCard('c3', name: '하루 한 컵', state: InterestState.held)],
      ),
    );

    expect(find.text('협업 조건 확인'), findsNothing);
    expect(find.textContaining('응답을 기다리고'), findsNothing);
  });

  testWidgets('a held card can be turned into a like or a pass', (
    tester,
  ) async {
    final discovery = FakeDiscoveryRepository();
    final repo = _three();
    await _pump(tester, repo, discovery: discovery);

    await tester.tap(find.text('하루 한 컵'));
    await tester.pumpAndSettle();
    expect(find.text('관심 보내기'), findsOneWidget);
    expect(find.text('넘기기'), findsOneWidget);

    // 서버에서도 관심으로 바뀐 것처럼 목록이 새로 온다.
    repo.cards = [
      for (final c in repo.cards)
        if (c.id == 'c3')
          brandCard('c3', name: '하루 한 컵', headline: '아침 한 컵의 기록')
        else
          c,
    ];
    await tester.tap(find.text('관심 보내기'));
    await tester.pumpAndSettle();

    expect(discovery.decisions.single.outcome, SwipeOutcome.like);
    expect(discovery.decisions.single.target.id, 'c3');
    expect(find.text('관심을 보냈어요. 상대도 고르면 알려드려요.'), findsOneWidget);
    expect(find.text('보류 0'), findsOneWidget);
    expect(find.text('보낸 관심 2'), findsOneWidget);
  });

  testWidgets('a held card turned into a like that matches opens the match '
      'sheet', (tester) async {
    final discovery = FakeDiscoveryRepository()..matchOn.add('c3');
    final repo = _three()
      ..match = matchInfo(collaborationId: 'collab-c3', creatorName: '하루 한 컵');
    await _pump(tester, repo, discovery: discovery);

    await tester.tap(find.text('하루 한 컵'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('관심 보내기'));
    await tester.pumpAndSettle();

    expect(repo.matchesFetched, ['collab-c3']);
    expect(find.text('서로를 골랐어요.'), findsOneWidget);
  });

  testWidgets('a failed decision on a held card keeps the card and says so', (
    tester,
  ) async {
    final discovery = FakeDiscoveryRepository()..failDecide = true;
    await _pump(tester, _three(), discovery: discovery);

    await tester.tap(find.text('하루 한 컵'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('넘기기'));
    await tester.pumpAndSettle();

    expect(find.text('하루 한 컵'), findsOneWidget);
    expect(find.text('잠시 뒤 다시 시도해 주세요.'), findsOneWidget);
  });

  testWidgets('tapping a card outside the circle opens the creator detail', (
    tester,
  ) async {
    final env = await _pump(tester, _three());

    await tester.tap(find.text('민의 옷장 기록'));
    await tester.pumpAndSettle();

    expect(env.opened, ['/brand/creators/c2']);
  });

  testWidgets('the creator side opens the campaign for a saved card', (
    tester,
  ) async {
    final env = await _pump(
      tester,
      FakeInterestsRepository(cards: [campaignCard('k1', name: '모아 스튜디오')]),
      isBrand: false,
    );

    await tester.tap(find.text('모아 스튜디오'));
    await tester.pumpAndSettle();

    expect(env.opened, ['/creator/campaigns/k1']);
  });

  testWidgets('shows the empty message', (tester) async {
    await _pump(tester, FakeInterestsRepository());

    expect(find.byType(CoraStateView), findsOneWidget);
    expect(find.text('아직 담은 후보가 없어요.'), findsOneWidget);
    expect(find.text('발견에서 마음에 드는 카드를 오른쪽으로 밀어 보세요.'), findsOneWidget);
    expect(find.textContaining('비교하기'), findsNothing);
  });

  testWidgets('an empty tab shows the empty message but keeps the tabs', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeInterestsRepository(cards: [brandCard('c2', name: '민의 옷장 기록')]),
    );

    await tester.tap(find.text('보류 0'));
    await tester.pumpAndSettle();

    expect(find.text('아직 담은 후보가 없어요.'), findsOneWidget);
    expect(find.text('저장 1'), findsOneWidget);
  });

  testWidgets('a failed load can be retried', (tester) async {
    final repo = FakeInterestsRepository(
      cards: [brandCard('c2', name: '민의 옷장 기록')],
    )..failFetch = true;
    await _pump(tester, repo);

    expect(find.text('관심 목록을 불러오지 못했어요'), findsOneWidget);

    repo.failFetch = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('민의 옷장 기록'), findsOneWidget);
  });

  testWidgets('the menu marks the interests tab for a brand', (tester) async {
    final env = await _pump(tester, _three());

    final nav = tester.widget<CoraBottomNav>(find.byType(CoraBottomNav));
    expect(nav.currentIndex, CoraCreatorNavItems.likes);
    await tester.tap(
      find.descendant(
        of: find.byType(CoraBottomNav),
        matching: find.text('프로필'),
      ),
    );
    await tester.pumpAndSettle();
    expect(env.opened, ['/brand/profile']);
  });

  group('the match query', () {
    testWidgets('opens the match sheet and closing returns to discovery', (
      tester,
    ) async {
      final repo = _three()..match = matchInfo();
      await _pump(tester, repo, query: 'match=collab-c1');

      expect(repo.matchesFetched, ['collab-c1']);
      expect(find.text('서로를 골랐어요.'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('닫기'));
      await tester.pumpAndSettle();

      // 03을 연 토스트가 있던 발견 화면으로 돌아간다.
      expect(find.text('go interests'), findsOneWidget);
      expect(find.text('서로를 골랐어요.'), findsNothing);
    });

    testWidgets('the creator side opens the same sheet', (tester) async {
      final repo = FakeInterestsRepository(
        cards: [campaignCard('k1', name: '모아 스튜디오')],
        match: matchInfo(isBrand: false),
      );
      await _pump(tester, repo, isBrand: false, query: 'match=collab-k1');

      expect(find.text('서로를 골랐어요.'), findsOneWidget);
    });

    testWidgets('a page opened without a screen below goes to discovery on '
        'close', (tester) async {
      final repo = _three()..match = matchInfo();
      await _pump(tester, repo, query: 'match=collab-c1', underHome: false);
      expect(find.text('서로를 골랐어요.'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('닫기'));
      await tester.pumpAndSettle();

      expect(find.text('go interests'), findsOneWidget);
    });

    testWidgets('says so when the match cannot be read', (tester) async {
      final repo = _three()..failMatch = true;
      await _pump(tester, repo, query: 'match=collab-c1');

      expect(find.text('서로를 골랐어요.'), findsNothing);
      expect(find.text('잠시 뒤 다시 시도해 주세요.'), findsOneWidget);
      // 03은 그대로 남아 있다.
      expect(find.text('저장 3'), findsOneWidget);
    });
  });

  testWidgets('the dark theme paints the selected tab with the quiet surface', (
    tester,
  ) async {
    await _pump(tester, _three(), theme: coraDarkTheme);

    final tab = find
        .ancestor(of: find.text('저장 3'), matching: find.byType(DecoratedBox))
        .first;
    final box = tester.widget<DecoratedBox>(tab).decoration as BoxDecoration;
    expect(box.color, CoraColors.dark.quietSelected);
    expect(CoraColors.dark.quietSelected, const Color(0xFF2A2D33));
  });

  testWidgets('a card extra for the detail keeps the card the brand sees', (
    tester,
  ) async {
    Object? extra;
    useCanvasPhone(tester);
    final router = GoRouter(
      initialLocation: AppRoutes.brandInterests,
      routes: [
        GoRoute(
          path: AppRoutes.brandInterests,
          builder: (context, state) => const InterestsPage(isBrand: true),
        ),
        GoRoute(
          path: AppRoutes.brandCreatorPattern,
          builder: (context, state) {
            extra = state.extra;
            return const Scaffold();
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          interestsRepositoryProvider.overrideWithValue(_three()),
          discoveryRepositoryProvider.overrideWithValue(
            FakeDiscoveryRepository(),
          ),
        ],
        child: MaterialApp.router(routerConfig: router, theme: coraLightTheme),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('민의 옷장 기록'));
    await tester.pumpAndSettle();

    expect(extra, isA<CreatorCard>());
    expect((extra! as CreatorCard).creatorId, 'c2');
    expect((extra! as CreatorCard).displayName, '민의 옷장 기록');
  });
}
