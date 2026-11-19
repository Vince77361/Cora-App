import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/theme/cora_colors.dart';
import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/core/ui/cora_bottom_nav.dart';
import 'package:cora/core/ui/cora_state_view.dart';
import 'package:cora/core/ui/swipe_deck/swipe_deck.dart';
import 'package:cora/core/ui/swipe_deck/swipe_physics.dart' show SwipeOutcome;
import 'package:cora/features/discovery/domain/featured_post_ref.dart';
import 'package:cora/features/discovery/domain/pass_reason.dart';
import 'package:cora/features/discovery/presentation/widgets/swipe_progress_bar.dart';
import 'package:cora/features/store_discover/domain/store_creator_card.dart';
import 'package:cora/features/store_discover/domain/store_discover_repository.dart';
import 'package:cora/features/store_discover/presentation/pages/store_discover_page.dart';
import 'package:cora/features/store_discover/presentation/viewmodels/store_discover_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import 'fake_store_discover_repository.dart';

/// 위치를 기록하는 라우터. 둘러보기를 `/store/discover`에 올리고 나머지 경로는 위치 글자만 보이는 빈 화면이다.
Future<List<String>> _pump(
  WidgetTester tester,
  FakeStoreDiscoverRepository repo, {
  ThemeData? theme,
  int savedCount = 0,
  bool smallPhoneLargeText = false,
}) async {
  if (smallPhoneLargeText) {
    useSmallPhoneWithLargeText(tester);
  } else {
    useCanvasPhone(tester);
  }
  final opened = <String>[];
  Widget stub(GoRouterState state) {
    opened.add(state.uri.toString());
    return Scaffold(body: Text('opened ${state.uri}'));
  }

  final router = GoRouter(
    initialLocation: AppRoutes.storeDiscover,
    routes: [
      GoRoute(
        path: AppRoutes.storeDiscover,
        builder: (context, state) => const StoreDiscoverPage(),
      ),
      for (final path in [
        AppRoutes.store,
        AppRoutes.storeInterests,
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
        storeDiscoverRepositoryProvider.overrideWithValue(repo),
        storeSavedCountProvider.overrideWithValue(savedCount),
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

FakeStoreDiscoverRepository _two() => FakeStoreDiscoverRepository(
  cards: [
    storeCard('c1'),
    storeCard(
      'c2',
      name: '민의 옷장 기록',
      contentFocus: '패션 릴스',
      followers: 4800,
      tags: const ['패션'],
    ),
  ],
);

/// 맨 위 카드(크리에이터 [id])의 왼쪽 위 글자. 뒤 카드도 자기 글자를 달고 있어서 카드 안에서 찾는다.
SwipeProgressBar _bar(WidgetTester tester, {String id = 'c1'}) =>
    tester.widget<SwipeProgressBar>(
      find.descendant(
        of: find.byKey(ValueKey(id)),
        matching: find.byType(SwipeProgressBar),
      ),
    );

Finder _badge(String text, {String id = 'c1'}) =>
    find.descendant(of: find.byKey(ValueKey(id)), matching: find.text(text));

const _heartToast = '하트를 보냈어요. 상대도 고르면 알려드려요.';
const _saveToast = '저장했어요. 나만 볼 수 있어요.';

/// 카드의 오른쪽·왼쪽 절반 안쪽(버튼 줄과 알림 아래).
const _rightHalf = Offset(300, 300);
const _leftHalf = Offset(80, 300);

Future<void> _swipe(WidgetTester tester, String text, Offset by) async {
  await tester.drag(find.text(text), by);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('shows the first post with the progress bar and 대표 게시물 1 / 4', (
    tester,
  ) async {
    await _pump(tester, _two());

    expect(find.text('전체 둘러보기'), findsOneWidget);
    expect(_badge('대표 게시물 1 / 4'), findsOneWidget);
    expect(find.text('하루 한 컵'), findsOneWidget);
    expect(find.text('하루 한 컵 게시물 1'), findsOneWidget);
    expect(find.text('리빙 릴스 · 팔로워 640'), findsOneWidget);
    expect(find.text('#리빙'), findsOneWidget);
    expect(find.text('#아침루틴'), findsOneWidget);
    final bar = _bar(tester);
    expect(bar.segments, 4);
    expect(bar.current, 0);
    // 버튼 네 개와 하단 메뉴(찾기가 켜짐).
    for (final label in ['되돌리기', '넘기기', '저장', '하트']) {
      expect(find.bySemanticsLabel(label), findsOneWidget);
    }
    expect(find.byType(CoraBottomNav), findsOneWidget);
  });

  testWidgets('a creator with one post shows a single segment and 1 / 1', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeStoreDiscoverRepository(cards: [storeCard('c1', postCount: 1)]),
    );

    expect(_badge('대표 게시물 1 / 1'), findsOneWidget);
    expect(_bar(tester).segments, 1);
    // 탭해도 그대로다.
    await tester.tapAt(_rightHalf);
    await tester.pumpAndSettle();
    expect(_badge('대표 게시물 1 / 1'), findsOneWidget);
  });

  testWidgets('the header shows the saved count badge only above zero', (
    tester,
  ) async {
    await _pump(tester, _two());
    expect(find.bySemanticsLabel('저장함'), findsOneWidget);
    expect(find.text('3'), findsNothing);
  });

  testWidgets('the header shows 3 on the bookmark when three are saved', (
    tester,
  ) async {
    final opened = await _pump(tester, _two(), savedCount: 3);

    expect(find.text('3'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('저장함, 3명'));
    await tester.pumpAndSettle();
    expect(opened, ['/store/interests?tab=saved']);
  });

  testWidgets('goes to the next and previous post by tapping the right and '
      'left halves', (tester) async {
    final repo = _two();
    await _pump(tester, repo);

    await tester.tapAt(_rightHalf);
    await tester.pumpAndSettle();
    expect(_badge('대표 게시물 2 / 4'), findsOneWidget);
    expect(find.text('하루 한 컵 게시물 2'), findsOneWidget);
    expect(_bar(tester).current, 1);

    await tester.tapAt(_rightHalf);
    await tester.pumpAndSettle();
    await tester.tapAt(_rightHalf);
    await tester.pumpAndSettle();
    expect(_badge('대표 게시물 4 / 4'), findsOneWidget);
    // 마지막에서 더 눌러도 넘어가지 않는다.
    await tester.tapAt(_rightHalf);
    await tester.pumpAndSettle();
    expect(_badge('대표 게시물 4 / 4'), findsOneWidget);

    await tester.tapAt(_leftHalf);
    await tester.pumpAndSettle();
    expect(_badge('대표 게시물 3 / 4'), findsOneWidget);
    for (var i = 0; i < 4; i++) {
      await tester.tapAt(_leftHalf);
      await tester.pumpAndSettle();
    }
    expect(_badge('대표 게시물 1 / 4'), findsOneWidget);
    expect(repo.decisions, isEmpty);
  });

  testWidgets('keeps swiping decisions on horizontal drags, not on post taps', (
    tester,
  ) async {
    final repo = _two();
    await _pump(tester, repo);

    await tester.tapAt(_rightHalf);
    await tester.tapAt(_leftHalf);
    await tester.pumpAndSettle();
    expect(repo.decisions, isEmpty);

    await _swipe(tester, '하루 한 컵 게시물 1', const Offset(-300, 0));
    expect(repo.decisions.single.outcome, SwipeOutcome.pass);
    // 다음 사람은 첫 게시물에서 시작한다.
    expect(find.text('민의 옷장 기록'), findsOneWidget);
    expect(_badge('대표 게시물 1 / 4', id: 'c2'), findsOneWidget);
  });

  testWidgets('sends LIKE for a right swipe and HOLD for an upward swipe', (
    tester,
  ) async {
    final repo = _two();
    await _pump(tester, repo);

    await _swipe(tester, '하루 한 컵 게시물 1', const Offset(300, 0));
    await _swipe(tester, '민의 옷장 기록 게시물 1', const Offset(0, -300));

    expect(repo.decisions.map((d) => (d.creatorId, d.outcome)), [
      ('c1', SwipeOutcome.like),
      ('c2', SwipeOutcome.hold),
    ]);
  });

  testWidgets('the heart, pass and save buttons decide too', (tester) async {
    final repo = FakeStoreDiscoverRepository(
      cards: [storeCard('c1'), storeCard('c2'), storeCard('c3')],
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

  testWidgets('shows the heart toast with 보낸 관심 and the save toast with '
      '저장함', (tester) async {
    final repo = _two();
    final opened = await _pump(tester, repo);

    await _swipe(tester, '하루 한 컵 게시물 1', const Offset(300, 0));
    expect(find.text(_heartToast), findsOneWidget);
    expect(find.text('보낸 관심'), findsOneWidget);
    // 사장님에게는 서로 관심 알림이 오지 않는다.
    expect(find.textContaining('서로 관심'), findsNothing);
    await tester.tap(find.text('보낸 관심'));
    await tester.pumpAndSettle();
    expect(opened, ['/store/interests?tab=sent']);
  });

  testWidgets('the save toast opens the saved tab', (tester) async {
    final opened = await _pump(tester, _two());

    await _swipe(tester, '하루 한 컵 게시물 1', const Offset(0, -300));
    expect(find.text(_saveToast), findsOneWidget);
    expect(find.text('저장함'), findsOneWidget);
    await tester.tap(find.text('저장함'));
    await tester.pumpAndSettle();
    expect(opened, ['/store/interests?tab=saved']);
  });

  testWidgets('opens the pass-reason sheet only from the 이유 남기기 action', (
    tester,
  ) async {
    final repo = _two();
    await _pump(tester, repo);

    await _swipe(tester, '하루 한 컵 게시물 1', const Offset(-300, 0));
    expect(find.text('넘겼어요. 상대에게는 알리지 않아요.'), findsOneWidget);
    expect(find.text('넘겼어요. 이유를 남길까요?'), findsNothing);

    await tester.tap(find.text('이유 남기기'));
    await tester.pumpAndSettle();
    expect(find.text('넘겼어요. 이유를 남길까요?'), findsOneWidget);
    expect(find.text('건너뛰기'), findsOneWidget);

    await tester.tap(find.text('금액이 안 맞아요'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('이유 남기고 다음 보기'));
    await tester.pumpAndSettle();

    expect(repo.reasons.single.creatorId, 'c1');
    expect(repo.reasons.single.reason, PassReason.fee);
    expect(find.text('넘겼어요. 이유를 남길까요?'), findsNothing);
  });

  testWidgets('shows 오늘 추천을 모두 봤어요 with 저장한 후보 보기 when the deck ends', (
    tester,
  ) async {
    final repo = FakeStoreDiscoverRepository(cards: [storeCard('c1')]);
    final opened = await _pump(tester, repo);

    await _swipe(tester, '하루 한 컵 게시물 1', const Offset(300, 0));

    expect(find.byType(CoraStateView), findsOneWidget);
    expect(find.text('오늘 추천을 모두 봤어요'), findsOneWidget);
    expect(find.text('하트와 저장에 담은 후보를 비교해 보세요. 내일 새 추천이 올라와요.'), findsOneWidget);
    await tester.tap(find.text('저장한 후보 보기'));
    await tester.pumpAndSettle();
    expect(opened, ['/store/interests?tab=saved']);
  });

  testWidgets('all seen is decided by the remaining cards, not by the total', (
    tester,
  ) async {
    // 서버의 total은 이미 결정한 카드를 포함한다. 남은 카드가 없으면 total이 커도 다 본 것이다.
    await _pump(tester, FakeStoreDiscoverRepository(cards: [], total: 7));

    expect(find.text('오늘 추천을 모두 봤어요'), findsOneWidget);
  });

  testWidgets('shows the no-candidates state when today has zero cards', (
    tester,
  ) async {
    await _pump(tester, FakeStoreDiscoverRepository());

    expect(find.text('아직 추천할 크리에이터가 없어요.'), findsOneWidget);
    expect(find.text('오늘 추천을 모두 봤어요'), findsNothing);
  });

  testWidgets('offers a retry when today cannot be loaded', (tester) async {
    final repo = _two()..failFetch = true;
    await _pump(tester, repo);

    expect(find.text('추천을 불러오지 못했어요'), findsOneWidget);
    repo.failFetch = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('하루 한 컵 게시물 1'), findsOneWidget);
  });

  testWidgets('undoes the last decision and puts the card back', (
    tester,
  ) async {
    final repo = _two();
    await _pump(tester, repo);
    await _swipe(tester, '하루 한 컵 게시물 1', const Offset(-300, 0));
    expect(find.text('민의 옷장 기록'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('되돌리기'));
    await tester.pumpAndSettle();

    expect(repo.undoCalls, 1);
    expect(find.text('하루 한 컵 게시물 1'), findsOneWidget);
    expect(_badge('대표 게시물 1 / 4'), findsOneWidget);
  });

  testWidgets('undo says it is too late when it cannot be undone (mutual '
      'interest)', (tester) async {
    final repo = _two();
    await _pump(tester, repo);
    await _swipe(tester, '하루 한 컵 게시물 1', const Offset(300, 0));
    repo.nothingToUndo = true;

    await tester.tap(find.bySemanticsLabel('되돌리기'));
    await tester.pumpAndSettle();

    expect(find.text('되돌릴 수 없어요. 내일 추천에 다시 나올 수 있어요.'), findsOneWidget);
    expect(find.text('민의 옷장 기록'), findsOneWidget);
  });

  testWidgets('the card returns when the decision fails', (tester) async {
    final repo = _two()..failDecide = true;
    await _pump(tester, repo);

    await _swipe(tester, '하루 한 컵 게시물 1', const Offset(300, 0));

    expect(tester.takeException(), isA<StoreDiscoverFailure>());
    expect(find.text('잠시 뒤 다시 시도해 주세요.'), findsOneWidget);
    expect(find.text('하루 한 컵 게시물 1'), findsOneWidget);
    expect(repo.decisions, isEmpty);
  });

  testWidgets('the bottom menu moves to the other store screens', (
    tester,
  ) async {
    final opened = await _pump(tester, _two());

    await tester.tap(find.text('오퍼').last);
    await tester.pumpAndSettle();
    expect(opened, [AppRoutes.storeProposals]);
  });

  testWidgets('does not overflow at 1.3x text scale and uses dark tokens', (
    tester,
  ) async {
    final longLine = '아주 긴 한 줄 설명을 마흔 글자까지 꽉 채워서 써 본 대표 게시물입니다 정말로';
    await _pump(
      tester,
      FakeStoreDiscoverRepository(
        cards: [
          StoreCreatorCard(
            creatorId: 'c1',
            displayName: '아주 긴 활동 이름을 가진 크리에이터의 작은 취향 기록',
            contentFocus: '리빙 릴스',
            followers: 1234567,
            headline: longLine,
            photoUrl: null,
            posts: [FeaturedPostRef(photoUrl: null, caption: longLine)],
            tags: const ['리빙', '아침루틴', '주말', '식탁'],
          ),
        ],
      ),
      theme: coraDarkTheme,
      savedCount: 12,
      smallPhoneLargeText: true,
    );

    expect(tester.takeException(), isNull);
    final context = tester.element(find.byType(StoreDiscoverPage));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(context.colors.background, const Color(0xFF0F1012));
    // 바탕은 다크 배경(#0F1012)이다(화면 바탕과 카드 영역 뒤).
    expect(Theme.of(context).scaffoldBackgroundColor, const Color(0xFF0F1012));
    final section = tester.widget<DecoratedBox>(
      find
          .ancestor(
            of: find.byType(SwipeDeck<StoreCreatorCard>),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect(
      (section.decoration as BoxDecoration).color,
      const Color(0xFF0F1012),
    );
    expect(find.text('리빙 릴스 · 팔로워 1,234,567'), findsOneWidget);

    // 한 줄이 두 줄을 넘으면 두 줄에서 말줄임표로 멈춘다(1.3배에서도 세 줄이 되지 않는다).
    final title = tester.widget<Text>(find.text(longLine));
    expect(title.maxLines, 2);
    final lineHeight =
        title.style!.fontSize! * 1.3 * (title.style!.height ?? 1.2);
    final height = tester.getSize(find.text(longLine)).height;
    expect(height, greaterThan(lineHeight * 1.5));
    expect(height, lessThanOrEqualTo(lineHeight * 2 + 2));
  });
}
