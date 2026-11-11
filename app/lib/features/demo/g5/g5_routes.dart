import 'package:go_router/go_router.dart';

import '../demo_paths.dart';
import 'offer_page.dart';
import 'store_a_i_page.dart';
import 'store_home_page.dart';
import 'store_link_page.dart';
import 'store_page_page.dart';

/// 이 묶음의 시연 화면 경로. 묶음을 맡은 작업자만 고친다.
final List<RouteBase> g5Routes = <RouteBase>[
  GoRoute(path: DemoPaths.storeLink, builder: (_, _) => const StoreLinkPage()),
  GoRoute(path: DemoPaths.storePage, builder: (_, _) => const StorePagePage()),
  GoRoute(path: DemoPaths.storeAI, builder: (_, _) => const StoreAIPage()),
  GoRoute(path: DemoPaths.storeHome, builder: (_, _) => const StoreHomePage()),
  GoRoute(path: DemoPaths.offer, builder: (_, _) => const OfferPage()),
];
