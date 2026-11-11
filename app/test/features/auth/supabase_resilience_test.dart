import 'dart:async';

import 'package:cora/core/network/timeout_http_client.dart';
import 'package:cora/features/auth/data/secure_session_storage.dart';
import 'package:cora/features/auth/data/supabase_failures.dart';
import 'package:cora/features/auth/domain/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, GoTrueClient;

import '../../support/fake_http_client.dart';
import 'fake_secure_key_value_store.dart';

const _sessionBody =
    '{"access_token":"access-1","token_type":"bearer","expires_in":3600,'
    '"refresh_token":"refresh-1","user":{"id":"user-1","aud":"authenticated",'
    '"app_metadata":{},"user_metadata":{},"created_at":"2026-01-01T00:00:00Z"}}';

GoTrueClient _client(
  FakeHttpClient http, {
  FakeSecureKeyValueStore? store,
  bool timeout = false,
}) => GoTrueClient(
  url: 'https://example.supabase.co/auth/v1',
  httpClient: timeout ? TimeoutHttpClient(http) : http,
  asyncStorage: SecureGotrueAsyncStorage(
    store: store ?? FakeSecureKeyValueStore(),
  ),
  autoRefreshToken: false,
);

/// 실제 gotrue SDK에 가짜 HTTP와 가짜 보안 저장소를 붙여, SDK 안에서 일어나는 일을 본다.
void main() {
  test('signing out still ends the session when the keychain cannot delete the '
      'PKCE value', () async {
    final store = FakeSecureKeyValueStore();
    final http = FakeHttpClient()..body = _sessionBody;
    final auth = _client(http, store: store);
    await auth.signInWithPassword(email: 'a@example.com', password: 'secret1');
    expect(auth.currentSession, isNotNull);

    store.deleteError = StateError('keychain locked');
    final events = <AuthChangeEvent>[];
    final subscription = auth.onAuthStateChange.listen(
      (state) => events.add(state.event),
    );
    addTearDown(subscription.cancel);
    http
      ..statusCode = 204
      ..body = '';

    await auth.signOut();
    await pumpEventQueue();

    expect(auth.currentSession, isNull);
    expect(events, contains(AuthChangeEvent.signedOut));
  });

  testWidgets('a sign-in that gets no answer fails as a network failure', (
    tester,
  ) async {
    final http = FakeHttpClient()..gate = Completer<void>();
    final auth = _client(http, timeout: true);

    final failure = Completer<Object>();
    unawaited(
      auth
          .signInWithPassword(email: 'a@example.com', password: 'secret1')
          .then<void>((_) {}, onError: failure.complete),
    );
    await tester.pump(apiRequestTimeout);
    await tester.pump();

    expect(failure.isCompleted, isTrue);
    expect(toAuthFailure(await failure.future).kind, AuthFailureKind.network);
  });
}
