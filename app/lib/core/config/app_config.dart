/// 실행 환경. `--dart-define=CORA_ENV=dev|prod`로 정한다.
enum CoraEnv { dev, prod }

/// 로그인 방식을 구현한 쪽. `--dart-define=AUTH_ADAPTER=fake|real`로 정한다.
/// `fake`는 개발용 계정으로 로그인시키는 가짜 인증이고 운영에서는 쓸 수 없다.
/// `real`(Supabase 휴대폰 OTP·카카오·네이버)은 9번 계획에서 만든다.
enum AuthAdapter { fake, real }

/// 운영 빌드(`CORA_ENV=prod`로 컴파일)에서는 컴파일 시점에 false다. 개발용 화면을 쓰는
/// 자리마다 `if (kDevScreensCompiledIn && config.isDev)`처럼 이 상수를 식 안에 직접 써서
/// 막아 두면 컴파일러가 그 화면 코드를 앱 바이너리에서 뺀다(getter나 지역 변수를 거치면
/// 이 보장이 약해진다). 실행 중의 판단은 `config.isDev`가 한다.
const kDevScreensCompiledIn = String.fromEnvironment('CORA_ENV') != 'prod';

/// 빌드 시점에 `--dart-define`(또는 `--dart-define-from-file`)으로 받는 앱 설정.
class AppConfig {
  const AppConfig({
    required this.env,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.apiBaseUrl,
    required this.authAdapter,
  });

  /// `String.fromEnvironment`는 상수로만 평가되므로 const 리터럴로 읽는다.
  factory AppConfig.fromEnvironment() {
    const envName = String.fromEnvironment('CORA_ENV');
    final env = _parseEnv(envName);
    return AppConfig(
      env: env,
      supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
      supabaseAnonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
      apiBaseUrl: const String.fromEnvironment('API_BASE_URL'),
      authAdapter: parseAuthAdapter(
        const String.fromEnvironment('AUTH_ADAPTER'),
        env,
      ),
    );
  }

  final CoraEnv env;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String apiBaseUrl;
  final AuthAdapter authAdapter;

  bool get isDev => env == CoraEnv.dev;

  /// `AUTH_ADAPTER` 값을 읽는다. 개발에서는 비어 있으면 가짜 인증이다. 운영에서 비어 있으면
  /// 조용히 하나로 흘러가지 않도록 던진다.
  static AuthAdapter parseAuthAdapter(String name, CoraEnv env) {
    switch (name) {
      case 'fake':
        return AuthAdapter.fake;
      case 'real':
        return AuthAdapter.real;
      case '':
        if (env == CoraEnv.dev) return AuthAdapter.fake;
        throw StateError('AUTH_ADAPTER가 비어 있습니다. 운영 빌드는 real로 정해야 합니다.');
      default:
        throw StateError(
          "AUTH_ADAPTER는 'fake' 또는 'real'이어야 합니다. 받은 값: '$name'.",
        );
    }
  }

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

/// 앱을 시작해도 되는 로그인 설정인지 확인한다. 서버의 `assertNoFakesInProduction`과 같은
/// 생각이다: 운영에서 가짜 인증이 선택되면 누구나 개발용 계정으로 들어올 수 있으므로
/// 시작부터 거부한다. main이 첫머리에서 부른다.
void assertAuthAdapterStartable(AppConfig config) {
  if (config.authAdapter == AuthAdapter.real) {
    throw StateError(
      '실제 로그인(AUTH_ADAPTER=real)은 아직 만들지 않았습니다(9번 계획). '
      '개발에서는 AUTH_ADAPTER=fake를 쓰세요.',
    );
  }
  if (config.env == CoraEnv.prod) {
    throw StateError(
      '운영 빌드에서는 가짜 인증(AUTH_ADAPTER=fake)을 쓸 수 없습니다. '
      'AUTH_ADAPTER=real로 빌드하세요.',
    );
  }
}
