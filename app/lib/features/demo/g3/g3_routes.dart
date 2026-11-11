import 'package:go_router/go_router.dart';

import '../demo_paths.dart';
import 'campaign_page.dart';
import 'creator_discover_page.dart';
import 'guide_page.dart';
import 'keep_list_page.dart';
import 'retro_page.dart';
import 'review_page.dart';
import 'store_view_page.dart';

/// 이 묶음의 시연 화면 경로. 묶음을 맡은 작업자만 고친다.
final List<RouteBase> g3Routes = <RouteBase>[
  GoRoute(path: DemoPaths.guide, builder: (_, _) => const GuidePage()),
  GoRoute(path: DemoPaths.review, builder: (_, _) => const ReviewPage()),
  GoRoute(path: DemoPaths.retro, builder: (_, _) => const RetroPage()),
  GoRoute(path: DemoPaths.keepList, builder: (_, _) => const KeepListPage()),
  GoRoute(
    path: DemoPaths.creatorDiscover,
    builder: (_, _) => const CreatorDiscoverPage(),
  ),
  GoRoute(path: DemoPaths.campaign, builder: (_, _) => const CampaignPage()),
  GoRoute(path: DemoPaths.storeView, builder: (_, _) => const StoreViewPage()),
];
