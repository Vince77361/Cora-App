import 'package:go_router/go_router.dart';

import '../demo_paths.dart';
import 'edit_profile_page.dart';
import 'help_page.dart';
import 'notify_page.dart';
import 'notify_settings_page.dart';
import 'settings_page.dart';
import 'wallet_page.dart';

/// 이 묶음의 시연 화면 경로. 묶음을 맡은 작업자만 고친다.
final List<RouteBase> g7Routes = <RouteBase>[
  GoRoute(path: DemoPaths.notify, builder: (_, _) => const NotifyPage()),
  GoRoute(path: DemoPaths.settings, builder: (_, _) => const SettingsPage()),
  GoRoute(
    path: DemoPaths.notifySettings,
    builder: (_, _) => const NotifySettingsPage(),
  ),
  GoRoute(
    path: DemoPaths.editProfile,
    builder: (_, _) => const EditProfilePage(),
  ),
  GoRoute(path: DemoPaths.wallet, builder: (_, _) => const WalletPage()),
  GoRoute(path: DemoPaths.help, builder: (_, _) => const HelpPage()),
];
