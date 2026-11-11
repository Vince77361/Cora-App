import 'dart:async';
import 'dart:convert';

import 'package:cora/core/config/app_config.dart';
import 'package:cora/core/config/app_config_provider.dart';
import 'package:cora/core/network/api_client_provider.dart';
import 'package:cora/features/auth/domain/auth_session.dart';
import 'package:cora/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:cora_api/api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../features/auth/fake_auth_repository.dart';

/// 손으로 쓴 가짜 HTTP 클라이언트. 받은 요청을 모으고 정해 둔 상태 코드로 답한다.
class FakeHttpClient extends http.BaseClient {
  int statusCode = 200;
  String body = '{"id":"user-1","role":null}';

  /// 설정하면 답하기 전에 이 Completer가 끝날 때까지 기다린다(동시 요청 흉내).
  Completer<void>? gate;

  /// 답하기 직전에 부른다(요청이 날아가는 사이 세션이 바뀌는 상황 흉내).
  void Function()? beforeRespond;

  final requests = <http.BaseRequest>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request);
    final wait = gate;
    if (wait != null) await wait.future;
    beforeRespond?.call();
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      statusCode,
      headers: {'content-type': 'application/json'},
      request: request,
    );
  }
}

const _unauthenticated =
    '{"error":{"code":"UNAUTHENTICATED","message":"로그인이 필요해요.","details":null}}';

void main() {
  late FakeAuthRepository auth;
  late FakeHttpClient http;
  late ProviderContainer container;

  setUp(() {
    auth = FakeAuthRepository(session: FakeAuthRepository.signedInSession);
    http = FakeHttpClient();
    container = ProviderContainer.test(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        appConfigProvider.overrideWithValue(
          const AppConfig(
            env: CoraEnv.dev,
            supabaseUrl: 'https://example.supabase.co',
            supabaseAnonKey: 'anon',
            apiBaseUrl: 'http://127.0.0.1:3000',
          ),
        ),
        httpClientProvider.overrideWithValue(http),
      ],
    );
  });

  UsersApi users() => UsersApi(container.read(apiClientProvider));

  test('sends requests to the configured API base URL', () async {
    await users().getMe();

    expect(http.requests.single.url.toString(), 'http://127.0.0.1:3000/me');
  });

  test(
    'reads the bearer token from the current session on every request',
    () async {
      await users().getMe();
      auth.setSession(
        const AuthSession(userId: 'user-1', accessToken: 'token-2'),
      );
      await users().getMe();

      expect(http.requests.map((r) => r.headers['Authorization']), [
        'Bearer token-1',
        'Bearer token-2',
      ]);
    },
  );

  test('sends no Authorization header without a session', () async {
    auth.endSession();

    await users().getMe();

    expect(http.requests.single.headers.containsKey('Authorization'), isFalse);
  });

  test('signs out when the API answers 401', () async {
    http
      ..statusCode = 401
      ..body = _unauthenticated;

    await expectLater(
      users().getMe(),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 401)),
    );

    expect(auth.signOutCalls, 1);
    expect(auth.currentSession, isNull);
  });

  test('signs out once when several requests get 401 together', () async {
    http
      ..statusCode = 401
      ..body = _unauthenticated
      ..gate = Completer<void>();

    final calls = [
      for (var i = 0; i < 3; i++)
        users().getMe().then<Object?>(
          (value) => value,
          onError: (Object e) => e,
        ),
    ];
    await pumpEventQueue();
    http.gate!.complete();
    final results = await Future.wait(calls);

    expect(results, everyElement(isA<ApiException>()));
    expect(auth.signOutCalls, 1);
  });

  test(
    'does not sign out a newer session when an old token gets 401',
    () async {
      http
        ..statusCode = 401
        ..body = _unauthenticated
        // 요청이 날아가는 사이 토큰이 갱신되었다.
        ..beforeRespond = () => auth.setSession(
          const AuthSession(userId: 'user-1', accessToken: 'token-2'),
        );

      await expectLater(users().getMe(), throwsA(isA<ApiException>()));

      expect(auth.signOutCalls, 0);
      expect(auth.currentSession?.accessToken, 'token-2');
    },
  );

  test('does not sign out on other errors', () async {
    for (final status in [400, 403, 404, 500]) {
      http.statusCode = status;
      await expectLater(users().getMe(), throwsA(isA<ApiException>()));
    }

    expect(auth.signOutCalls, 0);
  });
}
