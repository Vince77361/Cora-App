import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/core/ui/cora_bottom_nav.dart';
import 'package:cora/core/ui/cora_state_view.dart';
import 'package:cora/features/offer_terms/domain/offer_terms.dart';
import 'package:cora/features/offers/presentation/pages/send_offer_page.dart';
import 'package:cora/features/proposals/domain/proposal.dart';
import 'package:cora/features/proposals/domain/proposal_repository.dart';
import 'package:cora/features/store_interests/domain/store_interests_repository.dart';
import 'package:cora/features/store_interests/presentation/pages/store_interests_page.dart';
import 'package:cora/features/store_interests/presentation/viewmodels/store_interests_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../proposals/fake_proposal_repository.dart';
import 'fake_store_interests_repository.dart';

/// 위치와 `extra`를 기록하는 라우터. 저장함을 `/store/interests`에 올리고 나머지 경로는 위치 글자만 보이는
/// 빈 화면이다. 둘러보기(`/store/discover`)를 맨 아래에 깔아 뒤로 가기를 시험한다.
Future<({List<String> opened, List<Object?> extras, GoRouter router})> _pump(
  WidgetTester tester, {
  FakeStoreInterestsRepository? interests,
  FakeProposalRepository? proposals,
  String? query,
  ThemeData? theme,
  bool smallPhoneLargeText = false,
}) async {
  if (smallPhoneLargeText) {
    useSmallPhoneWithLargeText(tester);
  } else {
    useCanvasPhone(tester);
  }
  final opened = <String>[];
  final extras = <Object?>[];
  Widget stub(GoRouterState state) {
    opened.add(state.uri.toString());
    extras.add(state.extra);
    return Scaffold(body: Text('opened ${state.uri}'));
  }

  final router = GoRouter(
    initialLocation: AppRoutes.storeDiscover,
    routes: [
      GoRoute(
        path: AppRoutes.storeDiscover,
        builder: (context, state) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => context.push(
                '${AppRoutes.storeInterests}${query == null ? '' : '?$query'}',
              ),
              child: const Text('go saved box'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.storeInterests,
        builder: (context, state) => StoreInterestsPage(
          initialTab: StoreInterestTab.fromQuery(
            state.uri.queryParameters[AppRoutes.tabParam],
          ),
        ),
      ),
      for (final path in [
        '/store/offers/new/:creatorId',
        AppRoutes.storeProposalPattern,
        '/store/coming-soon/:title',
        AppRoutes.store,
        AppRoutes.chats,
        AppRoutes.storeProposals,
        AppRoutes.storeDrafts,
      ])
        GoRoute(path: path, builder: (context, state) => stub(state)),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        storeInterestsRepositoryProvider.overrideWithValue(
          interests ?? _board(),
        ),
        proposalRepositoryProvider.overrideWithValue(proposals ?? _offers()),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: theme ?? coraLightTheme,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('go saved box'));
  await tester.pumpAndSettle();
  return (opened: opened, extras: extras, router: router);
}

/// 캔버스 M19G2TabsB의 견본: 저장 셋, 보낸 관심 둘(서로 관심 하나, 응답 대기 하나).
FakeStoreInterestsRepository _board() => FakeStoreInterestsRepository(
  saved: [
    storeInterest(
      'c1',
      name: '서윤의 작은 취향',
      shortName: '서윤',
      contentFocus: '일상형 릴스',
      followers: 3100,
    ),
    storeInterest(
      'c2',
      name: '면치기 일기',
      contentFocus: '라멘 리뷰',
      followers: 12000,
    ),
    storeInterest('c3', name: '혼밥 연구소', contentFocus: '혼밥 릴스', followers: 3300),
  ],
  sent: [
    storeInterest('c4', name: '하루 한 컵', mutual: true, followers: 640),
    storeInterest('c5', name: '성수 한 끼', contentFocus: '맛집 릴스', followers: 4800),
  ],
);

/// 보낸 제안 둘: 내가 응답할 차례(역제안)와 상대 대기.
FakeProposalRepository _offers() => FakeProposalRepository(
  active: [
    proposalRow(offerId: 'p1', name: '오늘의 한 그릇', format: ContentFormat.reels),
    proposalRow(
      offerId: 'p2',
      name: '맛집 산책',
      group: ProposalGroup.waiting,
      counter: false,
      version: 1,
      format: ContentFormat.reels,
      daysLeft: 2,
    ),
  ],
);

Future<void> _tab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('shows three tabs with counts: 저장, 보낸 관심, 보낸 제안', (tester) async {
    await _pump(tester);

    expect(find.text('저장함'), findsOneWidget);
    expect(find.text('저장은 나만 보고, 하트는 상대에게 전해져요.'), findsOneWidget);
    expect(find.text('저장 3'), findsOneWidget);
    expect(find.text('보낸 관심 2'), findsOneWidget);
    expect(find.text('보낸 제안 2'), findsOneWidget);
    // 옛 탭 글자는 없다.
    expect(find.textContaining('보류'), findsNothing);
    expect(find.textContaining('관심·보류'), findsNothing);
  });

  testWidgets('lists only saved creators in the first tab with a 제안하기 '
      'button', (tester) async {
    await _pump(tester);

    expect(find.text('서윤의 작은 취향'), findsOneWidget);
    expect(find.text('면치기 일기'), findsOneWidget);
    expect(find.text('혼밥 연구소'), findsOneWidget);
    expect(find.text('일상형 릴스, 팔로워 3,100명'), findsOneWidget);
    expect(find.text('라멘 리뷰, 팔로워 1.2만명'), findsOneWidget);
    expect(find.text('제안하기'), findsNWidgets(3));
    // 보낸 관심의 사람은 이 탭에 없다.
    expect(find.text('하루 한 컵'), findsNothing);
    expect(find.text('서로 관심'), findsNothing);
    expect(find.text('응답 대기'), findsNothing);
  });

  testWidgets('marks a mutual row with 서로 관심 and a waiting row with 응답 대기 '
      'and 프로필', (tester) async {
    await _pump(tester);
    await _tab(tester, '보낸 관심 2');

    expect(find.text('하루 한 컵'), findsOneWidget);
    expect(find.text('서로 관심'), findsOneWidget);
    expect(find.text('제안하기'), findsOneWidget);
    expect(find.text('성수 한 끼'), findsOneWidget);
    expect(find.text('응답 대기'), findsOneWidget);
    expect(find.text('프로필'), findsOneWidget);
    // 저장 탭의 사람은 이 탭에 없다.
    expect(find.text('서윤의 작은 취향'), findsNothing);
  });

  testWidgets('shows 응답하기 for a counter proposal on my turn and 대기 '
      'otherwise', (tester) async {
    final shown = await _pump(tester);
    await _tab(tester, '보낸 제안 2');

    expect(find.text('오늘의 한 그릇'), findsOneWidget);
    expect(find.text('역제안 · 판본 2 · 릴스 1편'), findsOneWidget);
    expect(find.text('응답하기'), findsOneWidget);
    expect(find.text('맛집 산책'), findsOneWidget);
    expect(find.text('판본 1 · 릴스 1편 · 2일 안에 답이 와요'), findsOneWidget);
    expect(find.text('대기'), findsOneWidget);

    await tester.tap(find.text('맛집 산책'));
    await tester.pumpAndSettle();
    expect(shown.opened.last, '/store/proposals/p2');
  });

  testWidgets('opens the offer form with the creator as receiver', (
    tester,
  ) async {
    final shown = await _pump(tester);

    await tester.tap(find.text('제안하기').first);
    await tester.pumpAndSettle();

    expect(shown.opened.last, '/store/offers/new/c1');
    final args = shown.extras.last! as SendOfferArgs;
    expect(args.creator!.userId, 'c1');
    expect(args.creator!.displayName, '서윤의 작은 취향');
    expect(args.creator!.contentFocus, '일상형 릴스');
  });

  testWidgets('opens the offer form from a mutual row in the sent tab', (
    tester,
  ) async {
    final shown = await _pump(tester);
    await _tab(tester, '보낸 관심 2');

    await tester.tap(find.text('제안하기'));
    await tester.pumpAndSettle();

    expect(shown.opened.last, '/store/offers/new/c4');
  });

  testWidgets('opens the creator profile from a row and from 프로필', (
    tester,
  ) async {
    final shown = await _pump(tester);

    await tester.tap(find.text('면치기 일기'));
    await tester.pumpAndSettle();
    expect(shown.opened.last, startsWith('/store/coming-soon/'));
    shown.router.pop();
    await tester.pumpAndSettle();

    await _tab(tester, '보낸 관심 2');
    shown.opened.clear();
    await tester.tap(find.text('프로필'));
    await tester.pumpAndSettle();
    expect(shown.opened.last, startsWith('/store/coming-soon/'));
  });

  testWidgets('opens the tab named in the link', (tester) async {
    await _pump(tester, query: 'tab=sent');
    expect(find.text('성수 한 끼'), findsOneWidget);
    expect(find.text('서윤의 작은 취향'), findsNothing);
  });

  testWidgets('opens the proposals tab from ?tab=offers', (tester) async {
    await _pump(tester, query: 'tab=offers');
    expect(find.text('오늘의 한 그릇'), findsOneWidget);
  });

  testWidgets('shows the empty sentence per tab', (tester) async {
    final shown = await _pump(
      tester,
      interests: FakeStoreInterestsRepository(),
      proposals: FakeProposalRepository(),
    );

    expect(find.text('아직 저장한 후보가 없어요.'), findsOneWidget);
    expect(find.text('카드를 위로 밀거나 저장 버튼을 눌러 보세요.'), findsOneWidget);
    await tester.tap(find.text('전체 둘러보기'));
    await tester.pumpAndSettle();
    expect(
      shown.router.routerDelegate.currentConfiguration.uri.path,
      AppRoutes.storeDiscover,
    );
    shown.router.pop();
    await tester.pumpAndSettle();

    await _tab(tester, '보낸 관심 0');
    expect(find.text('아직 보낸 하트가 없어요.'), findsOneWidget);
    expect(find.text('카드를 오른쪽으로 밀거나 하트 버튼을 눌러 보세요.'), findsOneWidget);

    await _tab(tester, '보낸 제안 0');
    expect(find.text('아직 보낸 제안이 없어요.'), findsOneWidget);
    expect(find.text('마음에 드는 크리에이터에게 제안해 보세요.'), findsOneWidget);
  });

  testWidgets('shows a retry when the lists cannot be read', (tester) async {
    final repo = _board()..failFetch = true;
    await _pump(tester, interests: repo);

    expect(find.byType(CoraStateView), findsOneWidget);
    expect(find.text('저장함을 불러오지 못했어요'), findsOneWidget);
    repo.failFetch = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('서윤의 작은 취향'), findsOneWidget);
  });

  testWidgets(
    'still shows the saved and sent tabs when only the sent proposals '
    'cannot be read, and retries just that tab',
    (tester) async {
      final interests = _board();
      final proposals = _offers()..failFetch = true;
      await _pump(tester, interests: interests, proposals: proposals);

      // 저장과 보낸 관심은 그대로 보인다. 제안 수만 0이다.
      expect(find.text('서윤의 작은 취향'), findsOneWidget);
      expect(find.text('저장 3'), findsOneWidget);
      expect(find.text('보낸 관심 2'), findsOneWidget);
      expect(find.text('보낸 제안 0'), findsOneWidget);
      await _tab(tester, '보낸 관심 2');
      expect(find.text('하루 한 컵'), findsOneWidget);

      await _tab(tester, '보낸 제안 0');
      expect(find.text('보낸 제안을 불러오지 못했어요'), findsOneWidget);
      final savedCalls = interests.savedCalls;
      proposals.failFetch = false;
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();

      expect(find.text('오늘의 한 그릇'), findsOneWidget);
      expect(find.text('보낸 제안 2'), findsOneWidget);
      // 제안만 다시 읽는다.
      expect(interests.savedCalls, savedCalls);
    },
  );

  testWidgets('keeps 찾기 highlighted in the menu and goes back', (tester) async {
    final shown = await _pump(tester);

    final nav = tester.widget<CoraBottomNav>(find.byType(CoraBottomNav));
    expect(nav.currentIndex, 1);
    await tester.tap(find.text('홈'));
    await tester.pumpAndSettle();
    expect(shown.opened.last, AppRoutes.store);
  });

  testWidgets('goes back to the screen below with the back button', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.bySemanticsLabel('뒤로'));
    await tester.pumpAndSettle();

    expect(find.text('go saved box'), findsOneWidget);
  });

  testWidgets('exposes the saved count for the header badge', (tester) async {
    await _pump(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(StoreInterestsPage)),
    );
    final count = container.listen(storeSavedCountProvider, (_, _) {});
    await tester.pumpAndSettle();

    expect(count.read(), 3);
  });

  group('look', () {
    testWidgets('uses the canvas tokens in light mode', (tester) async {
      await _pump(tester);
      final c = coraLightTheme.extension<CoraColors>()!;

      expect(_tabBackground(tester, '저장 3'), c.notifyTabSelected);
      expect(_tabBackground(tester, '보낸 관심 2'), c.surface);
    });

    testWidgets('uses dark tokens in dark mode', (tester) async {
      await _pump(tester, theme: coraDarkTheme);
      final c = coraDarkTheme.extension<CoraColors>()!;

      expect(_tabBackground(tester, '저장 3'), c.notifyTabSelected);
      expect(_tabBackground(tester, '보낸 관심 2'), c.surface);
      expect(
        tester
            .widget<Text>(find.text('저장은 나만 보고, 하트는 상대에게 전해져요.'))
            .style!
            .color,
        c.textSecondary,
      );
    });

    // Ruling T9-1: 저장 줄의 `제안하기`는 캔버스(`.cta.subtle`)대로 약한 색이고, 응답할 차례인 제안 줄의
    // `응답하기`만 형광이다. 라이트와 다크 모두 고정한다.
    for (final (name, theme) in [
      ('light', coraLightTheme),
      ('dark', coraDarkTheme),
    ]) {
      testWidgets('keeps 제안하기 quiet and 응답하기 highlighted in $name mode', (
        tester,
      ) async {
        await _pump(tester, theme: theme);
        final c = theme.extension<CoraColors>()!;

        expect(_buttonBackground(tester, '제안하기'), c.surface);
        expect(_buttonText(tester, '제안하기').color, c.text);

        await _tab(tester, '보낸 제안 2');
        expect(_buttonBackground(tester, '응답하기'), c.highlightAction);
        expect(_buttonText(tester, '응답하기').color, c.onHighlightAction);
        expect(_buttonBackground(tester, '대기'), c.surface);
      });
    }

    testWidgets('does not overflow at 1.3x with long names', (tester) async {
      final repo = FakeStoreInterestsRepository(
        saved: [
          storeInterest(
            'c1',
            name: '아주아주 긴 활동 이름을 가진 크리에이터의 작은 취향 기록장',
            contentFocus: '일상형 릴스와 맛집 리뷰와 라멘 기록',
            followers: 1234567,
          ),
        ],
        sent: [
          storeInterest(
            'c2',
            name: '아주아주 긴 활동 이름을 가진 크리에이터의 작은 취향 기록장',
            mutual: true,
          ),
        ],
      );
      await _pump(tester, interests: repo, smallPhoneLargeText: true);
      expect(tester.takeException(), isNull);

      await _tab(tester, '보낸 관심 1');
      expect(tester.takeException(), isNull);
      await _tab(tester, '보낸 제안 2');
      expect(tester.takeException(), isNull);
    });
  });
}

Color? _tabBackground(WidgetTester tester, String label) {
  final box = tester.widget<DecoratedBox>(
    find
        .ancestor(of: find.text(label), matching: find.byType(DecoratedBox))
        .first,
  );
  return (box.decoration as BoxDecoration).color;
}

Color? _buttonBackground(WidgetTester tester, String label) {
  final box = tester.widget<DecoratedBox>(
    find
        .ancestor(of: find.text(label), matching: find.byType(DecoratedBox))
        .first,
  );
  return (box.decoration as BoxDecoration).color;
}

TextStyle _buttonText(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label).first).style!;
