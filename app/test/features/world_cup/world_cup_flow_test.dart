import 'dart:math';

import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/core/ui/swipe_deck/swipe_physics.dart' show SwipeOutcome;
import 'package:cora/features/brand_onboarding/domain/brand_repository.dart';
import 'package:cora/features/brand_onboarding/domain/campaign_repository.dart';
import 'package:cora/features/discovery/domain/discovery_repository.dart';
import 'package:cora/features/discovery/domain/discovery_target.dart';
import 'package:cora/features/interests/domain/interest_card.dart';
import 'package:cora/features/interests/domain/interests_repository.dart';
import 'package:cora/features/interests/presentation/pages/interests_page.dart';
import 'package:cora/features/offers/presentation/pages/send_offer_page.dart';
import 'package:cora/features/proposals/domain/proposal_repository.dart';
import 'package:cora/features/server_config/domain/server_config_repository.dart';
import 'package:cora/features/store_interests/domain/store_interest.dart';
import 'package:cora/features/store_interests/domain/store_interests_repository.dart';
import 'package:cora/features/store_interests/presentation/pages/store_interests_page.dart';
import 'package:cora/features/world_cup/presentation/pages/world_cup_match_page.dart';
import 'package:cora/features/world_cup/presentation/pages/world_cup_result_page.dart';
import 'package:cora/features/world_cup/presentation/viewmodels/world_cup_view_model.dart';
import 'package:cora/features/world_cup/presentation/widgets/world_cup_card.dart';
import 'package:cora/features/world_cup/presentation/world_cup_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../brand_onboarding/fake_brand_repository.dart';
import '../brand_onboarding/fake_campaign_repository.dart';
import '../discovery/fake_discovery_repository.dart';
import '../interests/fake_interests_repository.dart';
import '../proposals/fake_proposal_repository.dart';
import '../server_config/fake_server_config_repository.dart';
import '../store_interests/fake_store_interests_repository.dart';

GoRoute _worldCupMatch() => GoRoute(
  path: AppRoutes.worldCupMatch,
  builder: (context, state) =>
      WorldCupMatchPage(args: state.extra! as WorldCupMatchArgs),
);

GoRoute _worldCupResult() => GoRoute(
  path: AppRoutes.worldCupResult,
  builder: (context, state) =>
      WorldCupResultPage(args: state.extra! as WorldCupResultArgs),
);

Future<void> _pickFirst(WidgetTester tester, int times) async {
  for (var i = 0; i < times; i++) {
    await tester.tap(find.byType(WorldCupCard).first);
    await tester.pumpAndSettle();
  }
}

