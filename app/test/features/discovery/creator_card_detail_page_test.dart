import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/core/ui/swipe_deck/swipe_physics.dart' show SwipeOutcome;
import 'package:cora/features/discovery/domain/discovery_card.dart';
import 'package:cora/features/discovery/domain/discovery_repository.dart';
import 'package:cora/features/discovery/presentation/pages/brand_discovery_page.dart';
import 'package:cora/features/discovery/presentation/pages/creator_card_detail_page.dart';
import 'package:cora/features/notifications/domain/notification_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../notifications/fake_notification_repository.dart';
import 'fake_discovery_repository.dart';

/// 01을 `/brand`에, 상세를 `/brand/creators/:id`에 올린 실제 모양의 라우터.
Future<void> _pump(WidgetTester tester, FakeDiscoveryRepository repo) async {
  useCanvasPhone(tester);
  final router = GoRouter(
    initialLocation: AppRoutes.brand,
    routes: [
      GoRoute(
        path: AppRoutes.brand,
        builder: (context, state) => const BrandDiscoveryPage(),
      ),
      GoRoute(
        path: AppRoutes.brandCreatorPattern,
        builder: (context, state) => CreatorCardDetailPage(
          creatorId: state.pathParameters['id']!,
          card: state.extra is CreatorCard ? state.extra! as CreatorCard : null,
        ),
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
      child: MaterialApp.router(routerConfig: router, theme: coraLightTheme),
    ),
  );
  await tester.pumpAndSettle();
}

FakeDiscoveryRepository _repo() => FakeDiscoveryRepository(
  cards: [
    creatorCard('c1', name: '서윤의 작은 취향'),
    creatorCard('c2', name: '민의 옷장 기록', reasons: const []),
  ],
);

Future<void> _openDetail(WidgetTester tester) async {
  await tester.tap(find.text('서윤의 작은 취향'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('shows the photo, name, headline, tags and why they fit', (
    tester,
  ) async {
    await _pump(tester, _repo());
    await _openDetail(tester);

    expect(find.byType(CreatorCardDetailPage), findsOneWidget);
    expect(find.text('서윤의 작은 취향'), findsOneWidget);
    expect(find.text('출근 전 30초, 오늘의 손목 루틴'), findsOneWidget);
    expect(find.text('#얼굴출연없음'), findsOneWidget);
    expect(find.text('잘 맞는 점'), findsOneWidget);
    expect(find.text('분야가 맞아요'), findsOneWidget);
    expect(find.text('제작비가 맞아요'), findsOneWidget);
    expect(find.text('넘기기'), findsOneWidget);
    expect(find.text('관심 보내기'), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) => w is Hero && w.tag == 'creator:c1'),
      findsOneWidget,
    );
  });

  testWidgets('hides the fit section when there are no reasons', (
    tester,
  ) async {
    await _pump(tester, _repo());
    await tester.drag(find.text('서윤의 작은 취향'), const Offset(-300, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('민의 옷장 기록'));
    await tester.pumpAndSettle();

    expect(find.byType(CreatorCardDetailPage), findsOneWidget);
    expect(find.text('잘 맞는 점'), findsNothing);
  });

  testWidgets(
    'passing from the detail sends a pass and goes back to the pass toast',
    (tester) async {
      final repo = _repo();
      await _pump(tester, repo);
      await _openDetail(tester);

      await tester.tap(find.text('넘기기'));
      await tester.pumpAndSettle();

      expect(repo.decisions.single.outcome, SwipeOutcome.pass);
      expect(find.byType(CreatorCardDetailPage), findsNothing);
      expect(find.text('넘겼어요. 상대에게는 알리지 않아요.'), findsOneWidget);
      // 넘긴 카드는 덱에서 빠졌다.
      expect(find.text('서윤의 작은 취향'), findsNothing);
    },
  );

  testWidgets('liking from the detail can carry a note', (tester) async {
    final repo = _repo();
    await _pump(tester, repo);
    await _openDetail(tester);

    await tester.tap(find.text('관심 보내기'));
    await tester.pumpAndSettle();
    expect(find.text('좋았던 점을 한 줄 남길까요? (선택)'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('likeNote.field')),
      '손목 루틴이 브랜드 분위기와 잘 맞아요',
    );
    await tester.tap(find.text('관심 보내기').last);
    await tester.pumpAndSettle();

    expect(repo.decisions.single.outcome, SwipeOutcome.like);
    expect(repo.decisions.single.note, '손목 루틴이 브랜드 분위기와 잘 맞아요');
    expect(find.byType(CreatorCardDetailPage), findsNothing);
    expect(find.text('하트를 보냈어요. 상대도 고르면 알려드려요.'), findsOneWidget);
  });

  testWidgets('liking with an empty note sends no note', (tester) async {
    final repo = _repo();
    await _pump(tester, repo);
    await _openDetail(tester);

    await tester.tap(find.text('관심 보내기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('관심 보내기').last);
    await tester.pumpAndSettle();

    expect(repo.decisions.single.note, isNull);
  });

  testWidgets('a failed decision keeps the detail open and says so', (
    tester,
  ) async {
    final repo = _repo()..failDecide = true;
    await _pump(tester, repo);
    await _openDetail(tester);

    await tester.tap(find.text('넘기기'));
    await tester.pumpAndSettle();

    expect(find.byType(CreatorCardDetailPage), findsOneWidget);
    expect(find.text('잠시 뒤 다시 시도해 주세요.'), findsOneWidget);
    expect(repo.decisions, isEmpty);
  });

  testWidgets('a detail opened without a card finds it in today list', (
    tester,
  ) async {
    final repo = _repo();
    await _pump(tester, repo);
    GoRouter.of(
      tester.element(find.byType(BrandDiscoveryPage)),
    ).push(AppRoutes.brandCreator('c2'));
    await tester.pumpAndSettle();

    expect(find.byType(CreatorCardDetailPage), findsOneWidget);
    expect(find.text('민의 옷장 기록'), findsWidgets);

    GoRouter.of(
      tester.element(find.byType(CreatorCardDetailPage)),
    ).push(AppRoutes.brandCreator('unknown'));
    await tester.pumpAndSettle();
    expect(find.text('추천을 불러오지 못했어요'), findsOneWidget);
  });
}
