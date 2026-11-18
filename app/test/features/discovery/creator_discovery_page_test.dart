import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/core/theme/cora_swipe_tokens.dart';
import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/core/ui/cora_bottom_nav.dart';
import 'package:cora/core/ui/cora_state_view.dart';
import 'package:cora/core/ui/swipe_deck/swipe_physics.dart' show SwipeOutcome;
import 'package:cora/features/discovery/domain/discovery_repository.dart';
import 'package:cora/features/discovery/domain/discovery_target.dart';
import 'package:cora/features/discovery/domain/pass_reason.dart';
import 'package:cora/features/discovery/presentation/pages/creator_discovery_page.dart';
import 'package:cora/features/discovery/presentation/widgets/discovery_header.dart';
import 'package:cora/features/discovery/presentation/widgets/discovery_toast.dart';
import 'package:cora/features/notifications/domain/notification_repository.dart';
import 'package:cora/features/principles/domain/principles_repository.dart';
import 'package:cora/features/store_browse/domain/store_browse_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../notifications/fake_notification_repository.dart';
import '../principles/fake_principles_repository.dart';
import '../store_browse/fake_store_browse_repository.dart';
import 'fake_discovery_repository.dart';

/// 위치를 기록하는 라우터. 08을 `/creator`에 올리고, 08이 여는 경로는 위치 글자만 보이는 빈 화면으로 둔다.
Future<List<String>> _pump(
  WidgetTester tester,
  FakeDiscoveryRepository repo, {
  FakeStoreBrowseRepository? stores,
  FakePrinciplesRepository? principles,
  ThemeData? theme,
}) async {
  useCanvasPhone(tester);
  final opened = <String>[];
  Widget stub(GoRouterState state) {
    opened.add(state.uri.toString());
    return Scaffold(body: Text('opened ${state.uri}'));
  }

  final router = GoRouter(
    initialLocation: AppRoutes.creator,
    routes: [
      GoRoute(
        path: AppRoutes.creator,
        builder: (context, state) => const CreatorDiscoveryPage(),
      ),
      for (final path in [
        AppRoutes.creatorCampaignPattern,
        '/creator/stores/:id',
        AppRoutes.creatorInterests,
        AppRoutes.creatorPrinciples,
        AppRoutes.creatorOffers,
        '/creator/coming-soon/:title',
        '/notifications',
      ])
        GoRoute(path: path, builder: (context, state) => stub(state)),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        discoveryRepositoryProvider.overrideWithValue(repo),
        storeBrowseRepositoryProvider.overrideWithValue(
          stores ?? FakeStoreBrowseRepository(),
        ),
        principlesRepositoryProvider.overrideWithValue(
          principles ?? FakePrinciplesRepository(principles: defaultPrinciples),
        ),
        notificationRepositoryProvider.overrideWithValue(
          FakeNotificationRepository(),
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

/// 캠페인 카드 둘 사이에 가게 카드가 하나 있는 오늘 목록.
FakeDiscoveryRepository _mixed() => FakeDiscoveryRepository(
  campaignCards: [
    discoveryCampaign('k1'),
    discoveryStore('s1'),
    discoveryCampaign(
      'k2',
      brand: '결 리빙',
      headline: '느린 주말, 향으로 여는 방',
      fee: 400000,
      productProvided: false,
      tags: const ['리빙', '솔직후기'],
    ),
    discoveryCampaign('k3', brand: '오늘의 잔', headline: '하루 한 잔, 손에 맞는 컵'),
  ],
  campaignTotal: 4,
);

Finder _semanticsLabeled(String label) => find.byWidgetPredicate(
  (w) => w is Semantics && w.properties.label == label,
);

final _undoButton = _semanticsLabeled('되돌리기');

Future<void> _swipe(WidgetTester tester, String name, Offset by) async {
  await tester.drag(find.text(name), by);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('shows the badge with spaces around the slash and the card', (
    tester,
  ) async {
    await _pump(tester, _mixed());

    expect(find.text('내 원칙과 맞는 캠페인 1 / 4'), findsOneWidget);
    expect(find.text('모아 스튜디오'), findsOneWidget);
    expect(find.text('나만의 아침 루틴 속 작은 포인트'), findsOneWidget);
    expect(find.text('30만 원 + 제품'), findsOneWidget);
    expect(find.text('#얼굴출연없음'), findsOneWidget);
    expect(find.text('#대본낭독없음'), findsOneWidget);
  });

  testWidgets('mixes campaign and store cards', (tester) async {
    await _pump(tester, _mixed());

    await _swipe(tester, '모아 스튜디오', const Offset(-300, 0));
    expect(find.text('내 원칙과 맞는 캠페인 2 / 4'), findsOneWidget);
    expect(find.text('한그릇 라멘'), findsOneWidget);

    await _swipe(tester, '한그릇 라멘', const Offset(-300, 0));
    // 제작비만 있는 캠페인은 `+ 제품`이 붙지 않는다.
    expect(find.text('결 리빙'), findsOneWidget);
    expect(find.text('40만 원'), findsOneWidget);
    expect(find.text('내 원칙과 맞는 캠페인 3 / 4'), findsOneWidget);
  });

  testWidgets('store cards show the short reward line and the two tags', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeDiscoveryRepository(
        campaignCards: [discoveryStore('s1', otherSido: '부산광역시')],
      ),
    );

    expect(find.text('한그릇 라멘'), findsOneWidget);
    expect(find.text('식사권 + 조회수 수당'), findsOneWidget);
    expect(find.text('#소상공인'), findsOneWidget);
    expect(find.text('#팔로워무관'), findsOneWidget);
    // 내 지역이 아닌 가게는 시·도 표지가 붙는다.
    expect(find.text('부산광역시'), findsOneWidget);
  });

  testWidgets('the header has the logo, the creator pill and the bell', (
    tester,
  ) async {
    final opened = await _pump(tester, _mixed());

    expect(find.text('cora'), findsOneWidget);
    expect(find.text('브랜드'), findsOneWidget);
    expect(find.text('크리에이터'), findsOneWidget);
    // 종은 로고와 알약 사이(오른쪽 묶음의 맨 앞)에 있다.
    final bell = tester.getTopLeft(find.bySemanticsLabel('알림')).dx;
    final pill = tester.getTopLeft(find.text('브랜드')).dx;
    final logo = tester.getTopLeft(find.text('cora')).dx;
    expect(logo < bell && bell < pill, isTrue);

    await tester.tap(find.bySemanticsLabel('알림'));
    await tester.pumpAndSettle();
    expect(opened, ['/notifications']);
  });

  testWidgets('the card has the canvas accessibility label', (tester) async {
    await _pump(tester, _mixed());

    expect(_semanticsLabeled('모아 스튜디오 오퍼 상세 보기'), findsOneWidget);
  });

  testWidgets('the creator pill is the selected cell', (tester) async {
    await _pump(tester, _mixed());

    DecoratedBox cell(String label) => tester.widget<DecoratedBox>(
      find
          .ancestor(of: find.text(label), matching: find.byType(DecoratedBox))
          .first,
    );
    expect((cell('크리에이터').decoration as BoxDecoration).color, Colors.white);
    expect((cell('브랜드').decoration as BoxDecoration).color, isNull);
  });

  testWidgets('the bottom menu has the five creator items with discover on', (
    tester,
  ) async {
    await _pump(tester, _mixed());

    for (final label in ['발견', '관심', '대화', '협업', '프로필']) {
      expect(
        find.descendant(
          of: find.byType(CoraBottomNav),
          matching: find.text(label),
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets('swiping a campaign right sends a like and shows the toast', (
    tester,
  ) async {
    final repo = _mixed();
    final opened = await _pump(tester, repo);

    await _swipe(tester, '모아 스튜디오', const Offset(300, 0));

    expect(repo.decisions.single.outcome, SwipeOutcome.like);
    expect(repo.decisions.single.target, const DiscoveryTarget.campaign('k1'));
    expect(find.text('하트를 보냈어요. 브랜드도 고르면 알려드려요.'), findsOneWidget);

    await tester.tap(find.text('보낸 관심'));
    await tester.pumpAndSettle();
    expect(opened, ['/creator/interests?tab=sent']);
  });

  testWidgets('swiping a campaign left shows the creator pass toast', (
    tester,
  ) async {
    final repo = _mixed();
    await _pump(tester, repo);

    await _swipe(tester, '모아 스튜디오', const Offset(-300, 0));

    expect(repo.decisions.single.outcome, SwipeOutcome.pass);
    expect(find.text('넘겼어요. 브랜드에는 알리지 않아요.'), findsOneWidget);
    expect(find.text('이유 남기기'), findsOneWidget);
  });

  testWidgets(
    'swiping a campaign up holds it and the toast opens the held tab',
    (tester) async {
      final repo = _mixed();
      final opened = await _pump(tester, repo);

      await _swipe(tester, '모아 스튜디오', const Offset(0, -300));

      expect(repo.decisions.single.outcome, SwipeOutcome.hold);
      expect(find.text('저장했어요. 나만 볼 수 있어요.'), findsOneWidget);

      await tester.tap(find.text('저장함'));
      await tester.pumpAndSettle();
      expect(opened, ['/creator/interests?tab=held']);
    },
  );

  testWidgets('a mutual like shows the match toast that opens the match', (
    tester,
  ) async {
    final repo = _mixed()..matchOn.add('k1');
    final opened = await _pump(tester, repo);

    await _swipe(tester, '모아 스튜디오', const Offset(300, 0));

    expect(find.text('모아 스튜디오와 서로 관심이 닿았어요.'), findsOneWidget);
    expect(find.text('하트를 보냈어요. 브랜드도 고르면 알려드려요.'), findsNothing);

    await tester.tap(find.text('확인하기'));
    await tester.pumpAndSettle();
    expect(opened, ['/creator/interests?match=collab-k1']);
  });

  testWidgets('the toast goes away after three seconds', (tester) async {
    await _pump(tester, _mixed());
    await _swipe(tester, '모아 스튜디오', const Offset(300, 0));
    expect(find.text('하트를 보냈어요. 브랜드도 고르면 알려드려요.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    expect(find.text('하트를 보냈어요. 브랜드도 고르면 알려드려요.'), findsNothing);
  });

  group('store cards', () {
    FakeDiscoveryRepository storeFirst() => FakeDiscoveryRepository(
      campaignCards: [discoveryStore('s1'), discoveryCampaign('k1')],
    );

    testWidgets('swiping a store card right applies to the store', (
      tester,
    ) async {
      final repo = storeFirst();
      final stores = FakeStoreBrowseRepository();
      await _pump(tester, repo, stores: stores);

      await _swipe(tester, '한그릇 라멘', const Offset(300, 0));

      // 가게 흐름 개정의 `조건 그대로 지원`과 같은 호출이다. 발견의 결정 저장은 쓰지 않는다.
      expect(stores.applied, ['s1']);
      expect(stores.pitches, [null]);
      expect(repo.decisions, isEmpty);
      expect(find.text('지원했어요. 사장님이 고르면 오퍼가 도착해요.'), findsOneWidget);
      expect(find.text('모아 스튜디오'), findsOneWidget);
    });

    testWidgets('an already applied store leaves the deck on a conflict', (
      tester,
    ) async {
      final stores = FakeStoreBrowseRepository()..conflictOnChange = true;
      await _pump(tester, storeFirst(), stores: stores);

      await _swipe(tester, '한그릇 라멘', const Offset(300, 0));

      expect(find.text('한그릇 라멘'), findsNothing);
      expect(find.text('모아 스튜디오'), findsOneWidget);
      // 지원했다고 말하지 않고 중립 안내 하나만 뜬다.
      expect(find.text('이미 지원한 가게예요.'), findsOneWidget);
      expect(find.text('지원했어요. 사장님이 고르면 오퍼가 도착해요.'), findsNothing);
      expect(find.byType(DiscoveryToastBanner), findsOneWidget);
    });

    testWidgets('undo is off right after applying to a store', (tester) async {
      final repo = FakeDiscoveryRepository(
        campaignCards: [
          discoveryCampaign('k1'),
          discoveryStore('s1'),
          discoveryCampaign('k2'),
        ],
      );
      final stores = FakeStoreBrowseRepository();
      await _pump(tester, repo, stores: stores);

      // 먼저 캠페인을 넘기고, 그 뒤 가게에 지원한다.
      await _swipe(tester, '모아 스튜디오', const Offset(-300, 0));
      await _swipe(tester, '한그릇 라멘', const Offset(300, 0));
      expect(stores.applied, ['s1']);

      // 지원 직후의 되돌리기는 그 전의 넘김을 되살리지 않는다.
      await tester.tap(_undoButton);
      await tester.pumpAndSettle();
      expect(repo.undoCalls, 0);
      expect(repo.decisions, hasLength(1));

      // 다른 결정을 하면 다시 켜진다.
      await _swipe(tester, '모아 스튜디오', const Offset(-300, 0));
      await tester.tap(find.text('마지막 카드 되돌리기'));
      await tester.pumpAndSettle();
      expect(repo.undoCalls, 1);
    });

    testWidgets('a failed apply brings the card back with a notice', (
      tester,
    ) async {
      final stores = FakeStoreBrowseRepository()..failApply = true;
      await _pump(tester, storeFirst(), stores: stores);

      await _swipe(tester, '한그릇 라멘', const Offset(300, 0));

      expect(tester.takeException(), isA<StoreBrowseFailure>());
      expect(find.text('잠시 뒤 다시 시도해 주세요.'), findsOneWidget);
      expect(find.text('한그릇 라멘'), findsOneWidget);
    });

    testWidgets('swiping a store card up snaps back and saves nothing', (
      tester,
    ) async {
      final repo = storeFirst();
      final stores = FakeStoreBrowseRepository();
      await _pump(tester, repo, stores: stores);

      await _swipe(tester, '한그릇 라멘', const Offset(0, -300));

      expect(repo.decisions, isEmpty);
      expect(stores.applied, isEmpty);
      expect(find.text('저장했어요. 나만 볼 수 있어요.'), findsNothing);
      expect(find.text('한그릇 라멘'), findsOneWidget);
      expect(find.text('내 원칙과 맞는 캠페인 1 / 2'), findsOneWidget);

      // 보류 버튼도 같다.
      await tester.tap(find.bySemanticsLabel('저장'));
      await tester.pumpAndSettle();
      expect(repo.decisions, isEmpty);
      expect(find.text('한그릇 라멘'), findsOneWidget);
    });

    testWidgets('passing a store goes to the store pass and opens the reason', (
      tester,
    ) async {
      final repo = storeFirst();
      await _pump(tester, repo);

      await _swipe(tester, '한그릇 라멘', const Offset(-300, 0));

      expect(repo.decisions.single.target, const DiscoveryTarget.store('s1'));
      expect(repo.decisions.single.outcome, SwipeOutcome.pass);
      expect(find.text('넘겼어요. 브랜드에는 알리지 않아요.'), findsOneWidget);

      // 02 시트는 가게를 넘긴 뒤에도 뜬다.
      await tester.tap(find.text('이유 남기기'));
      await tester.pumpAndSettle();
      expect(find.text('넘겼어요. 이유를 남길까요?'), findsOneWidget);
      await tester.tap(find.text('지역·방문이 어려워요'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('이유 남기고 다음 보기'));
      await tester.pumpAndSettle();

      expect(repo.reasons.single.target, const DiscoveryTarget.store('s1'));
      expect(repo.reasons.single.reason, PassReason.region);
    });
  });

  group('principles banner', () {
    testWidgets('shows when no principles are set and opens them', (
      tester,
    ) async {
      final opened = await _pump(
        tester,
        _mixed(),
        principles: FakePrinciplesRepository(),
      );

      expect(find.text('협업 원칙을 정하면 브랜드에게 보여요.'), findsOneWidget);
      // 띠가 있어도 카드는 그대로 보인다.
      expect(find.text('모아 스튜디오'), findsOneWidget);

      await tester.tap(find.text('정하기'));
      await tester.pumpAndSettle();
      expect(opened, ['/creator/principles']);
    });

    testWidgets('is hidden once principles are set', (tester) async {
      await _pump(tester, _mixed());

      expect(find.text('협업 원칙을 정하면 브랜드에게 보여요.'), findsNothing);
    });

    testWidgets('does not block the cards when the principles cannot be read', (
      tester,
    ) async {
      await _pump(
        tester,
        _mixed(),
        principles: FakePrinciplesRepository(principles: defaultPrinciples)
          ..failFetch = true,
      );

      expect(find.text('협업 원칙을 정하면 브랜드에게 보여요.'), findsNothing);
      expect(find.text('모아 스튜디오'), findsOneWidget);
    });
  });

  group('all seen', () {
    testWidgets('shows the shared state with the canvas copy and undo', (
      tester,
    ) async {
      final repo = FakeDiscoveryRepository(campaignTotal: 3);
      final opened = await _pump(tester, repo);

      expect(find.byType(CoraStateView), findsOneWidget);
      expect(find.text('오늘 맞는 캠페인을 모두 봤어요.'), findsOneWidget);
      expect(find.text('협업 원칙을 다듬으면 더 잘 맞는 캠페인이 올라와요.'), findsOneWidget);
      expect(find.text('마지막 카드 되돌리기'), findsOneWidget);

      await tester.tap(find.text('협업 원칙 다듬기'));
      await tester.pumpAndSettle();
      expect(opened, ['/creator/principles']);
    });

    testWidgets('undo brings back the last passed card', (tester) async {
      final repo = FakeDiscoveryRepository(
        campaignCards: [discoveryCampaign('k1')],
      );
      await _pump(tester, repo);
      await _swipe(tester, '모아 스튜디오', const Offset(-300, 0));
      expect(find.text('오늘 맞는 캠페인을 모두 봤어요.'), findsOneWidget);

      await tester.tap(find.text('마지막 카드 되돌리기'));
      await tester.pumpAndSettle();

      expect(find.text('오늘 맞는 캠페인을 모두 봤어요.'), findsNothing);
      expect(find.text('모아 스튜디오'), findsOneWidget);
      expect(find.text('내 원칙과 맞는 캠페인 1 / 1'), findsOneWidget);
    });

    testWidgets('undo says it is too late when nothing can be undone', (
      tester,
    ) async {
      final repo = FakeDiscoveryRepository(campaignTotal: 2)
        ..nothingToUndo = true;
      await _pump(tester, repo);

      await tester.tap(find.text('마지막 카드 되돌리기'));
      await tester.pumpAndSettle();

      expect(find.text('되돌릴 수 없어요. 내일 추천에 다시 나올 수 있어요.'), findsOneWidget);
    });
  });

  testWidgets('tapping a campaign card opens D1 and the photo is a hero', (
    tester,
  ) async {
    final opened = await _pump(tester, _mixed());
    expect(
      find.byWidgetPredicate(
        (w) => w is Hero && w.tag == 'campaign:k1',
        skipOffstage: false,
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('모아 스튜디오'));
    await tester.pumpAndSettle();

    expect(opened, ['/creator/campaigns/k1']);
  });

  testWidgets('tapping a store card opens the store detail', (tester) async {
    final opened = await _pump(
      tester,
      FakeDiscoveryRepository(campaignCards: [discoveryStore('s1')]),
    );

    await tester.tap(find.text('한그릇 라멘'));
    await tester.pumpAndSettle();

    expect(opened, ['/creator/stores/s1']);
  });

  testWidgets('the heart, pass and save buttons decide too', (tester) async {
    final repo = FakeDiscoveryRepository(
      campaignCards: [
        discoveryCampaign('k1'),
        discoveryCampaign('k2'),
        discoveryCampaign('k3'),
      ],
    );
    await _pump(tester, repo);

    await tester.tap(find.bySemanticsLabel('하트'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('넘기기'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('저장'));
    await tester.pumpAndSettle();

    expect(repo.decisions.map((d) => d.outcome), [
      SwipeOutcome.like,
      SwipeOutcome.pass,
      SwipeOutcome.hold,
    ]);
  });

  testWidgets('the card returns when a campaign decision fails', (
    tester,
  ) async {
    final repo = _mixed()..failDecide = true;
    await _pump(tester, repo);

    await _swipe(tester, '모아 스튜디오', const Offset(300, 0));

    expect(tester.takeException(), isA<DiscoveryFailure>());
    expect(find.text('잠시 뒤 다시 시도해 주세요.'), findsOneWidget);
    expect(find.text('내 원칙과 맞는 캠페인 1 / 4'), findsOneWidget);
    expect(repo.decisions, isEmpty);
  });

  testWidgets('shows the empty state when today has no card', (tester) async {
    await _pump(tester, FakeDiscoveryRepository());

    expect(find.text('아직 추천할 캠페인이 없어요.'), findsOneWidget);
  });

  testWidgets('offers a retry when today cannot be loaded', (tester) async {
    final repo = _mixed()..failCampaignFetch = true;
    await _pump(tester, repo);
    expect(find.text('추천을 불러오지 못했어요'), findsOneWidget);

    repo.failCampaignFetch = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('모아 스튜디오'), findsOneWidget);
  });

  testWidgets('uses the 08 dark colors for the toast and the card area', (
    tester,
  ) async {
    await _pump(tester, _mixed(), theme: coraDarkTheme);
    await _swipe(tester, '모아 스튜디오', const Offset(300, 0));

    final toast =
        tester
                .widget<DecoratedBox>(
                  find
                      .descendant(
                        of: find.byType(DiscoveryToastBanner),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration;
    // 08 다크: 바탕 #0F1012, 글자 #F2F3F5, 그림자 rgba(23,24,28,0.16).
    expect(toast.color, const Color(0xFF0F1012));
    expect(toast.boxShadow!.single.color, const Color(0x2917181C));
    final text = tester.widget<Text>(find.text('하트를 보냈어요. 브랜드도 고르면 알려드려요.'));
    expect(text.style!.color, const Color(0xFFF2F3F5));

    final deck = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(CreatorDiscoveryPage),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((b) => b.decoration)
        .whereType<BoxDecoration>()
        .where((d) => d.color == CoraSwipeTokens.creatorBackdropDark);
    expect(deck, isNotEmpty);
    // 하단 메뉴의 고른 탭은 #F2F3F5다.
    expect(CoraColors.dark.navActive, const Color(0xFFF2F3F5));
    expect(find.byType(DiscoveryRolePill), findsOneWidget);
  });

  testWidgets('does not overflow at 1.3x text scale on a small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final router = GoRouter(
      initialLocation: AppRoutes.creator,
      routes: [
        GoRoute(
          path: AppRoutes.creator,
          builder: (context, state) => const CreatorDiscoveryPage(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          discoveryRepositoryProvider.overrideWithValue(
            FakeDiscoveryRepository(
              campaignCards: [discoveryStore('s1', otherSido: '부산광역시')],
            ),
          ),
          storeBrowseRepositoryProvider.overrideWithValue(
            FakeStoreBrowseRepository(),
          ),
          principlesRepositoryProvider.overrideWithValue(
            FakePrinciplesRepository(),
          ),
          notificationRepositoryProvider.overrideWithValue(
            FakeNotificationRepository(),
          ),
        ],
        child: MaterialApp.router(routerConfig: router, theme: coraLightTheme),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('협업 원칙을 정하면 브랜드에게 보여요.'), findsOneWidget);
  });
}
