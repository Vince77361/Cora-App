import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/features/interests/domain/match_info.dart';
import 'package:cora/features/interests/presentation/pages/match_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/load_app_fonts.dart';
import '../../support/pump_cora_app.dart';
import 'fake_interests_repository.dart';

/// 시트를 여는 단추 하나가 있는 화면. 시트가 가는 경로(06, 07)는 위치 글자만 보이는 빈 화면이고 위치를 기록한다.
Future<({List<String> opened, List<MatchSheetResult> results})> _pump(
  WidgetTester tester,
  MatchInfo info, {
  ThemeData? theme,
  String start = '/start',
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
      GoRoute(
        path: '/brand/coming-soon/:title',
        builder: (context, state) => stub(state),
      ),
      GoRoute(
        path: '/creator/coming-soon/:title',
        builder: (context, state) => stub(state),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(routerConfig: router, theme: theme ?? coraLightTheme),
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

  testWidgets('the propose-first button opens the proposal entry and keeps '
      'the sheet', (tester) async {
    final env = await _pump(tester, matchInfo());

    await tester.tap(find.text('내가 먼저 제안하기'));
    await tester.pumpAndSettle();

    // 보상 제안 흐름이 들어오기 전의 자리 화면이다. 보내지 않았으니 시트는 그대로다.
    expect(env.opened, hasLength(1));
    expect(env.opened.single, startsWith('/brand/coming-soon/'));
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

  testWidgets('the creator side sends the first proposal to the same entry', (
    tester,
  ) async {
    final env = await _pump(
      tester,
      matchInfo(isBrand: false),
      start: '/creator/interests',
    );

    await tester.tap(find.text('내가 먼저 제안하기'));
    await tester.pumpAndSettle();

    // 자리 화면은 크리에이터의 경로로 열린다(브랜드의 경로는 크리에이터가 열 수 없다).
    expect(env.opened.single, startsWith('/creator/coming-soon/'));
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

  testWidgets('tapping propose-first twice opens the proposal entry once', (
    tester,
  ) async {
    final env = await _pump(tester, matchInfo());

    // 첫 탭이 연 화면이 그려지기 전에 한 번 더 누른다.
    await tester.tap(find.text('내가 먼저 제안하기'));
    await tester.tap(find.text('내가 먼저 제안하기'));
    await tester.pumpAndSettle();

    expect(env.opened, hasLength(1));
  });
}
