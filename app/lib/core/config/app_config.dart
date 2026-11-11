/// 실행 환경. `--dart-define=CORA_ENV=dev|prod`로 정한다.
enum CoraEnv { dev, prod }

/// 빌드 시점에 `--dart-define`(또는 `--dart-define-from-file`)으로 받는 앱 설정.
class AppConfig {
  const AppConfig({
    required this.env,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.apiBaseUrl,
  });

  /// `String.fromEnvironment`는 상수로만 평가되므로 const 리터럴로 읽는다.
  factory AppConfig.fromEnvironment() {
    const envName = String.fromEnvironment('CORA_ENV');
    return AppConfig(
      env: _parseEnv(envName),
      supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
      supabaseAnonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
      apiBaseUrl: const String.fromEnvironment('API_BASE_URL'),
    );
  }

  final CoraEnv env;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String apiBaseUrl;

  bool get isDev => env == CoraEnv.dev;

  // 값이 비었거나 오타인 채로 조용히 dev/prod 중 하나로 흘러가면 운영 사고가 되므로 던진다.
  static CoraEnv _parseEnv(String name) {
    switch (name) {
      case 'dev':
        return CoraEnv.dev;
      case 'prod':
        return CoraEnv.prod;
      default:
        throw StateError(
          "CORA_ENV는 'dev' 또는 'prod'여야 합니다. 받은 값: '$name'. "
          '예: --dart-define-from-file=config/dev.json',
        );
    }
  }
}
