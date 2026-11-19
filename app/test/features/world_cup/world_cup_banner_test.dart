import 'dart:math';

import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/features/discovery/domain/discovery_repository.dart';
import 'package:cora/features/interests/domain/interest_card.dart';
import 'package:cora/features/interests/domain/interests_repository.dart';
import 'package:cora/features/interests/presentation/pages/interests_page.dart';
import 'package:cora/features/interests/presentation/viewmodels/interests_view_model.dart'
    show InterestTab;
import 'package:cora/features/proposals/domain/proposal_repository.dart';
import 'package:cora/features/store_interests/domain/store_interests_repository.dart';
import 'package:cora/features/store_interests/presentation/pages/store_interests_page.dart';
import 'package:cora/features/store_interests/presentation/viewmodels/store_interests_view_model.dart'
    show StoreInterestTab;
import 'package:cora/features/world_cup/presentation/viewmodels/world_cup_view_model.dart';
import 'package:cora/features/world_cup/presentation/widgets/world_cup_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../discovery/fake_discovery_repository.dart';
import '../interests/fake_interests_repository.dart';
import '../proposals/fake_proposal_repository.dart';
import '../store_interests/fake_store_interests_repository.dart';

Future<void> _pumpBanner(
  WidgetTester tester, {
  int saved = 8,
  VoidCallback? onStart,
  ThemeData? theme,
  bool smallPhoneLargeText = false,
}) async {
  if (smallPhoneLargeText) {
    useSmallPhoneWithLargeText(tester);
  } else {
    useCanvasPhone(tester);
  }
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? coraLightTheme,
      home: Scaffold(
        body: Center(
          child: WorldCupBanner(savedCount: saved, onStart: onStart ?? () {}),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 사장님 저장함을 `/store/interests`에 올린다.
Future<void> _pumpStore(
  WidgetTester tester, {
  required int saved,
  int sent = 0,
  String? query,
}) async {
  useCanvasPhone(tester);
  final router = GoRouter(
    initialLocation:
        '${AppRoutes.storeInterests}${query == null ? '' : '?$query'}',
    routes: [
      GoRoute(
        path: AppRoutes.storeInterests,
        builder: (context, state) => StoreInterestsPage(
          initialTab: StoreInterestTab.fromQuery(
            state.uri.queryParameters[AppRoutes.tabParam],
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.storeDiscover,
        builder: (context, state) => const Scaffold(),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        storeInterestsRepositoryProvider.overrideWithValue(
          FakeStoreInterestsRepository(
            saved: [
              for (var i = 1; i <= saved; i++)
                storeInterest('c$i', name: '크리에이터 $i'),
            ],
            sent: [
              for (var i = 1; i <= sent; i++)
                storeInterest('s$i', name: '보낸 $i'),
            ],
          ),
        ),
        proposalRepositoryProvider.overrideWithValue(FakeProposalRepository()),
        worldCupRandomProvider.overrideWithValue(Random(1)),
      ],
      child: MaterialApp.router(routerConfig: router, theme: coraLightTheme),
    ),
  );
  await tester.pumpAndSettle();
}

/// 브랜드(또는 크리에이터) 03을 올린다. 저장한 카드가 [held]장, 하트를 보낸 카드가 [waiting]장이다.
Future<void> _pumpInterests(
  WidgetTester tester, {
  required bool isBrand,
  required int held,
  int waiting = 0,
  String? query,
}) async {
  tester.view.physicalSize = const Size(1170, 3600);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final path = isBrand ? AppRoutes.brandInterests : AppRoutes.creatorInterests;
  final router = GoRouter(
    initialLocation: '$path${query == null ? '' : '?$query'}',
    routes: [
      GoRoute(
        path: path,
        builder: (context, state) => InterestsPage(
          isBrand: isBrand,
          initialTab: InterestTab.fromQuery(state.uri.queryParameters['tab']),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  final cards = [
    for (var i = 1; i <= held; i++)
      isBrand
          ? brandCard('h$i', name: '저장 $i', state: InterestState.held)
          : campaignCard('h$i', name: '저장 $i', state: InterestState.held),
    for (var i = 1; i <= waiting; i++)
      isBrand
          ? brandCard('w$i', name: '대기 $i')
          : campaignCard('w$i', name: '대기 $i'),
  ];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        interestsRepositoryProvider.overrideWithValue(
          FakeInterestsRepository(cards: cards),
        ),
        discoveryRepositoryProvider.overrideWithValue(
          FakeDiscoveryRepository(),
        ),
      ],
      child: MaterialApp.router(routerConfig: router, theme: coraLightTheme),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  group('WorldCupBanner', () {
    testWidgets('shows the canvas texts and starts on 월드컵 하기', (tester) async {
      var started = 0;
      await _pumpBanner(tester, saved: 8, onStart: () => started++);
      expect(find.text('이상형 월드컵'), findsOneWidget);
      expect(find.text('저장한 8명 중 한 명을 골라요'), findsOneWidget);
      expect(find.text('월드컵 하기'), findsOneWidget);
      await tester.tap(find.text('월드컵 하기'));
      expect(started, 1);
    });

    testWidgets('uses the canvas tokens in light and dark mode', (
      tester,
    ) async {
      for (final theme in [coraLightTheme, coraDarkTheme]) {
        await _pumpBanner(tester, theme: theme);
        final c = theme.extension<CoraColors>()!;
        final box = tester.widget<DecoratedBox>(
          find
              .ancestor(
                of: find.text('이상형 월드컵'),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        expect((box.decoration as BoxDecoration).color, c.surface);
        expect(
          tester.widget<Text>(find.text('저장한 8명 중 한 명을 골라요')).style?.color,
          c.textSecondary,
        );
      }
    });

    testWidgets('does not overflow at 1.3x', (tester) async {
      await _pumpBanner(tester, saved: 128, smallPhoneLargeText: true);
      expect(tester.takeException(), isNull);
    });
  });

  group('banner placement', () {
    testWidgets('shows the banner only with four or more saved (store)', (
      tester,
    ) async {
      await _pumpStore(tester, saved: 3);
      expect(find.byType(WorldCupBanner), findsNothing);
      expect(find.text('이상형 월드컵'), findsNothing);
    });

    testWidgets(
      'shows the banner above the saved list with four saved (store)',
      (tester) async {
        await _pumpStore(tester, saved: 4);
        expect(find.byType(WorldCupBanner), findsOneWidget);
        expect(find.text('저장한 4명 중 한 명을 골라요'), findsOneWidget);
        // 목록 위에 있다.
        expect(
          tester.getTopLeft(find.byType(WorldCupBanner)).dy,
          lessThan(tester.getTopLeft(find.text('크리에이터 1')).dy),
        );
      },
    );

    testWidgets('shows the banner only on the 저장 tab (store)', (tester) async {
      await _pumpStore(tester, saved: 5, sent: 2);
      expect(find.byType(WorldCupBanner), findsOneWidget);
      await tester.tap(find.text('보낸 관심 2'));
      await tester.pumpAndSettle();
      expect(find.byType(WorldCupBanner), findsNothing);
    });

    testWidgets('opens the count sheet from 월드컵 하기 (store)', (tester) async {
      await _pumpStore(tester, saved: 8);
      await tester.tap(find.text('월드컵 하기'));
      await tester.pumpAndSettle();
      expect(find.text('몇 강으로 할까요?'), findsOneWidget);
      expect(find.text('저장한 8명 중에서 골라요. 우승한 분께 바로 제안할 수 있어요.'), findsOneWidget);
    });

    testWidgets('shows the banner only with four or more saved (brand)', (
      tester,
    ) async {
      await _pumpInterests(tester, isBrand: true, held: 3, waiting: 2);
      expect(find.byType(WorldCupBanner), findsNothing);
    });

    testWidgets('shows the banner on the brand 저장 tab only', (tester) async {
      await _pumpInterests(tester, isBrand: true, held: 4, waiting: 2);
      expect(find.byType(WorldCupBanner), findsOneWidget);
      expect(find.text('저장한 4명 중 한 명을 골라요'), findsOneWidget);
      await tester.tap(find.text('보낸 관심 2'));
      await tester.pumpAndSettle();
      expect(find.byType(WorldCupBanner), findsNothing);
    });

    testWidgets('never shows the banner to a creator', (tester) async {
      await _pumpInterests(tester, isBrand: false, held: 6);
      expect(find.byType(WorldCupBanner), findsNothing);
    });
  });
}
