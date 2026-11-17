import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/core/ui/cora_bottom_nav.dart';
import 'package:cora/core/ui/cora_state_view.dart';
import 'package:cora/core/ui/swipe_deck/swipe_physics.dart' show SwipeOutcome;
import 'package:cora/features/discovery/domain/discovery_repository.dart';
import 'package:cora/features/discovery/domain/pass_reason.dart';
import 'package:cora/features/discovery/presentation/pages/brand_discovery_page.dart';
import 'package:cora/features/discovery/presentation/widgets/discovery_toast.dart';
import 'package:cora/features/notifications/domain/notification_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../notifications/fake_notification_repository.dart';
import 'fake_discovery_repository.dart';

/// 위치를 기록하는 라우터. 01을 `/brand`에 올리고, 01이 여는 경로는 위치 글자만 보이는 빈 화면으로 둔다.
Future<List<String>> _pump(
  WidgetTester tester,
  FakeDiscoveryRepository repo, {
  ThemeData? theme,
}) async {
  useCanvasPhone(tester);
  final opened = <String>[];
  Widget stub(GoRouterState state) {
    opened.add(state.uri.toString());
    return Scaffold(body: Text('opened ${state.uri}'));
  }

  final router = GoRouter(
    initialLocation: AppRoutes.brand,
    routes: [
      GoRoute(
        path: AppRoutes.brand,
        builder: (context, state) => const BrandDiscoveryPage(),
      ),
      GoRoute(
        path: AppRoutes.brandCreatorPattern,
        builder: (context, state) => stub(state),
      ),
      GoRoute(
        path: AppRoutes.brandInterests,
        builder: (context, state) => stub(state),
      ),
      GoRoute(
        path: AppRoutes.brandProfile,
        builder: (context, state) => stub(state),
      ),
      GoRoute(path: '/notifications', builder: (context, state) => stub(state)),
      GoRoute(path: AppRoutes.chats, builder: (context, state) => stub(state)),
      GoRoute(
        path: '/brand/coming-soon/:title',
        builder: (context, state) => stub(state),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        discoveryRepositoryProvider.overrideWithValue(repo),
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

FakeDiscoveryRepository _three() => FakeDiscoveryRepository(
  cards: [
    creatorCard('c1', name: '서윤의 작은 취향'),
    creatorCard(
      'c2',
      name: '민의 옷장 기록',
      headline: '같은 니트, 세 가지 액세서리',
      tags: const ['니트'],
    ),
    creatorCard('c3', name: '하루 한 컵', headline: null, tags: const []),
  ],
);

Future<void> _swipe(WidgetTester tester, String name, Offset by) async {
  await tester.drag(find.text(name), by);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('shows the badge with position and total', (tester) async {
    await _pump(tester, _three());

    expect(find.text('운영자 추천 1 / 3'), findsOneWidget);
    // 뒤 카드도 자기 순번을 달고 있다.
    expect(find.text('운영자 추천 2 / 3', skipOffstage: false), findsOneWidget);
    expect(find.text('서윤의 작은 취향'), findsOneWidget);
    expect(find.text('출근 전 30초, 오늘의 손목 루틴'), findsOneWidget);
    expect(find.text('30만 원대'), findsWidgets);
    expect(find.text('#얼굴출연없음'), findsOneWidget);
    expect(find.text('#소품'), findsOneWidget);
  });

  testWidgets('counts cards already decided earlier today in the position', (
    tester,
  ) async {
    final repo = FakeDiscoveryRepository(
      cards: [creatorCard('c3', name: '하루 한 컵')],
      total: 3,
    );
    await _pump(tester, repo);

    expect(find.text('운영자 추천 3 / 3'), findsOneWidget);
  });

  testWidgets('a card without a headline says it is being prepared', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeDiscoveryRepository(cards: [creatorCard('c1', headline: null)]),
    );

    expect(find.text('대표 콘텐츠를 준비 중이에요'), findsOneWidget);
  });

  testWidgets('the header has the logo, the brand pill and the bell', (
    tester,
  ) async {
    final opened = await _pump(tester, _three());

    expect(find.text('cora'), findsOneWidget);
    expect(find.text('브랜드'), findsOneWidget);
    expect(find.text('크리에이터'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('알림'));
    await tester.pumpAndSettle();

    expect(opened, ['/notifications']);
  });

  testWidgets('the bottom menu has the five brand items', (tester) async {
    await _pump(tester, _three());

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

  testWidgets('swiping right sends a like and shows the like toast', (
    tester,
  ) async {
    final repo = _three();
    final opened = await _pump(tester, repo);

    await _swipe(tester, '서윤의 작은 취향', const Offset(300, 0));

    expect(repo.decisions.single.outcome, SwipeOutcome.like);
    expect(repo.decisions.single.target.id, 'c1');
    expect(find.text('관심을 보냈어요. 상대도 고르면 알려드려요.'), findsOneWidget);
    expect(find.text('운영자 추천 2 / 3'), findsOneWidget);

    await tester.tap(find.text('관심 목록'));
    await tester.pumpAndSettle();
    expect(opened, ['/brand/interests']);
  });

  testWidgets('swiping left shows the pass toast with a reason link', (
    tester,
  ) async {
    final repo = _three();
    await _pump(tester, repo);

    await _swipe(tester, '서윤의 작은 취향', const Offset(-300, 0));

    expect(repo.decisions.single.outcome, SwipeOutcome.pass);
    expect(find.text('넘겼어요. 상대에게는 알리지 않아요.'), findsOneWidget);
    expect(find.text('이유 남기기'), findsOneWidget);
  });

  testWidgets('swiping up holds the card and the toast opens the saved tab', (
    tester,
  ) async {
    final repo = _three();
    final opened = await _pump(tester, repo);

    await _swipe(tester, '서윤의 작은 취향', const Offset(0, -300));

    expect(repo.decisions.single.outcome, SwipeOutcome.hold);
    expect(find.text('보류함에 담았어요.'), findsOneWidget);

    await tester.tap(find.text('보류 보기'));
    await tester.pumpAndSettle();
    expect(opened, ['/brand/interests?tab=saved']);
  });

  testWidgets('the three buttons decide too', (tester) async {
    final repo = _three();
    await _pump(tester, repo);

    await tester.tap(find.bySemanticsLabel('관심 있어요'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('넘기기'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('보류'));
    await tester.pumpAndSettle();

    expect(repo.decisions.map((d) => d.outcome), [
      SwipeOutcome.like,
      SwipeOutcome.pass,
      SwipeOutcome.hold,
    ]);
  });

  testWidgets('the toast goes away after three seconds', (tester) async {
    await _pump(tester, _three());
    await _swipe(tester, '서윤의 작은 취향', const Offset(300, 0));
    expect(find.text('관심을 보냈어요. 상대도 고르면 알려드려요.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    expect(find.text('관심을 보냈어요. 상대도 고르면 알려드려요.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.text('관심을 보냈어요. 상대도 고르면 알려드려요.'), findsNothing);
  });

  testWidgets('a mutual like shows the match toast', (tester) async {
    final repo = _three()..matchOn.add('c1');
    final opened = await _pump(tester, repo);

    await _swipe(tester, '서윤의 작은 취향', const Offset(300, 0));

    expect(find.text('서윤의 작은 취향과 서로 관심이 닿았어요.'), findsOneWidget);
    expect(find.text('관심을 보냈어요. 상대도 고르면 알려드려요.'), findsNothing);

    await tester.tap(find.text('확인하기'));
    await tester.pumpAndSettle();
    // 05는 10번 작업이 등록한다. 여기서는 가는 곳만 본다.
    expect(opened, ['/brand/interests?match=collab-c1']);
  });

  testWidgets(
    'the reason sheet opens with nothing picked and the no-reason button',
    (tester) async {
      await _pump(tester, _three());
      await _swipe(tester, '서윤의 작은 취향', const Offset(-300, 0));

      await tester.tap(find.text('이유 남기기'));
      await tester.pumpAndSettle();

      expect(find.text('넘겼어요. 이유를 남길까요?'), findsOneWidget);
      expect(
        find.text('선택이에요. 남기면 다음 추천에만 반영하고 상대에게는 알리지 않아요.'),
        findsOneWidget,
      );
      for (final reason in PassReason.values) {
        expect(find.text(reason.label), findsOneWidget);
      }
      expect(find.text('이유 없이 다음 보기'), findsOneWidget);
      expect(find.text('이유 남기고 다음 보기'), findsNothing);
      expect(find.text('되돌리기'), findsWidgets);
    },
  );

  testWidgets('picking a reason switches the button and saves that reason', (
    tester,
  ) async {
    final repo = _three();
    await _pump(tester, repo);
    await _swipe(tester, '서윤의 작은 취향', const Offset(-300, 0));
    await tester.tap(find.text('이유 남기기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('금액이 안 맞아요'));
    await tester.pumpAndSettle();
    expect(find.text('이유 남기고 다음 보기'), findsOneWidget);

    // 하나만 고르고, 고른 것을 다시 누르면 풀린다.
    await tester.tap(find.text('분야가 달라요'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('분야가 달라요'));
    await tester.pumpAndSettle();
    expect(find.text('이유 없이 다음 보기'), findsOneWidget);
    await tester.tap(find.text('금액이 안 맞아요'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('이유 남기고 다음 보기'));
    await tester.pumpAndSettle();

    expect(repo.reasons.single.reason, PassReason.fee);
    expect(repo.reasons.single.target.id, 'c1');
    expect(find.text('넘겼어요. 이유를 남길까요?'), findsNothing);
  });

  testWidgets('leaving without a reason saves nothing', (tester) async {
    final repo = _three();
    await _pump(tester, repo);
    await _swipe(tester, '서윤의 작은 취향', const Offset(-300, 0));
    await tester.tap(find.text('이유 남기기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('이유 없이 다음 보기'));
    await tester.pumpAndSettle();

    expect(repo.reasons, isEmpty);
    expect(find.text('넘겼어요. 이유를 남길까요?'), findsNothing);
    expect(repo.decisions.single.outcome, SwipeOutcome.pass);

    // 시트를 아래로 내려 닫는 것도 같다.
    await _swipe(tester, '민의 옷장 기록', const Offset(-300, 0));
    await tester.tap(find.text('이유 남기기'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(195, 60));
    await tester.pumpAndSettle();
    expect(repo.reasons, isEmpty);
  });

  testWidgets('saving the reason fails quietly and keeps the sheet open', (
    tester,
  ) async {
    final repo = _three()..failSetReason = true;
    await _pump(tester, repo);
    await _swipe(tester, '서윤의 작은 취향', const Offset(-300, 0));
    await tester.tap(find.text('이유 남기기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('분야가 달라요'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('이유 남기고 다음 보기'));
    await tester.pumpAndSettle();

    expect(find.text('잠시 뒤 다시 시도해 주세요.'), findsOneWidget);
    expect(find.text('넘겼어요. 이유를 남길까요?'), findsOneWidget);
  });

  testWidgets(
    'undo on the reason sheet brings the passed card back to the top',
    (tester) async {
      final repo = _three();
      await _pump(tester, repo);
      await _swipe(tester, '서윤의 작은 취향', const Offset(-300, 0));
      expect(find.text('운영자 추천 2 / 3'), findsOneWidget);

      await tester.tap(find.text('이유 남기기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('되돌리기').last);
      await tester.pumpAndSettle();

      expect(repo.undoCalls, 1);
      expect(find.text('넘겼어요. 이유를 남길까요?'), findsNothing);
      // 넘겼던 카드가 맨 앞에 다시 있다.
      expect(find.text('운영자 추천 1 / 3'), findsOneWidget);
      expect(find.text('서윤의 작은 취향'), findsOneWidget);
    },
  );

  testWidgets('undo says it is too late when the server has nothing to undo', (
    tester,
  ) async {
    final repo = _three();
    await _pump(tester, repo);
    await _swipe(tester, '서윤의 작은 취향', const Offset(-300, 0));
    repo.nothingToUndo = true;

    await tester.tap(find.text('이유 남기기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('되돌리기').last);
    await tester.pumpAndSettle();

    expect(find.text('되돌릴 수 없어요. 내일 추천에 다시 나올 수 있어요.'), findsOneWidget);
    // 시트는 열려 있고 넘긴 카드는 그대로 넘겨져 있다.
    expect(find.text('넘겼어요. 이유를 남길까요?'), findsOneWidget);
    expect(find.text('운영자 추천 1 / 3'), findsNothing);
  });

  testWidgets(
    'shows the shared all-seen state with the saved-candidates button and undo',
    (tester) async {
      final repo = FakeDiscoveryRepository(cards: [], total: 2);
      final opened = await _pump(tester, repo);

      expect(find.byType(CoraStateView), findsOneWidget);
      expect(find.text('오늘 추천을 모두 봤어요'), findsOneWidget);
      expect(
        find.text('관심과 저장에 담은 후보를 비교해 보세요. 내일 새 추천이 올라와요.'),
        findsOneWidget,
      );
      expect(find.text('마지막 카드 되돌리기'), findsOneWidget);

      await tester.tap(find.text('저장한 후보 보기'));
      await tester.pumpAndSettle();
      expect(opened, ['/brand/interests?tab=saved']);
    },
  );

  testWidgets('undo brings back the last card', (tester) async {
    final repo = FakeDiscoveryRepository(cards: [creatorCard('c1')]);
    await _pump(tester, repo);
    await _swipe(tester, '서윤의 작은 취향', const Offset(300, 0));
    expect(find.text('오늘 추천을 모두 봤어요'), findsOneWidget);

    await tester.tap(find.text('마지막 카드 되돌리기'));
    await tester.pumpAndSettle();

    expect(find.text('오늘 추천을 모두 봤어요'), findsNothing);
    expect(find.text('서윤의 작은 취향'), findsOneWidget);
    expect(find.text('운영자 추천 1 / 1'), findsOneWidget);
  });

  testWidgets('undo after a restart reads today again and shows the card', (
    tester,
  ) async {
    // 앱을 다시 켠 뒤: 오늘 이미 결정한 카드가 서버 목록에 없고 되돌릴 대상은 서버가 안다.
    final repo = FakeDiscoveryRepository(cards: [], total: 1);
    repo.decisions.add((
      target: const DiscoveryTargetStub('c1').target,
      outcome: SwipeOutcome.pass,
      note: null,
      proposal: null,
    ));
    repo.cards = [creatorCard('c1')];
    await _pump(tester, repo);
    expect(find.text('오늘 추천을 모두 봤어요'), findsOneWidget);

    await tester.tap(find.text('마지막 카드 되돌리기'));
    await tester.pumpAndSettle();

    expect(find.text('서윤의 작은 취향'), findsOneWidget);
  });

  testWidgets('undo says it is too late when nothing can be undone', (
    tester,
  ) async {
    final repo = FakeDiscoveryRepository(cards: [], total: 2)
      ..nothingToUndo = true;
    await _pump(tester, repo);

    await tester.tap(find.text('마지막 카드 되돌리기'));
    await tester.pumpAndSettle();

    expect(find.text('되돌릴 수 없어요. 내일 추천에 다시 나올 수 있어요.'), findsOneWidget);
    expect(find.text('오늘 추천을 모두 봤어요'), findsOneWidget);
  });

  testWidgets('shows the no-candidates state when today has zero cards', (
    tester,
  ) async {
    await _pump(tester, FakeDiscoveryRepository());

    expect(find.text('아직 추천할 크리에이터가 없어요.'), findsOneWidget);
    expect(find.text('크리에이터가 늘어나면 알려드릴게요.'), findsOneWidget);
    expect(find.text('오늘 추천을 모두 봤어요'), findsNothing);
  });

  testWidgets('offers a retry when today cannot be loaded', (tester) async {
    final repo = _three()..failFetch = true;
    await _pump(tester, repo);

    expect(find.text('추천을 불러오지 못했어요'), findsOneWidget);

    repo.failFetch = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('서윤의 작은 취향'), findsOneWidget);
  });

  testWidgets('the card returns when the decision fails', (tester) async {
    final repo = _three()..failDecide = true;
    await _pump(tester, repo);

    await _swipe(tester, '서윤의 작은 취향', const Offset(300, 0));

    // 덱이 예상 못 한 실패를 Flutter 오류로도 알린다.
    expect(tester.takeException(), isA<DiscoveryFailure>());
    expect(find.text('잠시 뒤 다시 시도해 주세요.'), findsOneWidget);
    expect(find.text('서윤의 작은 취향'), findsOneWidget);
    expect(find.text('운영자 추천 1 / 3'), findsOneWidget);
    expect(repo.decisions, isEmpty);
  });

  testWidgets(
    'tapping the card opens the creator detail and the photo is a hero',
    (tester) async {
      final opened = await _pump(tester, _three());
      expect(
        find.byWidgetPredicate(
          (w) => w is Hero && w.tag == 'creator:c1',
          skipOffstage: false,
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('서윤의 작은 취향'));
      await tester.pumpAndSettle();

      expect(opened, ['/brand/creators/c1']);
    },
  );

  testWidgets('the chat menu item opens the conversation list', (tester) async {
    final opened = await _pump(tester, _three());

    await tester.tap(find.text('대화'));
    await tester.pumpAndSettle();
    expect(opened, [AppRoutes.chats]);
  });

  testWidgets('uses the dark toast and card section colors in dark mode', (
    tester,
  ) async {
    await _pump(tester, _three(), theme: coraDarkTheme);
    await _swipe(tester, '서윤의 작은 취향', const Offset(300, 0));

    final toast = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(DiscoveryToastBanner),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final decoration = toast.decoration as BoxDecoration;
    expect(decoration.color, CoraColors.dark.toastSurface);
    // 다크는 그림자 없음(투명).
    expect(decoration.boxShadow!.single.color.a, 0);
    final text = tester.widget<Text>(find.text('관심을 보냈어요. 상대도 고르면 알려드려요.'));
    expect(text.style!.color, const Color(0xFFFFFFFF));
  });
}
