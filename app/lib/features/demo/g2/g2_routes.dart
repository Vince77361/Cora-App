import 'package:go_router/go_router.dart';

import '../demo_paths.dart';
import 'agreement_page.dart';
import 'chat_page.dart';
import 'chat_thread_page.dart';
import 'contract_page.dart';
import 'principles_page.dart';
import 'proposal_page.dart';

/// 이 묶음의 시연 화면 경로. 묶음을 맡은 작업자만 고친다.
final List<RouteBase> g2Routes = <RouteBase>[
  GoRoute(
    path: DemoPaths.principles,
    builder: (_, _) => const PrinciplesPage(),
  ),
  GoRoute(path: DemoPaths.proposal, builder: (_, _) => const ProposalPage()),
  GoRoute(path: DemoPaths.chat, builder: (_, _) => const ChatPage()),
  GoRoute(
    path: DemoPaths.chatThread,
    builder: (_, _) => const ChatThreadPage(),
  ),
  GoRoute(path: DemoPaths.agreement, builder: (_, _) => const AgreementPage()),
  GoRoute(path: DemoPaths.contract, builder: (_, _) => const ContractPage()),
];
