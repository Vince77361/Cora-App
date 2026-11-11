import 'package:cora/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

AppConfig _config(CoraEnv env) => AppConfig(
      env: env,
      supabaseUrl: 'https://example.supabase.co',
      supabaseAnonKey: 'anon',
      apiBaseUrl: 'http://127.0.0.1:3000',
    );

void main() {
  test('isDev is true only for the dev environment', () {
    expect(_config(CoraEnv.dev).isDev, isTrue);
    expect(_config(CoraEnv.prod).isDev, isFalse);
  });

  test('fromEnvironment rejects a missing CORA_ENV', () {
    // 테스트 실행에는 --dart-define이 없으므로 CORA_ENV가 비어 있다.
    expect(AppConfig.fromEnvironment, throwsStateError);
  });
}
