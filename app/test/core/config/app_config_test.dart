import 'package:cora/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

AppConfig _config(CoraEnv env, [AuthAdapter adapter = AuthAdapter.fake]) =>
    AppConfig(
      env: env,
      supabaseUrl: 'https://example.supabase.co',
      supabaseAnonKey: 'anon',
      apiBaseUrl: 'http://127.0.0.1:3000',
      authAdapter: adapter,
    );

void main() {
  test('isDev is true only for the dev environment', () {
    expect(_config(CoraEnv.dev).isDev, isTrue);
    expect(_config(CoraEnv.prod).isDev, isFalse);
  });

  test('dev screens are enabled only in the dev environment', () {
    expect(_config(CoraEnv.dev).devScreensEnabled, isTrue);
    expect(_config(CoraEnv.prod).devScreensEnabled, isFalse);
  });

  test('fromEnvironment rejects a missing CORA_ENV', () {
    // 테스트 실행에는 --dart-define이 없으므로 CORA_ENV가 비어 있다.
    expect(AppConfig.fromEnvironment, throwsStateError);
  });

  group('parseAuthAdapter', () {
    test('an empty value is fake in dev', () {
      expect(AppConfig.parseAuthAdapter('', CoraEnv.dev), AuthAdapter.fake);
    });

    test('an empty value is an error in prod', () {
      expect(
        () => AppConfig.parseAuthAdapter('', CoraEnv.prod),
        throwsA(isA<StateError>()),
      );
    });

    test('reads fake and real by name', () {
      expect(AppConfig.parseAuthAdapter('fake', CoraEnv.dev), AuthAdapter.fake);
      expect(
        AppConfig.parseAuthAdapter('real', CoraEnv.prod),
        AuthAdapter.real,
      );
    });

    test('rejects a misspelled value', () {
      expect(
        () => AppConfig.parseAuthAdapter('fak', CoraEnv.dev),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('fak'),
          ),
        ),
      );
    });
  });

  group('assertAuthAdapterStartable', () {
    test('refuses to start a prod build with the fake sign-in', () {
      expect(
        () => assertAuthAdapterStartable(_config(CoraEnv.prod)),
        throwsA(
          isA<StateError>().having((e) => e.message, 'message', contains('운영')),
        ),
      );
    });

    test('lets a dev build start with the fake sign-in', () {
      expect(
        () => assertAuthAdapterStartable(_config(CoraEnv.dev)),
        returnsNormally,
      );
    });

    test('says plainly that the real sign-in does not exist yet', () {
      expect(
        () =>
            assertAuthAdapterStartable(_config(CoraEnv.prod, AuthAdapter.real)),
        throwsA(
          isA<StateError>().having((e) => e.message, 'message', contains('아직')),
        ),
      );
      expect(
        () =>
            assertAuthAdapterStartable(_config(CoraEnv.dev, AuthAdapter.real)),
        throwsStateError,
      );
    });
  });
}
