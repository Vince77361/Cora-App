import 'package:go_router/go_router.dart';

import '../demo_paths.dart';
import 'bid_result_page.dart';
import 'bidding_page.dart';
import 'directory_page.dart';
import 'login_page.dart';
import 'outreach_page.dart';
import 'pay_page.dart';
import 'role_page.dart';
import 'verify_page.dart';

/// 이 묶음의 시연 화면 경로. 묶음을 맡은 작업자만 고친다.
final List<RouteBase> g6Routes = <RouteBase>[
  GoRoute(path: DemoPaths.pay, builder: (_, _) => const PayPage()),
  GoRoute(path: DemoPaths.bidding, builder: (_, _) => const BiddingPage()),
  GoRoute(path: DemoPaths.bidResult, builder: (_, _) => const BidResultPage()),
  GoRoute(path: DemoPaths.directory, builder: (_, _) => const DirectoryPage()),
  GoRoute(path: DemoPaths.outreach, builder: (_, _) => const OutreachPage()),
  GoRoute(path: DemoPaths.login, builder: (_, _) => const LoginPage()),
  GoRoute(path: DemoPaths.verify, builder: (_, _) => const VerifyPage()),
  GoRoute(path: DemoPaths.role, builder: (_, _) => const RolePage()),
];
