import 'package:cora/features/auth/data/secure_session_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_secure_key_value_store.dart';

void main() {
  late FakeSecureKeyValueStore store;
  late SecureSessionStorage storage;

  setUp(() {
    store = FakeSecureKeyValueStore();
    storage = SecureSessionStorage(
      store: store,
      persistSessionKey: 'sb-proj-auth-token',
    );
  });

  group('SecureSessionStorage', () {
    test('has no session before anything is persisted', () async {
      await storage.initialize();

      expect(await storage.hasAccessToken(), isFalse);
      expect(await storage.accessToken(), isNull);
    });

    test('persists the session string and reads it back', () async {
      await storage.persistSession('{"access_token":"a"}');

      expect(await storage.hasAccessToken(), isTrue);
      expect(await storage.accessToken(), '{"access_token":"a"}');
      expect(store.values, {'sb-proj-auth-token': '{"access_token":"a"}'});
    });

    test('overwrites the previous session on refresh', () async {
      await storage.persistSession('old');
      await storage.persistSession('new');

      expect(await storage.accessToken(), 'new');
    });

    test('removes the persisted session', () async {
      await storage.persistSession('session');

      await storage.removePersistedSession();

      expect(await storage.hasAccessToken(), isFalse);
      expect(store.values, isEmpty);
    });

    test('treats an unreadable store as signed out without throwing', () async {
      await storage.persistSession('session');
      store.readError = StateError('keychain locked');

      expect(await storage.hasAccessToken(), isFalse);
      expect(await storage.accessToken(), isNull);
      // 읽지 못했다고 저장된 값을 지우지는 않는다.
      expect(store.values, isNotEmpty);
    });
  });

  group('SecureGotrueAsyncStorage', () {
    late SecureGotrueAsyncStorage pkce;

    setUp(() => pkce = SecureGotrueAsyncStorage(store: store));

    test('stores, reads and removes an item', () async {
      await pkce.setItem(key: 'verifier', value: 'abc');
      expect(await pkce.getItem(key: 'verifier'), 'abc');

      await pkce.removeItem(key: 'verifier');
      expect(await pkce.getItem(key: 'verifier'), isNull);
    });

    test('reads as empty and removes silently when the store throws', () async {
      await pkce.setItem(key: 'verifier', value: 'abc');
      store
        ..readError = StateError('keychain locked')
        ..deleteError = StateError('keychain locked');

      expect(await pkce.getItem(key: 'verifier'), isNull);
      // 던지면 gotrue의 signOut이 signedOut을 보내지 못한 채 끝난다.
      await pkce.removeItem(key: 'verifier');
    });

    test('keeps its keys apart from the session key', () async {
      await storage.persistSession('session');
      await pkce.setItem(key: 'sb-proj-auth-token', value: 'verifier');

      expect(await storage.accessToken(), 'session');
      expect(await pkce.getItem(key: 'sb-proj-auth-token'), 'verifier');
    });
  });
}
