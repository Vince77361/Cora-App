import 'package:go_router/go_router.dart';

import '../demo_paths.dart';
import 'ai_order_page.dart';
import 'applicants_page.dart';
import 'counter_page.dart';
import 'result_page.dart';
import 'switch_report_page.dart';

/// 이 묶음의 화면 경로. 묶음을 맡은 작업자만 고친다.
final List<RouteBase> g9Routes = <RouteBase>[
  GoRoute(path: DemoPaths.result, builder: (_, _) => const ResultPage()),
  GoRoute(
    path: DemoPaths.applicants,
    builder: (_, _) => const ApplicantsPage(),
  ),
  GoRoute(
    path: DemoPaths.switchReport,
    builder: (_, _) => const SwitchReportPage(),
  ),
  GoRoute(path: DemoPaths.aiOrder, builder: (_, _) => const AiOrderPage()),
  GoRoute(path: DemoPaths.counter, builder: (_, _) => const CounterPage()),
];
