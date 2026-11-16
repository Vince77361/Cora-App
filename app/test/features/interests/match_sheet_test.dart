import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/features/discovery/domain/reward_proposal.dart';
import 'package:cora/features/instagram_connect/domain/instagram_repository.dart';
import 'package:cora/features/interests/domain/interests_repository.dart';
import 'package:cora/features/server_config/domain/server_config_repository.dart';
import 'package:cora/features/interests/domain/match_info.dart';
import 'package:cora/features/interests/presentation/pages/match_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import '../instagram_connect/fake_instagram_repository.dart';
import '../server_config/fake_server_config_repository.dart';
import 'fake_interests_repository.dart';

/// 시트를 여는 단추 하나가 있는 화면. 시트가 가는 경로(06, 07)는 위치 글자만 보이는 빈 화면이고 위치를 기록한다.
Future<({List<String> opened, List<MatchSheetResult> results})> _pump(
  WidgetTester tester,
  MatchInfo info, {
  ThemeData? theme,
  String start = '/start',
  FakeInterestsRepository? repo,
}) async {
  useCanvasPhone(tester);
  final opened = <String>[];
  final results = <MatchSheetResult>[];
  Widget stub(GoRouterState state) {
    opened.add(state.uri.toString());
    return Scaffold(body: Text('opened ${state.uri}'));
  }

  final router = GoRouter(
    initialLocation: start,
    routes: [
      GoRoute(
        path: start,
        builder: (context, state) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async =>
                  results.add(await showMatchSheet(context, info)),
              child: const Text('open sheet'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/collaborations/:id/terms',
        builder: (context, state) => stub(state),
      ),
      // 보낸 제안은 그 협업의 07(진행 단계)로 이어진다. 여기서는 위치만 기록한다.
      GoRoute(
        path: AppRoutes.collaborationProgressPattern,
        builder: (c, s) => stub(s),
      ),
      GoRoute(path: '/creator/instagram', builder: (c, s) => stub(s)),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        interestsRepositoryProvider.overrideWithValue(
          repo ?? (FakeInterestsRepository()..proposalBase = proposalBase()),
        ),
        serverConfigRepositoryProvider.overrideWithValue(
          FakeServerConfigRepository(),
        ),
        instagramRepositoryProvider.overrideWithValue(
          FakeInstagramRepository(),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: theme ?? coraLightTheme,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('open sheet'));
  await tester.pumpAndSettle();
  return (opened: opened, results: results);
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('the match sheet shows the campaign badge and the two new '
      'buttons', (tester) async {
    await _pump(tester, matchInfo());

    expect(find.text('느린 결, 일상의 주얼리 캠페인에서 연결'), findsOneWidget);
    expect(find.text('서로를 골랐어요.'), findsOneWidget);
    expect(
      find.text(
        '모아 스튜디오와 서윤의 작은 취향이 서로의 콘텐츠에 관심을 표시했어요. '
        '아직 계약이나 지급 의무는 생기지 않아요.',
      ),
      findsOneWidget,
    );
    expect(find.text('받은 제안 보기 · 1건'), findsOneWidget);
    expect(find.text('내가 먼저 제안하기'), findsOneWidget);
  });

  testWidgets('the badge falls back to the brand name without a tagline', (
    tester,
  ) async {
    await _pump(tester, matchInfo(brandTagline: null));

    expect(find.text('모아 스튜디오 캠페인에서 연결'), findsOneWidget);
  });

  testWidgets('the sentence takes the josa of each name', (tester) async {
    await _pump(tester, matchInfo(brandName: '한그릇', creatorName: '하루 한 컵'));

    expect(find.textContaining('한그릇과 하루 한 컵이 서로의 콘텐츠에'), findsOneWidget);
  });

  testWidgets('the button says view proposals without a count when there is '
      'none', (tester) async {
    await _pump(tester, matchInfo(pendingProposals: 0));

    expect(find.text('제안 보기'), findsOneWidget);
    expect(find.textContaining('받은 제안 보기'), findsNothing);
  });

  testWidgets('the match sheet no longer has the keep-browsing button', (
    tester,
  ) async {
    await _pump(tester, matchInfo());

    expect(find.text('계속 둘러보기'), findsNothing);
    expect(find.text('협업 조건 확인하기'), findsNothing);
    // 첫 인사 입력란은 이 계획에서 만들지 않는다.
    expect(find.byType(TextField), findsNothing);
    expect(find.text('콘텐츠에 대한 첫 인사 남기기'), findsNothing);
  });

  testWidgets('the received-proposal button opens the terms screen', (
    tester,
  ) async {
    final env = await _pump(tester, matchInfo(collaborationId: 'collab-9'));

    await tester.tap(find.text('받은 제안 보기 · 1건'));
    await tester.pumpAndSettle();

    expect(env.opened, ['/collaborations/collab-9/terms']);
    expect(env.results, [MatchSheetResult.moved]);
    expect(find.text('서로를 골랐어요.'), findsNothing);
  });

  testWidgets('the propose-first button opens the reward screen and keeps '
      'the sheet', (tester) async {
    final env = await _pump(tester, matchInfo());

    await tester.tap(find.text('내가 먼저 제안하기'));
    await tester.pumpAndSettle();

    // F1은 최신 판본의 값(30만 원, 제품 제공, 성과 추가 없음)에서 시작한다.
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('300,000원'), findsOneWidget);
    expect(find.text('제품 제공'), findsOneWidget);

    // 보내지 않고 닫으면 시트는 그대로다.
    await tester.tap(find.bySemanticsLabel('뒤로'));
    await tester.pumpAndSettle();
    expect(find.text('서로를 골랐어요.'), findsOneWidget);
    expect(env.results, isEmpty);
    expect(env.opened, isEmpty);
  });

  testWidgets('proposing first from the match sheet creates a new version and '
      'goes to progress', (tester) async {
    final repo = FakeInterestsRepository()..proposalBase = proposalBase();
    final env = await _pump(tester, matchInfo(baseVersion: 2), repo: repo);

    await tester.tap(find.text('내가 먼저 제안하기'));
    await tester.pumpAndSettle();
    // 성과 추가를 켜서 값을 바꾼다(바꾼 조건이 없으면 서버가 거절한다).
    await tester.tap(find.text('성과 추가'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('검토하고 보내기'));
    await tester.pumpAndSettle();
    // 이번에 만들어질 판본은 기준 판본의 다음이다.
    expect(find.textContaining('판본 3으로 고정되고'), findsOneWidget);
    await tester.tap(find.text('이 조건으로 보내기'));
    await tester.pumpAndSettle();

    final sent = repo.proposed.single;
    expect(sent.id, 'collab-1');
    expect(sent.baseVersion, 2);
    expect(
      sent.proposal,
      const RewardProposal(
        fee: 300000,
        productProvided: true,
        performance: (ratePer1000: 2000, cap: 60000),
      ),
    );
    expect(env.opened, [AppRoutes.collaborationProgress('collab-1')]);
    expect(env.results, [MatchSheetResult.moved]);
    expect(find.text('서로를 골랐어요.'), findsNothing);
  });

  testWidgets('the creator side proposes the same way and goes to that '
      'collaboration progress', (tester) async {
    final repo = FakeInterestsRepository()
      ..proposalBase = proposalBase(proposedByBrand: false);
    final env = await _pump(
      tester,
      matchInfo(isBrand: false),
      start: '/creator/interests',
      repo: repo,
    );

    await tester.tap(find.text('내가 먼저 제안하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('제품 제공'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('검토하고 보내기'));
    await tester.pumpAndSettle();
    // 이용료는 브랜드가 내서 크리에이터의 제안에는 이용료 문장이 없다.
    expect(find.textContaining('이용료'), findsNothing);
    await tester.tap(find.text('이 조건으로 보내기'));
    await tester.pumpAndSettle();

    expect(repo.proposed.single.proposal.productProvided, isFalse);
    expect(env.opened, [AppRoutes.collaborationProgress('collab-1')]);
  });

  testWidgets('a creator turning on view pay is asked to connect instagram', (
    tester,
  ) async {
    final repo = FakeInterestsRepository()
      ..proposalBase = proposalBase(proposedByBrand: false);
    final env = await _pump(
      tester,
      matchInfo(isBrand: false),
      start: '/creator/interests',
      repo: repo,
    );

    await tester.tap(find.text('내가 먼저 제안하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('성과 추가'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('검토하고 보내기'));
    await tester.pumpAndSettle();

    // 연동이 없으면 보내기 대신 `연동하기`가 있다.
    expect(find.text('인스타그램을 연동하면 수락할 수 있어요'), findsOneWidget);
    expect(find.text('이 조건으로 보내기'), findsNothing);
    await tester.tap(find.text('연동하기'));
    await tester.pumpAndSettle();
    expect(env.opened, ['/creator/instagram']);
    expect(repo.proposed, isEmpty);
  });

  testWidgets('a brand is never asked to connect instagram', (tester) async {
    final repo = FakeInterestsRepository()..proposalBase = proposalBase();
    await _pump(tester, matchInfo(), repo: repo);

    await tester.tap(find.text('내가 먼저 제안하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('성과 추가'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('검토하고 보내기'));
    await tester.pumpAndSettle();

    expect(find.textContaining('인스타그램'), findsNothing);
    expect(find.text('이 조건으로 보내기'), findsOneWidget);
  });

  testWidgets('a newer version shows the stale-version screen with its '
      'number', (tester) async {
    final repo = FakeInterestsRepository()
      ..proposalBase = proposalBase()
      ..proposeFailure = const RewardProposalStale(3);
    final env = await _pump(
      tester,
      matchInfo(collaborationId: 'collab-9'),
      repo: repo,
    );

    await tester.tap(find.text('내가 먼저 제안하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('성과 추가'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('검토하고 보내기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('이 조건으로 보내기'));
    await tester.pumpAndSettle();

    expect(find.text('이전 판본이라 수락할 수 없어요'), findsOneWidget);
    expect(find.text('판본 3 보기'), findsOneWidget);
    // 보내지 못했으니 시트는 그대로이고 07로 가지 않는다.
    expect(env.opened, isEmpty);

    await tester.tap(find.text('판본 3 보기'));
    await tester.pumpAndSettle();
    expect(env.opened, ['/collaborations/collab-9/terms']);
  });

  testWidgets('a rejection from the server shows its message and stays on '
      'the review screen', (tester) async {
    final repo = FakeInterestsRepository()
      ..proposalBase = proposalBase()
      ..proposeFailure = const RewardProposalRejected('바꾼 조건이 없어요.');
    final env = await _pump(tester, matchInfo(), repo: repo);

    await tester.tap(find.text('내가 먼저 제안하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('검토하고 보내기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('이 조건으로 보내기'));
    await tester.pumpAndSettle();

    expect(find.text('바꾼 조건이 없어요.'), findsOneWidget);
    expect(find.text('2 / 2'), findsOneWidget);
    expect(env.opened, isEmpty);
  });

  testWidgets('the reward screen offers a retry when the collaboration cannot '
      'be read', (tester) async {
    final repo = FakeInterestsRepository()..failProposalBase = true;
    await _pump(tester, matchInfo(), repo: repo);

    await tester.tap(find.text('내가 먼저 제안하기'));
    await tester.pumpAndSettle();

    expect(find.text('제안 화면을 불러오지 못했어요'), findsOneWidget);
    repo
      ..failProposalBase = false
      ..proposalBase = proposalBase();
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 2'), findsOneWidget);
  });

  testWidgets('the close button closes the sheet', (tester) async {
    final env = await _pump(tester, matchInfo());

    await tester.tap(find.bySemanticsLabel('닫기'));
    await tester.pumpAndSettle();

    expect(find.text('서로를 골랐어요.'), findsNothing);
    expect(env.results, [MatchSheetResult.dismissed]);
  });

  testWidgets('tapping outside the sheet closes it', (tester) async {
    final env = await _pump(tester, matchInfo());

    await tester.tapAt(const Offset(195, 40));
    await tester.pumpAndSettle();

    expect(find.text('서로를 골랐어요.'), findsNothing);
    expect(env.results, [MatchSheetResult.dismissed]);
  });

  testWidgets('dragging the sheet down closes it', (tester) async {
    final env = await _pump(tester, matchInfo());

    await tester.fling(find.text('서로를 골랐어요.'), const Offset(0, 600), 1500);
    await tester.pumpAndSettle();

    expect(find.text('서로를 골랐어요.'), findsNothing);
    expect(env.results, [MatchSheetResult.dismissed]);
  });

  testWidgets('the two photos slide in from both sides and meet', (
    tester,
  ) async {
    useCanvasPhone(tester);
    final router = GoRouter(
      initialLocation: '/start',
      routes: [
        GoRoute(
          path: '/start',
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () => showMatchSheet(context, matchInfo()),
              child: const Text('open sheet'),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(routerConfig: router, theme: coraLightTheme),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('open sheet'));
    // 시트가 올라오는 도중(사진 움직임의 앞부분)에는 사진이 자리보다 바깥에 있다.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final earlyLeft = tester.getRect(find.byType(ClipOval).first);
    final earlyRight = tester.getRect(find.byType(ClipOval).at(1));
    await tester.pumpAndSettle();
    final left = tester.getRect(find.byType(ClipOval).first);
    final right = tester.getRect(find.byType(ClipOval).at(1));

    expect(earlyLeft.left, lessThan(left.left));
    expect(earlyRight.left, greaterThan(right.left));
    // 다 들어오면 지름 96의 두 사진이 168 폭 안에서 24만큼 겹친다(왼쪽 0..96, 오른쪽 72..168).
    expect(left.width, 96);
    expect(right.width, 96);
    expect(right.left - left.left, 72);
  });

  testWidgets('the dark sheet uses the canvas dark surface', (tester) async {
    await _pump(tester, matchInfo(), theme: coraDarkTheme);

    expect(find.text('서로를 골랐어요.'), findsOneWidget);
    final colors = find
        .ancestor(
          of: find.text('서로를 골랐어요.'),
          matching: find.byType(DecoratedBox),
        )
        .evaluate()
        .map((e) => (e.widget as DecoratedBox).decoration)
        .whereType<BoxDecoration>()
        .map((d) => d.color);
    // 시트의 바탕은 캔버스 DarkMatch의 #0F1012이고, 시트 안에서 칠한다.
    expect(colors, contains(const Color(0xFF0F1012)));
  });

  testWidgets('tapping propose-first twice opens the reward screen once', (
    tester,
  ) async {
    final env = await _pump(tester, matchInfo());

    // 첫 탭이 연 화면이 그려지기 전에 한 번 더 누른다.
    await tester.tap(find.text('내가 먼저 제안하기'));
    await tester.tap(find.text('내가 먼저 제안하기'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('1 / 2'), findsOneWidget);
    // 한 번만 열렸으니 뒤로 한 번이면 시트로 돌아온다.
    await tester.tap(find.bySemanticsLabel('뒤로'));
    await tester.pumpAndSettle();
    expect(find.text('서로를 골랐어요.'), findsOneWidget);
    expect(env.opened, isEmpty);
  });
}
