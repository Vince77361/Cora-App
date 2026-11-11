import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_config.dart';

/// 실행 설정. 기본값은 일부러 던진다. main.dart가 `AppConfig.fromEnvironment()`로,
/// 테스트가 원하는 환경(dev, prod)으로 바꿔 끼운다.
final appConfigProvider = Provider<AppConfig>(
  (ref) => throw UnimplementedError('appConfigProvider must be overridden'),
);
