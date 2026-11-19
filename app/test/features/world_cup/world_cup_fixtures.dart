import 'dart:math';

import 'package:cora/core/navigation/app_routes.dart';
import 'package:cora/core/theme/cora_theme.dart';
import 'package:cora/features/world_cup/domain/world_cup_candidate.dart';
import 'package:cora/features/world_cup/presentation/pages/world_cup_match_page.dart';
import 'package:cora/features/world_cup/presentation/pages/world_cup_result_page.dart';
import 'package:cora/features/world_cup/presentation/viewmodels/world_cup_view_model.dart';
import 'package:cora/features/world_cup/presentation/world_cup_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/pump_cora_app.dart';

/// 저장 [n]번째 후보. 이름·한 줄·설명이 번호로 갈려 화면에서 누가 나왔는지 글자로 알아본다.
WorldCupCandidate wcCandidate(
  int n, {
  String? name,
  String? headline,
  String? meta,
}) => WorldCupCandidate(
  id: 'c$n',
  name: name ?? '크리에이터 $n',
  headline: headline ?? '한 줄 $n',
  meta: meta ?? '리빙 릴스 · 팔로워 ${n}00',
  savedOrder: n,
);

List<WorldCupCandidate> wcCandidates(int count) => [
  for (var i = 1; i <= count; i++) wcCandidate(i),
];

/// 제안하기가 불린 우승자들. [notice]를 주면 제안을 보낸 뒤의 안내로 돌려준다.
class ProposeLog {
  ProposeLog({this.notice});

  final WorldCupNotice? notice;
  final winners = <WorldCupCandidate>[];

  Future<WorldCupNotice?> call(
    BuildContext context,
    WorldCupCandidate winner,
  ) async {
    winners.add(winner);
    return notice;
  }
}

typedef WorldCupHarness = ({
  GoRouter router,
  ProposeLog proposals,
  List<String> opened,
});

/// 저장함 자리(버튼 `go start`)를 맨 아래에 깔고 월드컵 대결(`/world-cup/match`)과 결과를 올린다. 그 밖의 경로는
/// 위치만 기록하는 빈 화면이다. 뽑는 무작위는 고정 시드다.
Future<WorldCupHarness> pumpWorldCup(
  WidgetTester tester, {
  int saved = 4,
  int size = 4,
  int seed = 1,
  List<WorldCupCandidate>? candidates,
  WorldCupNotice? notice,
  ThemeData? theme,
  bool smallPhoneLargeText = false,
  bool startPlaying = true,
}) async {
  if (smallPhoneLargeText) {
    useSmallPhoneWithLargeText(tester);
  } else {
    useCanvasPhone(tester);
  }
  final proposals = ProposeLog(notice: notice);
  final opened = <String>[];
  final router = GoRouter(
    initialLocation: '/store/interests',
    routes: [
      GoRoute(
        path: '/store/interests',
        builder: (context, state) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => context.push(
                AppRoutes.worldCupMatch,
                extra: WorldCupMatchArgs(
                  saved: candidates ?? wcCandidates(saved),
                  size: size,
                  onPropose: proposals.call,
                ),
              ),
              child: const Text('go start'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.worldCupMatch,
        builder: (context, state) =>
            WorldCupMatchPage(args: state.extra! as WorldCupMatchArgs),
      ),
      GoRoute(
        path: AppRoutes.worldCupResult,
        builder: (context, state) =>
            WorldCupResultPage(args: state.extra! as WorldCupResultArgs),
      ),
      GoRoute(
        path: '/store/offers/new/:creatorId',
        builder: (context, state) {
          opened.add(state.uri.toString());
          return Scaffold(body: Text('opened ${state.uri}'));
        },
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [worldCupRandomProvider.overrideWithValue(Random(seed))],
      child: MaterialApp.router(
        routerConfig: router,
        theme: theme ?? coraLightTheme,
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (startPlaying) {
    await tester.tap(find.text('go start'));
    await tester.pumpAndSettle();
  }
  return (router: router, proposals: proposals, opened: opened);
}
