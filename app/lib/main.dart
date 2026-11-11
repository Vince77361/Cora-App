import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/config/app_config_provider.dart';
import 'core/network/api_client_provider.dart';
import 'features/auth/data/secure_key_value_store.dart';
import 'features/auth/data/fake_sign_in_adapter.dart';
import 'features/auth/data/secure_session_storage.dart';
import 'features/auth/data/sign_in_adapter.dart';
import 'features/auth/data/supabase_auth_repository.dart';
import 'features/auth/domain/auth_repository_provider.dart';
import 'features/onboarding/data/api_me_repository.dart';
import 'features/onboarding/domain/me_repository_provider.dart';

/// 앱 시작점이자 실제 구현을 조립하는 곳. Supabase SDK는 여기서 초기화만 하고,
/// 기능 코드는 [SupabaseAuthRepository]를 거쳐서만 쓴다.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  // 운영에서 가짜 인증이 선택되면 여기서 멈춘다(서버의 assertNoFakesInProduction과 같다).
  assertAuthAdapterStartable(config);
  const secureStore = FlutterSecureKeyValueStore();
  // 저장된 세션을 기기에서 읽어 올려 둔다. 그래서 첫 화면을 그리기 전에 로그인 여부를 안다.
  // SUPABASE_ANON_KEY에는 새 공개 키(sb_publishable_…)가 들어 있다. SDK의 anonKey 인자는
  // 같은 일을 하지만 사용 중단 예정이라 publishableKey로 넘긴다.
  await Supabase.initialize(
    url: config.supabaseUrl,
    publishableKey: config.supabaseAnonKey,
    // 세션(리프레시 토큰 포함)을 일반 설정 파일이 아니라 Keychain/Keystore에 둔다.
    authOptions: FlutterAuthClientOptions(
      localStorage: SecureSessionStorage(
        store: secureStore,
        // SDK 기본 키와 같은 모양(sb-<프로젝트>-auth-token).
        persistSessionKey:
            'sb-${Uri.parse(config.supabaseUrl).host.split('.').first}-auth-token',
      ),
      pkceAsyncStorage: SecureGotrueAsyncStorage(store: secureStore),
    ),
  );
  final auth = Supabase.instance.client.auth;
  // assertAuthAdapterStartable이 real을 이미 거부했으므로 여기까지 오면 fake뿐이다.
  // 실제 어댑터(휴대폰 OTP·카카오·네이버)는 9번 계획에서 이 자리에 들어온다.
  final SignInAdapter signInAdapter = switch (config.authAdapter) {
    AuthAdapter.fake => FakeSignInAdapter.supabase(auth),
    AuthAdapter.real => throw StateError('실제 로그인은 아직 만들지 않았습니다.'),
  };
  runApp(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          SupabaseAuthRepository(auth, signInAdapter: signInAdapter),
        ),
        appConfigProvider.overrideWithValue(config),
        meRepositoryProvider.overrideWith(
          (ref) => ApiMeRepository(ref.watch(apiClientProvider)),
        ),
      ],
      child: const CoraApp(),
    ),
  );
}
