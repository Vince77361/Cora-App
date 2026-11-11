import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/navigation/app_router.dart';
import 'core/theme/cora_theme.dart';

/// 앱의 뿌리. 화면은 [appRouterProvider]가 로그인 상태를 보고 고른다.
class CoraApp extends ConsumerWidget {
  const CoraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Cora',
      theme: coraLightTheme,
      darkTheme: coraDarkTheme,
      themeMode: ThemeMode.system,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
