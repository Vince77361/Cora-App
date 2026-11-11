import 'package:flutter/material.dart';

import 'core/theme/cora_theme.dart';
import 'features/dev/presentation/pages/motion_gallery_page.dart';

/// 임시 앱 껍데기. 라우팅과 화면은 Task 9에서 채운다.
class CoraApp extends StatelessWidget {
  const CoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cora',
      theme: coraLightTheme,
      darkTheme: coraDarkTheme,
      themeMode: ThemeMode.system,
      // 임시: Task 9의 라우터가 생기기 전까지 소유자가 전환을 실제 기기에서 승인할 수 있게
      // 첫 화면에 모션 갤러리를 띄운다. Task 9에서 개발 환경 전용 경로 /dev/motion으로 옮긴다.
      home: const MotionGalleryPage(),
    );
  }
}