void main() {
  setUpAll(loadAppFonts);

  group('store world cup flow', () {
    late FakeStoreInterestsRepository interests;
    late FakeProposalRepository proposals;
    late List<({String uri, Object? extra})> opened;

    Future<void> pump(
      WidgetTester tester, {
      int saved = 8,
      List<StoreInterest>? list,
    }) async {
      useCanvasPhone(tester);
      opened = [];
      interests = FakeStoreInterestsRepository(
        saved:
            list ??
            [
              for (var i = 1; i <= saved; i++)
                storeInterest(
                  'c$i',
                  name: '크리에이터 $i',
                  contentFocus: '리빙 릴스',
                  followers: 100 * i,
                ),
            ],
      );
      proposals = FakeProposalRepository();
      final router = GoRouter(
        initialLocation: AppRoutes.storeInterests,
        routes: [
          GoRoute(
            path: AppRoutes.storeInterests,
            builder: (context, state) => const StoreInterestsPage(),
          ),
          GoRoute(
            path: AppRoutes.storeDiscover,
            builder: (context, state) => const Scaffold(),
          ),
          _worldCupMatch(),
          _worldCupResult(),
          GoRoute(
            path: '/store/offers/new/:creatorId',
            builder: (context, state) {
              opened.add((uri: state.uri.toString(), extra: state.extra));
              return const Scaffold(body: Text('offer form'));
            },
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storeInterestsRepositoryProvider.overrideWithValue(interests),
            proposalRepositoryProvider.overrideWithValue(proposals),
            worldCupRandomProvider.overrideWithValue(Random(11)),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            theme: coraLightTheme,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('plays an 8강 world cup and proposes to the champion with the '
        'creator filled in', (tester) async {
      await pump(tester);
      await tester.tap(find.text('월드컵 하기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('8강'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('시작하기'));
      await tester.pumpAndSettle();
      expect(find.text('8강 · 1 / 4'), findsOneWidget);

      await _pickFirst(tester, 7);
      expect(find.text('이상형 1위'), findsOneWidget);
      final champion = tester
          .widget<WorldCupCard>(find.byType(WorldCupCard))
          .candidate;

      await tester.tap(find.text('제안하기'));
      await tester.pumpAndSettle();
      expect(opened, hasLength(1));
      expect(opened.single.uri, AppRoutes.storeOfferNew(champion.id));
      final args = opened.single.extra! as SendOfferArgs;
      expect(args.creator!.userId, champion.id);
      expect(args.creator!.displayName, champion.name);
    });

    testWidgets('shows the first featured post line and photo on the cards '
        'when the creator has one', (tester) async {
      await pump(
        tester,
        list: [
          for (var i = 1; i <= 4; i++)
            storeInterest(
              'c$i',
              name: '크리에이터 $i',
              contentFocus: '리빙 릴스',
              followers: 100 * i,
              photoUrl: 'https://x/profile-$i.jpg',
              headline: '대표 한 줄 $i',
              representativePhotoUrl: 'https://x/first-$i.jpg',
            ),
        ],
      );
      await tester.tap(find.text('월드컵 하기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('시작하기'));
      await tester.pumpAndSettle();

      final cards = tester
          .widgetList<WorldCupCard>(find.byType(WorldCupCard))
          .map((w) => w.candidate)
          .toList();
      expect(cards, hasLength(2));
      for (final c in cards) {
        final n = c.id.substring(1);
        expect(c.headline, '대표 한 줄 $n');
        // 사진은 프로필 사진이 아니라 대표 게시물 1번이다.
        expect(c.photoUrl, 'https://x/first-$n.jpg');
        expect(find.text('대표 한 줄 $n'), findsOneWidget);
        // 활동 이름은 작은 글자로 한 줄 위에 보인다.
        expect(find.text(c.name), findsOneWidget);
      }
    });

    testWidgets('shows the creator name as the big line and falls back to the '
        'profile photo when there is no featured post', (tester) async {
      await pump(
        tester,
        list: [
          for (var i = 1; i <= 4; i++)
            storeInterest(
              'c$i',
              name: '크리에이터 $i',
              contentFocus: '리빙 릴스',
              followers: 100 * i,
              photoUrl: 'https://x/profile-$i.jpg',
            ),
        ],
      );
      await tester.tap(find.text('월드컵 하기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('시작하기'));
      await tester.pumpAndSettle();

      final cards = tester
          .widgetList<WorldCupCard>(find.byType(WorldCupCard))
          .map((w) => w.candidate)
          .toList();
      expect(cards, hasLength(2));
      for (final c in cards) {
        expect(c.headline, isNull);
        expect(c.photoUrl, 'https://x/profile-${c.id.substring(1)}.jpg');
        // 한 줄이 없으면 활동 이름이 큰 글자 하나로만 나온다.
        expect(find.text(c.name), findsOneWidget);
      }
    });

    testWidgets('writes nothing to the server and reads the box only once', (
      tester,
    ) async {
      await pump(tester, saved: 5);
      final readsBefore = interests.savedCalls;
      await tester.tap(find.text('월드컵 하기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('시작하기'));
      await tester.pumpAndSettle();
      await _pickFirst(tester, 3);
      expect(find.text('이상형 1위'), findsOneWidget);
      await tester.tap(find.text('다시 하기'));
      await tester.pumpAndSettle();
      await _pickFirst(tester, 3);
      await tester.tap(find.bySemanticsLabel('닫기'));
      await tester.pumpAndSettle();

      // 월드컵은 저장 목록을 다시 읽지도 않고, 제안함 쪽에 아무것도 쓰지 않는다.
      expect(interests.savedCalls, readsBefore);
      expect(proposals.accepted, isEmpty);
      expect(proposals.endedWith, isEmpty);
      expect(proposals.replies, isEmpty);
      expect(proposals.cancelled, isEmpty);
      expect(opened, isEmpty);
      // 저장함으로 돌아왔고 저장 수는 그대로다.
      expect(find.text('저장 5'), findsOneWidget);
    });

    testWidgets('returns to the saved box without a result when 그만하기', (
      tester,
    ) async {
      await pump(tester, saved: 4);
      await tester.tap(find.text('월드컵 하기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('시작하기'));
      await tester.pumpAndSettle();
      await _pickFirst(tester, 1);
      await tester.tap(find.bySemanticsLabel('그만하기'));
      await tester.pumpAndSettle();
      expect(find.text('저장 4'), findsOneWidget);
      expect(find.text('이상형 1위'), findsNothing);
      expect(find.text('이상형 월드컵'), findsOneWidget); // 배너 제목만 남는다.
    });

    testWidgets('keeps the drawn people when the saved box changes meanwhile', (
      tester,
    ) async {
      await pump(tester, saved: 4);
      await tester.tap(find.text('월드컵 하기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('시작하기'));
      await tester.pumpAndSettle();
      // 다른 기기에서 저장을 빼도 이미 뽑은 사람으로 끝까지 한다.
      interests.saved = [];
      await _pickFirst(tester, 3);
      expect(find.text('이상형 1위'), findsOneWidget);
    });
  });

  group('brand world cup flow', () {
    late FakeInterestsRepository repo;
    late FakeDiscoveryRepository discovery;

    Future<void> pump(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1170, 3600);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      repo = FakeInterestsRepository(
        cards: [
          for (var i = 1; i <= 5; i++)
            brandCard(
              'h$i',
              name: '저장 $i',
              state: InterestState.held,
              headline: '한 줄 $i',
            ),
        ],
      );
      discovery = FakeDiscoveryRepository();
      final router = GoRouter(
        initialLocation: AppRoutes.brandInterests,
        routes: [
          GoRoute(
            path: AppRoutes.brandInterests,
            builder: (context, state) => InterestsPage(
              isBrand: true,
              matchId: state.uri.queryParameters['match'],
            ),
          ),
          _worldCupMatch(),
          _worldCupResult(),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            interestsRepositoryProvider.overrideWithValue(repo),
            discoveryRepositoryProvider.overrideWithValue(discovery),
            campaignRepositoryProvider.overrideWithValue(
              FakeCampaignRepository(active: defaultCampaign),
            ),
            brandRepositoryProvider.overrideWithValue(
              FakeBrandRepository(profile: defaultBrandProfile),
            ),
            serverConfigRepositoryProvider.overrideWithValue(
              FakeServerConfigRepository(),
            ),
            worldCupRandomProvider.overrideWithValue(Random(4)),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            theme: coraLightTheme,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('plays the world cup, writes nothing, then proposes to the '
        'champion through the reward flow', (tester) async {
      await pump(tester);
      expect(find.text('저장한 5명 중 한 명을 골라요'), findsOneWidget);
      await tester.tap(find.text('월드컵 하기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('시작하기'));
      await tester.pumpAndSettle();
      await _pickFirst(tester, 3);

      final champion = tester
          .widget<WorldCupCard>(find.byType(WorldCupCard))
          .candidate;
      expect(champion.headline, startsWith('한 줄'));
      // 제안하기 전에는 서버에 쓴 것이 없다.
      expect(discovery.decisions, isEmpty);
      expect(repo.proposed, isEmpty);

      await tester.tap(find.text('제안하기'));
      await tester.pumpAndSettle();
      expect(find.text('1 / 2'), findsOneWidget); // F1
      await tester.tap(find.text('검토하고 보내기'));
      await tester.pumpAndSettle();
      expect(find.text('2 / 2'), findsOneWidget); // F2
      await tester.tap(find.text('이 조건으로 보내기'));
      await tester.pumpAndSettle();

      final sent = discovery.decisions.single;
      expect(sent.target, DiscoveryTarget.creator(champion.id));
      expect(sent.outcome, SwipeOutcome.like);
      // 보낸 뒤 결과 화면에 04와 같은 안내가 뜬다.
      expect(find.text('이상형 1위'), findsOneWidget);
      expect(
        find.text('${champion.name}에게 제안을 보냈어요. 상대도 고르면 알려드려요.'),
        findsOneWidget,
      );
    });
  });
}
