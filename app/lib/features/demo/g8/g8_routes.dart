import 'package:go_router/go_router.dart';

import '../demo_paths.dart';
import 'budget_page.dart';
import 'metrics_page.dart';
import 'proposals_page.dart';
import 'review_send_page.dart';
import 'states_page.dart';
import 'store_manual_page.dart';

/// 이 묶음의 화면 경로. 묶음을 맡은 작업자만 고친다.
/// 2026-11-12 캔버스: F1 보상·예산, F2 제안 검토, F3 제안함, F4 조회 자료, F7 매장 직접 입력, F8 빈 상태·오류.
final List<RouteBase> g8Routes = <RouteBase>[
  GoRoute(path: DemoPaths.budget, builder: (_, _) => const BudgetPage()),
  GoRoute(
    path: DemoPaths.reviewSend,
    builder: (_, _) => const ReviewSendPage(),
  ),
  GoRoute(path: DemoPaths.proposals, builder: (_, _) => const ProposalsPage()),
  GoRoute(path: DemoPaths.metrics, builder: (_, _) => const MetricsPage()),
  GoRoute(
    path: DemoPaths.storeManual,
    builder: (_, _) => const StoreManualPage(),
  ),
  GoRoute(path: DemoPaths.states, builder: (_, _) => const StatesPage()),
];
