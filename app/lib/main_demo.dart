import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/demo/demo_app.dart';

/// 서버·Supabase 없이 모든 화면을 목업 데이터로 띄우는 앱의 시작점.
/// 실행: `flutter run -t lib/main_demo.dart`
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: DemoApp()));
}
