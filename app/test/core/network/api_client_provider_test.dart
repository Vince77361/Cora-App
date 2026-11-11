import 'dart:async';

import 'package:cora/core/config/app_config.dart';
import 'package:cora/core/config/app_config_provider.dart';
import 'package:cora/core/network/api_client_provider.dart';
import 'package:cora/core/network/timeout_http_client.dart';
import 'package:cora/features/auth/domain/auth_session.dart';
import 'package:cora/features/auth/domain/auth_repository_provider.dart';
import 'package:cora_api/api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../features/auth/fake_auth_repository.dart';
import '../../support/fake_http_client.dart';

void main() {
  late FakeAuthRepository auth;
  late FakeHttpClient fakeHttp;
  late ProviderContainer container;

  setUp(() {
    auth = FakeAuthRepository(session: FakeAuthRepository.signedInSession);
    fakeHttp = FakeHttpClient();
    container = ProviderContainer.test(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        appConfigProvider.overrideWithValue(
          const AppConfig(
            env: CoraEnv.dev,
            supabaseUrl: 'https://example.supabase.co',
            supabaseAnonKey: 'anon',
            apiBaseUrl: 'http://127.0.0.1:3000',
            authAdapter: AuthAdapter.fake,
          ),
        ),
        httpClientProvider.overrideWithValue(fakeHttp),
      ],
    );
  });

  UsersApi users() => UsersApi(container.read(apiClientProvider));

  test('sends requests to the configured API base URL', () async {
    await users().getMe();

    expect(fakeHttp.requests.single.url.toString(), 'http://127.0.0.1:3000/me');
  });

  test(
    'reads the bearer token from the current session on every request',
    () async {
      await users().getMe();
      auth.setSession(
        const AuthSession(userId: 'user-1', accessToken: 'token-2'),
      );
      await users().getMe();

      expect(fakeHttp.requests.map((r) => r.headers['Authorization']), [
        'Bearer token-1',
        'Bearer token-2',
      ]);
    },
  );

  test('sends no Authorization header without a session', () async {
    auth.endSession();

    await users().getMe();

    expect(
      fakeHttp.requests.single.headers.containsKey('Authorization'),
      isFalse,
    );
  });

  test('signs out when the API answers 401', () async {
    fakeHttp
      ..statusCode = 401
      ..body = unauthenticatedBody;

    await expectLater(
      users().getMe(),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 401)),
    );

    expect(auth.signOutCalls, 1);
    expect(auth.currentSession, isNull);
  });

  test('signs out once when several requests get 401 together', () async {
    fakeHttp
      ..statusCode = 401
      ..body = unauthenticatedBody
      ..gate = Completer<void>();

    final calls = [
      for (var i = 0; i < 3; i++)
        users().getMe().then<Object?>(
          (value) => value,
          onError: (Object e) => e,
        ),
    ];
    await pumpEventQueue();
    fakeHttp.gate!.complete();
    final results = await Future.wait(calls);

    expect(results, everyElement(isA<ApiException>()));
    expect(auth.signOutCalls, 1);
  });

  test(
    'does not sign out a newer session when an old token gets 401',
    () async {
      fakeHttp
        ..statusCode = 401
        ..body = unauthenticatedBody
        // 요청이 날아가는 사이 토큰이 갱신되었다.
        ..beforeRespond = () => auth.setSession(
          const AuthSession(userId: 'user-1', accessToken: 'token-2'),
        );

      await expectLater(users().getMe(), throwsA(isA<ApiException>()));

      expect(auth.signOutCalls, 0);
      expect(auth.currentSession?.accessToken, 'token-2');
    },
  );

  test(
    'refreshes an expired token before sending and does not sign out',
    () async {
      auth.expired = true;
      // 만료 토큰을 보내면 서버가 401로 답하는 상황. 갱신된 토큰을 보내면 200이다.
      fakeHttp.respond = (request) =>
          request.headers['Authorization'] == 'Bearer token-refreshed'
          ? 200
          : 401;
      fakeHttp.body = '{"id":"user-1","role":null}';

      await users().getMe();

      expect(auth.refreshCalls, 1);
      expect(
        fakeHttp.requests.single.headers['Authorization'],
        'Bearer token-refreshed',
      );
      expect(auth.signOutCalls, 0);
      expect(auth.currentSession?.accessToken, 'token-refreshed');
    },
  );

  test(
    'concurrent requests with an expired token share one refresh and do not sign out',
    () async {
      auth.expired = true;
      fakeHttp.respond = (request) =>
          request.headers['Authorization'] == 'Bearer token-refreshed'
          ? 200
          : 401;

      await Future.wait([users().getMe(), users().getMe(), users().getMe()]);

      expect(auth.refreshCalls, 1);
      expect(
        fakeHttp.requests.map((r) => r.headers['Authorization']),
        everyElement('Bearer token-refreshed'),
      );
      expect(auth.signOutCalls, 0);
    },
  );

  test('does not sign out on other errors', () async {
    for (final status in [400, 403, 404, 500]) {
      fakeHttp.statusCode = status;
      await expectLater(users().getMe(), throwsA(isA<ApiException>()));
    }

    expect(auth.signOutCalls, 0);
  });

  testWidgets(
    'fails a request that gets no answer instead of waiting forever',
    (tester) async {
      fakeHttp.gate = Completer<void>();

      final result = expectLater(users().getMe(), throwsA(isA<ApiException>()));
      await tester.pump(apiRequestTimeout);
      await result;

      // 응답이 없었던 것이지 토큰이 틀린 것이 아니므로 로그아웃하지 않는다.
      expect(auth.signOutCalls, 0);
    },
  );

  testWidgets(
    'sends the request without a token when the token refresh hangs, and does not sign out on 401',
    (tester) async {
      auth.holdValidToken = Completer<void>();
      fakeHttp
        ..statusCode = 401
        ..body = unauthenticatedBody;

      final result = expectLater(
        users().getMe(),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 401)),
      );
      await tester.pump(apiRequestTimeout);
      await result;

      expect(
        fakeHttp.requests.single.headers.containsKey('Authorization'),
        isFalse,
      );
      // 헤더 없이 나간 요청의 401은 지금 세션의 토큰에 대한 답이 아니다.
      expect(auth.signOutCalls, 0);
      expect(auth.currentSession, isNotNull);
    },
  );
}
