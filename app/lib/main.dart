import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/config/app_config_provider.dart';
import 'core/network/api_client_provider.dart';
import 'core/network/photo_uploader.dart';
import 'core/network/timeout_http_client.dart';
import 'package:cora_api/api.dart' as api;
import 'features/auth/data/secure_key_value_store.dart';
import 'features/auth/data/fake_sign_in_adapter.dart';
import 'features/auth/data/secure_session_storage.dart';
import 'features/auth/data/sign_in_adapter.dart';
import 'features/auth/data/supabase_auth_repository.dart';
import 'features/auth/domain/auth_repository_provider.dart';
import 'features/collaboration/data/api_collaboration_repository.dart';
import 'features/collaboration/domain/collaboration_repository.dart';
import 'features/creator_profile/data/api_creator_profile_repository.dart';
import 'features/creator_profile/domain/creator_profile_repository.dart';
import 'features/instagram_connect/data/api_instagram_repository.dart';
import 'features/instagram_connect/domain/instagram_repository.dart';
import 'features/notification_settings/data/api_notification_settings_repository.dart';
import 'features/notification_settings/domain/notification_settings_repository.dart';
import 'features/notifications/data/api_notification_repository.dart';
import 'features/notifications/domain/notification_repository.dart';
import 'features/onboarding/data/api_me_repository.dart';
import 'features/payout_account/data/api_payout_account_repository.dart';
import 'features/wallet/data/api_wallet_repository.dart';
import 'features/wallet/domain/wallet_repository.dart';
import 'features/payout_account/domain/payout_account_repository.dart';
import 'features/onboarding/domain/me_repository_provider.dart';
import 'features/offers/data/api_received_offers_repository.dart';
import 'features/offers/domain/received_offers_repository.dart';
import 'features/payment/data/api_payment_repository.dart';
import 'features/payment/domain/payment_repository.dart';
import 'features/server_config/data/api_server_config_repository.dart';
import 'features/server_config/domain/server_config_repository.dart';
import 'features/store_browse/data/api_store_browse_repository.dart';
import 'features/store_browse/domain/store_browse_repository.dart';
import 'features/store_home/data/api_store_home_repository.dart';
import 'features/store_home/domain/store_home_repository.dart';
import 'features/store_onboarding/data/api_content_draft_repository.dart';
import 'features/store_onboarding/data/api_store_repository.dart';
import 'features/store_onboarding/domain/content_draft_repository_provider.dart';
import 'features/store_onboarding/domain/store_repository_provider.dart';

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
    // 응답이 없는 연결에서 로그인 화면의 버튼이 안내 없이 꺼진 채 남지 않게 API와 같은 제한을 건다.
    httpClient: TimeoutHttpClient(http.Client()),
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
        serverConfigRepositoryProvider.overrideWith(
          (ref) => ApiServerConfigRepository(ref.watch(apiClientProvider)),
        ),
        storeRepositoryProvider.overrideWith(
          (ref) => ApiStoreRepository(ref.watch(apiClientProvider)),
        ),
        contentDraftRepositoryProvider.overrideWith(
          (ref) => ApiContentDraftRepository(ref.watch(apiClientProvider)),
        ),
        creatorProfileRepositoryProvider.overrideWith(
          (ref) => ApiCreatorProfileRepository(ref.watch(apiClientProvider)),
        ),
        storeBrowseRepositoryProvider.overrideWith(
          (ref) => ApiStoreBrowseRepository(ref.watch(apiClientProvider)),
        ),
        storeHomeRepositoryProvider.overrideWith(
          (ref) => ApiStoreHomeRepository(ref.watch(apiClientProvider)),
        ),
        paymentRepositoryProvider.overrideWith(
          (ref) => ApiPaymentRepository(ref.watch(apiClientProvider)),
        ),
        collaborationRepositoryProvider.overrideWith(
          (ref) => ApiCollaborationRepository(ref.watch(apiClientProvider)),
        ),
        notificationRepositoryProvider.overrideWith(
          (ref) => ApiNotificationRepository(ref.watch(apiClientProvider)),
        ),
        notificationSettingsRepositoryProvider.overrideWith(
          (ref) =>
              ApiNotificationSettingsRepository(ref.watch(apiClientProvider)),
        ),
        instagramRepositoryProvider.overrideWith(
          (ref) => ApiInstagramRepository(ref.watch(apiClientProvider)),
        ),
        payoutAccountRepositoryProvider.overrideWith(
          (ref) => ApiPayoutAccountRepository(ref.watch(apiClientProvider)),
        ),
        walletRepositoryProvider.overrideWith(
          (ref) => ApiWalletRepository(ref.watch(apiClientProvider)),
        ),
        receivedOffersRepositoryProvider.overrideWith(
          (ref) => ApiReceivedOffersRepository(ref.watch(apiClientProvider)),
        ),
        photoUploaderProvider.overrideWith(
          (ref) => ApiPhotoUploader(
            uploads: api.UploadsApi(ref.watch(apiClientProvider)),
            httpClient: ref.watch(httpClientProvider),
          ),
        ),
      ],
      child: const CoraApp(),
    ),
  );
}
