import 'package:flutter/cupertino.dart' show CupertinoPage;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'demo_index_page.dart';
import 'demo_paths.dart';
import 'g1/g1_routes.dart';
import 'g2/g2_routes.dart';
import 'g3/g3_routes.dart';
import 'g4/g4_routes.dart';
import 'g5/g5_routes.dart';
import 'g6/g6_routes.dart';
import 'g7/g7_routes.dart';

final GoRouter demoRouter = GoRouter(
  initialLocation: DemoPaths.index,
  routes: [
    GoRoute(path: DemoPaths.index, builder: (_, _) => const DemoIndexPage()),
    ..._swipeBack(g1Routes),
    ..._swipeBack(g2Routes),
    ..._swipeBack(g3Routes),
    ..._swipeBack(g4Routes),
    ..._swipeBack(g5Routes),
    ..._swipeBack(g6Routes),
    ..._swipeBack(g7Routes),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('아직 만들지 않은 화면이에요\n${state.uri}', textAlign: TextAlign.center),
    ),
  ),
);

/// go_router의 기본 페이지는 자기 전환을 써서 iOS 가장자리 밀기가 붙지 않는다.
/// 시연 화면은 모두 CupertinoPage로 감싸 어느 화면에서든 밀어서 뒤로 가게 한다.
List<RouteBase> _swipeBack(List<RouteBase> routes) => [
  for (final r in routes)
    if (r is GoRoute && r.builder != null)
      GoRoute(
        path: r.path,
        pageBuilder: (context, state) => CupertinoPage(
          key: state.pageKey,
          child: r.builder!(context, state),
        ),
      )
    else
      r,
];
