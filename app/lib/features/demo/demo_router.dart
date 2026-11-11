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
    ...g1Routes,
    ...g2Routes,
    ...g3Routes,
    ...g4Routes,
    ...g5Routes,
    ...g6Routes,
    ...g7Routes,
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('아직 만들지 않은 화면이에요\n${state.uri}', textAlign: TextAlign.center),
    ),
  ),
);
