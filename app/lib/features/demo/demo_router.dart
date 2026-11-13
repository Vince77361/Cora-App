import 'package:flutter/cupertino.dart' show CupertinoRouteTransitionMixin;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'demo_paths.dart';
import 'g1/g1_routes.dart';
import 'g2/g2_routes.dart';
import 'g3/g3_routes.dart';
import 'g4/g4_routes.dart';
import 'g5/g5_routes.dart';
import 'g6/g6_routes.dart';
import 'g7/g7_routes.dart';
import 'g8/g8_routes.dart';
import 'g9/g9_routes.dart';

final GoRouter demoRouter = GoRouter(
  // 앱은 로그인(E1)에서 시작한다.
  initialLocation: DemoPaths.login,
  routes: [
    ..._swipeBack(g1Routes),
    ..._swipeBack(g2Routes),
    ..._swipeBack(g3Routes),
    ..._swipeBack(g4Routes),
    ..._swipeBack(g5Routes),
    ..._swipeBack(g6Routes),
    ..._swipeBack(g7Routes),
    ..._swipeBack(g8Routes),
    ..._swipeBack(g9Routes),
  ],
  errorBuilder: (context, state) => const Scaffold(),
);

/// go_router의 기본 페이지는 자기 전환을 써서 iOS 가장자리 밀기가 붙지 않는다.
/// 화면은 모두 [_InstantPage]로 감싸 어느 화면에서든 밀어서 뒤로 가게 한다.
/// 소유자 요청으로 화면 이동 애니메이션은 없앤다(밀어서 뒤로 갈 때만 손가락을 따라 움직인다).
List<RouteBase> _swipeBack(List<RouteBase> routes) => [
  for (final r in routes)
    if (r is GoRoute && r.builder != null)
      GoRoute(
        path: r.path,
        pageBuilder: (context, state) => _InstantPage(
          key: state.pageKey,
          child: r.builder!(context, state),
        ),
      )
    else
      r,
];

/// 전환 시간이 0인 쿠퍼티노 페이지. 가장자리 밀기 뒤로 가기는 그대로 쓴다.
class _InstantPage extends Page<void> {
  const _InstantPage({super.key, required this.child});

  final Widget child;

  @override
  Route<void> createRoute(BuildContext context) => _InstantRoute(this);
}

class _InstantRoute extends PageRoute<void>
    with CupertinoRouteTransitionMixin<void> {
  _InstantRoute(_InstantPage page) : super(settings: page);

  _InstantPage get _page => settings as _InstantPage;

  @override
  Widget buildContent(BuildContext context) => _page.child;

  @override
  String? get title => null;

  @override
  bool get maintainState => true;

  @override
  bool get fullscreenDialog => false;

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => Duration.zero;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';
}
