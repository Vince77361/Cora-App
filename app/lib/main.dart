import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/config/app_config_provider.dart';
import 'features/auth/data/secure_key_value_store.dart';
import 'features/auth/data/secure_session_storage.dart';
import 'features/auth/data/supabase_auth_repository.dart';
import 'features/auth/domain/auth_repository_provider.dart';

/// 앱 시작점이자 실제 구현을 조립하는 곳. Supabase SDK는 여기서 초기화만 하고,
/// 기능 코드는 [SupabaseAuthRepository]를 거쳐서만 쓴다.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
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
  runApp(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          SupabaseAuthRepository(Supabase.instance.client.auth),
        ),
        appConfigProvider.overrideWithValue(config),
      ],
      child: const CoraApp(),
    ),
  );
}
