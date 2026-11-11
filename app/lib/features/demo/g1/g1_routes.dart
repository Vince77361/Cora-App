import 'package:go_router/go_router.dart';

import '../demo_paths.dart';
import 'brand_discover_page.dart';
import 'compare_page.dart';
import 'likes_page.dart';
import 'match_page.dart';
import 'pass_page.dart';
import 'progress_page.dart';
import 'terms_page.dart';

/// 이 묶음의 시연 화면 경로. 묶음을 맡은 작업자만 고친다.
final List<RouteBase> g1Routes = <RouteBase>[
  GoRoute(
    path: DemoPaths.brandDiscover,
    builder: (_, _) => const BrandDiscoverPage(),
  ),
  GoRoute(path: DemoPaths.pass, builder: (_, _) => const PassPage()),
  GoRoute(path: DemoPaths.likes, builder: (_, _) => const LikesPage()),
  GoRoute(path: DemoPaths.compare, builder: (_, _) => const ComparePage()),
  GoRoute(path: DemoPaths.match, builder: (_, _) => const MatchPage()),
  GoRoute(path: DemoPaths.terms, builder: (_, _) => const TermsPage()),
  GoRoute(path: DemoPaths.progress, builder: (_, _) => const ProgressPage()),
];
