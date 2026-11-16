import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/core/ui/cora_state_view.dart';
import 'package:cora/features/auth/domain/current_user_provider.dart';
import 'package:cora/features/collaboration/domain/collaboration.dart';
import 'package:cora/features/collaboration/domain/collaboration_repository.dart';
import 'package:cora/features/creator_profile/domain/creator_profile_repository.dart';
import 'package:cora/features/discovery/presentation/widgets/brand_bottom_nav.dart';
import 'package:cora/features/negotiation/presentation/pages/brand_progress_page.dart';
import 'package:cora/features/negotiation/presentation/pages/collaboration_hub_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../collaboration/fake_collaboration_repository.dart';
import '../creator_profile/fake_creator_profile_repository.dart';
import 'brand_collaboration_harness.dart';

/// 협업 탭(`/brand/collaborations`)을 올린다. 07과 발견 쪽 경로는 위치를 기록하는 빈 화면이다.
Future<List<String>> _pump(
  WidgetTester tester,
  FakeCollaborationRepository repo, {
  ThemeData? theme,
}) async {
  useCanvasPhone(tester);
  final opened = <String>[];
  Widget stub(GoRouterState state) {
    opened.add(state.uri.toString());
    return Scaffold(body: Text('opened ${state.uri}'));
  }

  final router = GoRouter(
    initialLocation: AppRoutes.brandCollaborations,
    routes: [
      GoRoute(
        path: AppRoutes.brandCollaborations,
        builder: (context, state) => const CollaborationHubPage(),
      ),
      GoRoute(
        path: AppRoutes.collaborationProgressPattern,
        builder: (context, state) => stub(state),
      ),
      GoRoute(path: AppRoutes.brand, builder: (c, s) => stub(s)),
      GoRoute(path: AppRoutes.brandInterests, builder: (c, s) => stub(s)),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('user-1'),
        collaborationRepositoryProvider.overrideWithValue(repo),
        creatorProfileRepositoryProvider.overrideWithValue(
          FakeCreatorProfileRepository(),
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

  testWidgets('with exactly one brand collaboration the tab shows the '
      'progress screen straight away', (tester) async {
    await _pump(tester, FakeCollaborationRepository(active: [brandCollab()]));

    expect(find.byType(BrandProgressPage), findsOneWidget);
    expect(find.text('2 / 6 완료'), findsOneWidget);
    expect(find.text('콘텐츠 방향을 함께 잡아요.'), findsOneWidget);
  });

  testWidgets('store offers are not counted as brand collaborations', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeCollaborationRepository(active: [collaboration(), brandCollab()]),
    );

    expect(find.byType(BrandProgressPage), findsOneWidget);
  });

  testWidgets('with several the tab lists them and a row opens its progress', (
    tester,
  ) async {
    final opened = await _pump(
      tester,
      FakeCollaborationRepository(
        active: [
          brandCollab(nextAction: CollaborationNextAction.respondTerms),
          brandCollab(
            id: 'b0b0b0b0-aaaa-bbbb-cccc-000000000008',
            counterpart: '하루 한 컵',
            doneCount: 1,
            current: 2,
          ),
        ],
      ),
    );

    expect(find.text('협업'), findsNWidgets(2)); // 제목과 하단 메뉴
    expect(find.text('서윤의 작은 취향'), findsOneWidget);
    expect(find.text('받은 제안 확인하고 응답하기'), findsOneWidget);
    expect(find.text('하루 한 컵'), findsOneWidget);
    expect(find.text('1 / 6 완료'), findsOneWidget);
    expect(find.byType(BrandProgressPage), findsNothing);

    await tester.tap(find.text('하루 한 컵'));
    await tester.pumpAndSettle();

    expect(
      opened.last,
      AppRoutes.collaborationProgress('b0b0b0b0-aaaa-bbbb-cccc-000000000008'),
    );
  });

  testWidgets('an empty list says so', (tester) async {
    await _pump(tester, FakeCollaborationRepository());

    expect(find.byType(CoraStateView), findsOneWidget);
    expect(find.text('아직 진행 중인 협업이 없어요.'), findsOneWidget);
  });

  testWidgets('a load failure shows the shared failure state and retries', (
    tester,
  ) async {
    final repo = FakeCollaborationRepository(active: [brandCollab()])
      ..failFetch = true;
    await _pump(tester, repo);

    expect(find.text('진행 중인 협업을 불러오지 못했어요.'), findsOneWidget);

    repo.failFetch = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(find.byType(BrandProgressPage), findsOneWidget);
  });

  testWidgets('the brand nav goes back to discovery and interests from the '
      'tab', (tester) async {
    final opened = await _pump(
      tester,
      FakeCollaborationRepository(active: [brandCollab()]),
    );

    expect(find.byType(BrandBottomNav), findsOneWidget);
    await tester.tap(find.text('발견'));
    await tester.pumpAndSettle();
    expect(opened.last, AppRoutes.brandDiscoverTab);
  });

  testWidgets('works in the dark theme', (tester) async {
    await _pump(
      tester,
      FakeCollaborationRepository(
        active: [
          brandCollab(),
          brandCollab(id: 'other-1', counterpart: '하루 한 컵'),
        ],
      ),
      theme: coraDarkTheme,
    );

    expect(find.text('하루 한 컵'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
